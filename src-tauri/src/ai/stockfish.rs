//! UCI sidecar wrapper for Stockfish. In development the sidecar can be a
//! placeholder stub, so this module validates the binary before spawning.

use std::{fs, path::PathBuf, time::Duration};

use tauri::AppHandle;
use tauri_plugin_shell::{process::CommandEvent, ShellExt};

use crate::{
    ai::custom::{self, SearchOutput},
    api::{AiProgressEvent, ApiError, ApiResult},
    engine::Position,
};

pub async fn choose_move(
    app: Option<AppHandle>,
    game_id: &str,
    position: &Position,
    history_uci: &[String],
    difficulty: u8,
    mut progress: impl FnMut(AiProgressEvent) + Send + 'static,
) -> ApiResult<Option<SearchOutput>> {
    let Some(app) = app else {
        return Ok(custom::choose_move(game_id, position, 3, progress));
    };
    if !sidecar_looks_real() {
        log::warn!("Stockfish sidecar is missing or a placeholder; using custom engine fallback");
        return Ok(custom::choose_move(game_id, position, 3, progress));
    }

    match run_stockfish(&app, game_id, position, history_uci, difficulty, &mut progress).await {
        Ok(Some(output)) => Ok(Some(output)),
        Ok(None) => Ok(custom::choose_move(game_id, position, 3, progress)),
        Err(err) => {
            log::warn!("Stockfish failed ({err}); using custom engine fallback");
            Ok(custom::choose_move(game_id, position, 3, progress))
        }
    }
}

async fn run_stockfish(
    app: &AppHandle,
    game_id: &str,
    position: &Position,
    history_uci: &[String],
    difficulty: u8,
    progress: &mut (impl FnMut(AiProgressEvent) + Send + 'static),
) -> ApiResult<Option<SearchOutput>> {
    let (skill, depth) = stockfish_level(difficulty);
    let (mut rx, mut child) = app
        .shell()
        .sidecar("binaries/stockfish")
        .map_err(|e| ApiError::Engine(format!("stockfish sidecar: {e}")))?
        .spawn()
        .map_err(|e| ApiError::Engine(format!("stockfish spawn: {e}")))?;

    child
        .write(b"uci\n")
        .map_err(|e| ApiError::Engine(format!("stockfish stdin: {e}")))?;
    child
        .write(format!("setoption name Skill Level value {skill}\n").as_bytes())
        .map_err(|e| ApiError::Engine(format!("stockfish stdin: {e}")))?;
    child
        .write(b"isready\n")
        .map_err(|e| ApiError::Engine(format!("stockfish stdin: {e}")))?;
    child
        .write(b"ucinewgame\n")
        .map_err(|e| ApiError::Engine(format!("stockfish stdin: {e}")))?;

    let mut position_cmd = format!("position fen {}", position.to_fen());
    if !history_uci.is_empty() {
        position_cmd.push_str(" moves ");
        position_cmd.push_str(&history_uci.join(" "));
    }
    position_cmd.push('\n');
    child
        .write(position_cmd.as_bytes())
        .map_err(|e| ApiError::Engine(format!("stockfish stdin: {e}")))?;
    child
        .write(format!("go depth {depth}\n").as_bytes())
        .map_err(|e| ApiError::Engine(format!("stockfish stdin: {e}")))?;

    let mut best = None;
    let mut best_eval = 0;
    let mut best_depth = 0;
    let deadline = tokio::time::sleep(Duration::from_secs(8));
    tokio::pin!(deadline);

    loop {
        tokio::select! {
            _ = &mut deadline => {
                let _ = child.write(b"stop\n");
                break;
            }
            event = rx.recv() => {
                let Some(event) = event else { break; };
                match event {
                    CommandEvent::Stdout(bytes) => {
                        let line = String::from_utf8_lossy(&bytes);
                        for line in line.lines() {
                            if let Some((depth, eval, pv)) = parse_info_line(line, position) {
                                best_eval = eval;
                                best_depth = depth;
                                progress(AiProgressEvent {
                                    game_id: game_id.to_string(),
                                    depth,
                                    eval_cp: eval,
                                    pv_san: pv,
                                });
                            } else if let Some(uci) = line.strip_prefix("bestmove ").and_then(|rest| rest.split_whitespace().next()) {
                                let mut pos = position.clone();
                                best = pos.parse_uci(uci);
                                break;
                            }
                        }
                        if best.is_some() {
                            break;
                        }
                    }
                    CommandEvent::Stderr(bytes) => {
                        log::warn!("stockfish stderr: {}", String::from_utf8_lossy(&bytes));
                    }
                    CommandEvent::Error(err) => return Err(ApiError::Engine(err)),
                    CommandEvent::Terminated(_) => break,
                    _ => {}
                }
            }
        }
    }

    let _ = child.kill();
    Ok(best.map(|mv| SearchOutput {
        mv,
        eval_cp: best_eval,
        depth: best_depth,
        pv: vec![mv],
    }))
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

fn stockfish_level(difficulty: u8) -> (u8, u32) {
    match difficulty {
        4 => (5, 6),
        5 => (8, 8),
        6 => (11, 10),
        7 => (14, 12),
        8 => (17, 14),
        9 => (20, 18),
        10 => (20, 22),
        _ => (5, 6),
    }
}

fn sidecar_looks_real() -> bool {
    let Some(path) = sidecar_path() else {
        return false;
    };
    let Ok(bytes) = fs::read(path) else {
        return false;
    };
    bytes.starts_with(&[0x7f, b'E', b'L', b'F'])
        || bytes.starts_with(&[0xcf, 0xfa, 0xed, 0xfe])
        || bytes.starts_with(&[0xca, 0xfe, 0xba, 0xbe])
        || bytes.starts_with(&[0xfe, 0xed, 0xfa, 0xcf])
        || bytes.starts_with(b"MZ")
}

fn sidecar_path() -> Option<PathBuf> {
    let triple = target_triple();
    let exe = if cfg!(windows) { ".exe" } else { "" };
    Some(
        PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("binaries")
            .join(format!("stockfish-{triple}{exe}")),
    )
}

fn target_triple() -> &'static str {
    if cfg!(all(target_os = "macos", target_arch = "aarch64")) {
        "aarch64-apple-darwin"
    } else if cfg!(all(target_os = "macos", target_arch = "x86_64")) {
        "x86_64-apple-darwin"
    } else if cfg!(all(target_os = "linux", target_arch = "x86_64")) {
        "x86_64-unknown-linux-gnu"
    } else if cfg!(all(target_os = "windows", target_arch = "x86_64")) {
        "x86_64-pc-windows-msvc"
    } else {
        "unknown"
    }
}
