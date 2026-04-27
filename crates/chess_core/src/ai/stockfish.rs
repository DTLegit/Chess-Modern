//! UCI engine wrapper.
//!
//! The actual `tokio::process::Command` (or `tauri_plugin_shell`, on the
//! legacy Tauri shell) lives in the embedding shell behind the
//! [`StockfishSpawner`] trait — this module only knows the UCI protocol
//! and how to talk to the child process the spawner returns.

use std::time::Duration;

use tokio::io::{AsyncReadExt, AsyncWriteExt};

use crate::{
    ai::{
        custom::{self, SearchOutput},
        difficulty::profile_for,
    },
    api::{AiProgressEvent, ApiError, ApiResult},
    engine::Position,
    platform::{StockfishSpawner, UciChild},
};

pub async fn choose_move(
    spawner: &dyn StockfishSpawner,
    game_id: &str,
    position: &Position,
    history_uci: &[String],
    difficulty: u8,
    mut progress: impl FnMut(AiProgressEvent) + Send + 'static,
) -> ApiResult<Option<SearchOutput>> {
    let fallback_difficulty = profile_for(difficulty).fallback_custom_level;
    if !spawner.is_available() {
        return Ok(custom::choose_move(
            game_id,
            position,
            fallback_difficulty,
            progress,
        ));
    }

    match run_stockfish(
        spawner,
        game_id,
        position,
        history_uci,
        difficulty,
        &mut progress,
    )
    .await
    {
        Ok(Some(output)) => Ok(Some(output)),
        Ok(None) => Ok(custom::choose_move(
            game_id,
            position,
            fallback_difficulty,
            progress,
        )),
        Err(err) => {
            log::warn!("Stockfish failed ({err}); using custom engine fallback");
            Ok(custom::choose_move(
                game_id,
                position,
                fallback_difficulty,
                progress,
            ))
        }
    }
}

