//! PGN import/export.

use std::collections::HashMap;

use crate::{
    api::{ApiError, ApiResult, GameResult, Move},
    engine::{square_name, ChessMove, Position, STARTING_FEN},
};

#[derive(Debug, Clone)]
pub struct ParsedPgn {
    pub tags: HashMap<String, String>,
    pub position: Position,
    pub history: Vec<Move>,
    pub result: GameResult,
}

pub fn parse(pgn: &str) -> ApiResult<ParsedPgn> {
    let mut tags = HashMap::new();
    let mut movetext = String::new();
    for line in pgn.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with('[') && trimmed.ends_with(']') {
            if let Some((key, value)) = parse_tag(trimmed) {
                tags.insert(key, value);
            }
        } else {
            movetext.push_str(line);
            movetext.push(' ');
        }
    }

    let cleaned = strip_movetext_noise(&movetext);
    let mut pos = Position::from_fen(tags.get("FEN").map(String::as_str).unwrap_or(STARTING_FEN))
        .map_err(ApiError::InvalidInput)?;
    let mut history = Vec::new();
    let mut result = GameResult::Ongoing;
    for token in cleaned.split_whitespace() {
        if let Some(r) = parse_result(token) {
            result = r;
            break;
        }
        if token.ends_with('.') || token.contains("...") {
            continue;
        }
        let san = token.trim_matches(|c: char| c == '+' || c == '#' || c == '!' || c == '?');
        let mv = pos
            .parse_san(san)
            .ok_or_else(|| ApiError::IllegalMove(format!("invalid PGN move: {token}")))?;
        let api_move = api_move_from_engine(&pos, mv);
        pos.make_move(mv);
        history.push(api_move);
    }
    Ok(ParsedPgn {
        tags,
        position: pos,
        history,
        result,
    })
}

pub fn serialize(history: &[Move], result: GameResult, white: Option<&str>, black: Option<&str>) -> String {
    let result_text = result_text(result);
    let mut out = String::new();
    for (key, value) in [
        ("Event", "Casual Game"),
        ("Site", "Chess Desktop"),
        ("Date", "????.??.??"),
        ("Round", "-"),
        ("White", white.unwrap_or("White")),
        ("Black", black.unwrap_or("Black")),
        ("Result", result_text),
    ] {
        out.push_str(&format!("[{key} \"{value}\"]\n"));
    }
    out.push('\n');
    for (idx, mv) in history.iter().enumerate() {
        if idx % 2 == 0 {
            out.push_str(&format!("{}. ", idx / 2 + 1));
        }
        out.push_str(&mv.san);
        out.push(' ');
    }
    out.push_str(result_text);
    out.push('\n');
    out
}

fn api_move_from_engine(pos: &Position, mv: ChessMove) -> Move {
    let san = pos.move_to_san(mv);
    let mut after = pos.clone();
    after.make_move(mv);
    let is_check = after.is_in_check(after.side_to_move);
    let is_mate = is_check && after.legal_moves().is_empty();
    Move {
        from: square_name(mv.from),
        to: square_name(mv.to),
        promotion: mv.promotion,
        san,
        uci: mv.uci(),
        captured: pos.captured_piece_for(mv),
        is_check,
        is_mate,
        is_castle: mv.is_castle(),
        is_en_passant: mv.is_en_passant(),
    }
}

fn parse_tag(line: &str) -> Option<(String, String)> {
    let inner = line.strip_prefix('[')?.strip_suffix(']')?.trim();
    let first_space = inner.find(char::is_whitespace)?;
    let key = inner[..first_space].to_string();
    let value = inner[first_space..].trim();
    Some((
        key,
        value
            .strip_prefix('"')?
            .strip_suffix('"')?
            .replace("\\\"", "\""),
    ))
}

fn strip_movetext_noise(input: &str) -> String {
    let mut out = String::new();
    let mut comment = false;
    let mut variation_depth = 0u32;
    let mut chars = input.chars().peekable();
    while let Some(ch) = chars.next() {
        if comment {
            if ch == '}' {
                comment = false;
            }
            continue;
        }
        if variation_depth > 0 {
            match ch {
                '(' => variation_depth += 1,
                ')' => variation_depth -= 1,
                _ => {}
            }
            continue;
        }
        match ch {
            '{' => comment = true,
            ';' => {
                for next in chars.by_ref() {
                    if next == '\n' {
                        break;
                    }
                }
            }
            '(' => variation_depth = 1,
            '$' => {
                while chars.peek().is_some_and(|c| c.is_ascii_digit()) {
                    chars.next();
                }
            }
            _ => out.push(ch),
        }
    }
    out
}

fn parse_result(token: &str) -> Option<GameResult> {
    match token {
        "1-0" => Some(GameResult::White),
        "0-1" => Some(GameResult::Black),
        "1/2-1/2" => Some(GameResult::Draw),
        "*" => Some(GameResult::Ongoing),
        _ => None,
    }
}

fn result_text(result: GameResult) -> &'static str {
    match result {
        GameResult::White => "1-0",
        GameResult::Black => "0-1",
        GameResult::Draw => "1/2-1/2",
        GameResult::Ongoing => "*",
    }
}