async fn run_stockfish(
    spawner: &dyn StockfishSpawner,
    game_id: &str,
    position: &Position,
    history_uci: &[String],
    difficulty: u8,
    progress: &mut (impl FnMut(AiProgressEvent) + Send + 'static),
) -> ApiResult<Option<SearchOutput>> {
    let (skill, _depth, movetime_ms) = profile_for(difficulty)
        .stockfish_settings()
        .ok_or_else(|| ApiError::Engine(format!("level {difficulty} is not a Stockfish level")))?;
    let UciChild {
        mut stdin,
        stdout,
        stderr,
        kill,
    } = spawner.spawn().await?;

    write_line(&mut stdin, "uci").await?;
    write_line(&mut stdin, &format!("setoption name Skill Level value {skill}")).await?;
    write_line(&mut stdin, "isready").await?;
    write_line(&mut stdin, "ucinewgame").await?;

    let mut position_cmd = format!("position fen {}", position.to_fen());
    if !history_uci.is_empty() {
        position_cmd.push_str(" moves ");
        position_cmd.push_str(&history_uci.join(" "));
    }
    write_line(&mut stdin, &position_cmd).await?;
    write_line(&mut stdin, &format!("go movetime {movetime_ms}")).await?;

    if let Some(stderr) = stderr {
        spawn_stderr_logger(stderr);
    }

    let mut best = None;
    let mut best_eval = 0;
    let mut best_depth = 0;
    let deadline = tokio::time::sleep(Duration::from_millis(movetime_ms.saturating_add(1_000)));
    tokio::pin!(deadline);

    let mut lines = LineReader::new(stdout);
    loop {
        tokio::select! {
            _ = &mut deadline => {
                let _ = write_line(&mut stdin, "stop").await;
                break;
            }
            line = lines.next_line() => {
                let Some(line) = line.map_err(|e| ApiError::Engine(format!("stockfish stdout: {e}")))? else {
                    break;
                };
                if let Some((depth, eval, pv)) = parse_info_line(&line, position) {
                    best_eval = eval;
                    best_depth = depth;
                    progress(AiProgressEvent {
                        game_id: game_id.to_string(),
                        depth,
                        eval_cp: eval,
                        pv_san: pv,
                    });
                } else if let Some(uci) =
                    line.strip_prefix("bestmove ").and_then(|rest| rest.split_whitespace().next())
                {
                    let mut pos = position.clone();
                    best = pos.parse_uci(uci);
                    break;
                }
            }
        }
    }

    kill();
    Ok(best.map(|mv| SearchOutput {
        mv,
        eval_cp: best_eval,
        depth: best_depth,
        pv: vec![mv],
    }))
}

async fn write_line(
    stdin: &mut std::pin::Pin<Box<dyn tokio::io::AsyncWrite + Send>>,
    line: &str,
) -> ApiResult<()> {
    stdin
        .write_all(line.as_bytes())
        .await
        .map_err(|e| ApiError::Engine(format!("stockfish stdin: {e}")))?;
    stdin
        .write_all(b"\n")
        .await
        .map_err(|e| ApiError::Engine(format!("stockfish stdin: {e}")))?;
    let _ = stdin.flush().await;
    Ok(())
}

fn spawn_stderr_logger(mut stderr: std::pin::Pin<Box<dyn tokio::io::AsyncRead + Send>>) {
    tokio::spawn(async move {
        let mut buf = [0u8; 1024];
        loop {
            match stderr.read(&mut buf).await {
                Ok(0) | Err(_) => break,
                Ok(n) => log::warn!("stockfish stderr: {}", String::from_utf8_lossy(&buf[..n])),
            }
        }
    });
}

/// Tiny line-buffered reader so the AI loop can stream UCI replies.
struct LineReader {
    inner: std::pin::Pin<Box<dyn tokio::io::AsyncRead + Send>>,
    buf: Vec<u8>,
    eof: bool,
}

impl LineReader {
    fn new(inner: std::pin::Pin<Box<dyn tokio::io::AsyncRead + Send>>) -> Self {
        Self {
            inner,
            buf: Vec::with_capacity(256),
            eof: false,
        }
    }

    async fn next_line(&mut self) -> std::io::Result<Option<String>> {
        loop {
            if let Some(pos) = self.buf.iter().position(|&b| b == b'\n') {
                let mut line = self.buf.drain(..=pos).collect::<Vec<u8>>();
                line.pop();
                if line.last() == Some(&b'\r') {
                    line.pop();
                }
                return Ok(Some(String::from_utf8_lossy(&line).into_owned()));
            }
            if self.eof {
                if self.buf.is_empty() {
                    return Ok(None);
                }
                let line = std::mem::take(&mut self.buf);
                return Ok(Some(String::from_utf8_lossy(&line).into_owned()));
            }
            let mut tmp = [0u8; 256];
            let n = self.inner.read(&mut tmp).await?;
            if n == 0 {
                self.eof = true;
            } else {
                self.buf.extend_from_slice(&tmp[..n]);
            }
        }
    }
}

fn parse_info_line(line: &str, position: &Position) -> Option<(u32, i32, Vec<String>)> {
    if !line.starts_with("info ") {
        return None;
    }
    let mut depth = None;
    let mut eval = None;
    let mut pv_start = None;
    let parts: Vec<_> = line.split_whitespace().collect();
    let mut i = 0;
    while i < parts.len() {
        match parts[i] {
            "depth" => {
                depth = parts.get(i + 1).and_then(|d| d.parse().ok());
                i += 2;
            }
            "score" => {
                match (parts.get(i + 1), parts.get(i + 2)) {
                    (Some(&"cp"), Some(v)) => eval = v.parse().ok(),
                    (Some(&"mate"), Some(v)) => {
                        eval = v.parse::<i32>().ok().map(|m| m.signum() * 30_000 - m * 10)
                    }
                    _ => {}
                }
                i += 3;
            }
            "pv" => {
                pv_start = Some(i + 1);
                break;
            }
            _ => i += 1,
        }
    }
    let depth = depth?;
    let eval = eval.unwrap_or_default();
    let mut pos = position.clone();
    let mut pv_san = Vec::new();
    if let Some(start) = pv_start {
        for uci in &parts[start..parts.len().min(start + 5)] {
            let Some(mv) = pos.parse_uci(uci) else {
                break;
            };
            pv_san.push(pos.move_to_san(mv));
            pos.make_move(mv);
        }
    }
    Some((depth, eval, pv_san))
}
