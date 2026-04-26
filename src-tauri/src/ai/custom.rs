//! Small classical search used for local difficulty levels and Stockfish fallback.

use std::collections::HashMap;

use rand::{seq::SliceRandom, Rng};

use crate::{
    api::{AiProgressEvent, Color, PieceKind},
    engine::{opposite, piece_value, ChessMove, Position},
};

const MATE: i32 = 30_000;

#[derive(Debug, Clone)]
pub struct SearchOutput {
    pub mv: ChessMove,
    pub eval_cp: i32,
    pub depth: u32,
    pub pv: Vec<ChessMove>,
}

#[derive(Debug, Clone)]
struct TtEntry {
    depth: u32,
    score: i32,
}

pub fn choose_move(
    game_id: &str,
    position: &Position,
    difficulty: u8,
    mut progress: impl FnMut(AiProgressEvent),
) -> Option<SearchOutput> {
    let (max_depth, noise) = match difficulty {
        1 => (2, 0.30),
        2 => (3, 0.10),
        _ => (4, 0.0),
    };

    let mut rng = rand::thread_rng();
    let mut root = position.clone();
    let legal = root.legal_moves();
    if legal.is_empty() {
        return None;
    }
    if noise > 0.0 && rng.gen_bool(noise) {
        let mv = *legal.choose(&mut rng)?;
        return Some(SearchOutput {
            mv,
            eval_cp: evaluate(position),
            depth: 0,
            pv: vec![mv],
        });
    }

    let mut table = HashMap::new();
    let mut best = None;
    for depth in 1..=max_depth {
        let mut search_pos = position.clone();
        let (mv, eval) = search_root(&mut search_pos, depth, &mut table)?;
        let pv = principal_variation(position.clone(), mv, &table, depth);
        progress(AiProgressEvent {
            game_id: game_id.to_string(),
            depth,
            eval_cp: eval,
            pv_san: pv_to_san(position, &pv),
        });
        best = Some(SearchOutput {
            mv,
            eval_cp: eval,
            depth,
            pv,
        });
    }
    best
}

fn pv_to_san(position: &Position, pv: &[ChessMove]) -> Vec<String> {
    let mut pos = position.clone();
    let mut sans = Vec::with_capacity(pv.len());
    for mv in pv {
        sans.push(pos.move_to_san(*mv));
        pos.make_move(*mv);
    }
    sans
}

fn search_root(
    pos: &mut Position,
    depth: u32,
    table: &mut HashMap<u64, TtEntry>,
) -> Option<(ChessMove, i32)> {
    let mut best = None;
    let mut alpha = -MATE;
    let mut moves = ordered_moves(pos);
    for mv in moves.drain(..) {
        pos.make_move(mv);
        let score = -negamax(pos, depth.saturating_sub(1), -MATE, -alpha, 1, table);
        pos.unmake_move();
        if best.is_none() || score > alpha {
            alpha = score;
            best = Some((mv, score));
        }
    }
    best
}

fn negamax(
    pos: &mut Position,
    depth: u32,
    mut alpha: i32,
    beta: i32,
    ply: i32,
    table: &mut HashMap<u64, TtEntry>,
) -> i32 {
    let hash = pos.zobrist_hash();
    if let Some(entry) = table.get(&hash) {
        if entry.depth >= depth {
            return entry.score;
        }
    }
    if depth == 0 {
        return quiescence(pos, alpha, beta, 0);
    }

    let moves = ordered_moves(pos);
    if moves.is_empty() {
        return if pos.is_in_check(pos.side_to_move) {
            -MATE + ply
        } else {
            0
        };
    }

    let mut best = -MATE;
    for mv in moves {
        pos.make_move(mv);
        let score = -negamax(pos, depth - 1, -beta, -alpha, ply + 1, table);
        pos.unmake_move();
        best = best.max(score);
        alpha = alpha.max(score);
        if alpha >= beta {
            break;
        }
    }
    table.insert(hash, TtEntry { depth, score: best });
    best
}

fn quiescence(pos: &mut Position, mut alpha: i32, beta: i32, depth: u32) -> i32 {
    let stand_pat = evaluate(pos);
    if stand_pat >= beta {
        return beta;
    }
    alpha = alpha.max(stand_pat);
    if depth >= 6 {
        return alpha;
    }
    let captures: Vec<_> = ordered_moves(pos)
        .into_iter()
        .filter(|mv| mv.is_capture())
        .collect();
    for mv in captures {
        pos.make_move(mv);
        let score = -quiescence(pos, -beta, -alpha, depth + 1);
        pos.unmake_move();
        if score >= beta {
            return beta;
        }
        alpha = alpha.max(score);
    }
    alpha
}

fn ordered_moves(pos: &mut Position) -> Vec<ChessMove> {
    let mut moves = pos.legal_moves();
    moves.sort_by_key(|mv| {
        let captured = pos.piece_at(mv.to).map(|p| piece_value(p.kind)).unwrap_or(0);
        let promo = mv.promotion.map(|p| piece_value(match p {
            crate::api::Promotion::N => PieceKind::N,
            crate::api::Promotion::B => PieceKind::B,
            crate::api::Promotion::R => PieceKind::R,
            crate::api::Promotion::Q => PieceKind::Q,
        })).unwrap_or(0);
        -(captured + promo)
    });
    moves
}

fn principal_variation(
    mut pos: Position,
    first: ChessMove,
    table: &HashMap<u64, TtEntry>,
    max_depth: u32,
) -> Vec<ChessMove> {
    let mut pv = vec![first];
    pos.make_move(first);
    for _ in 1..max_depth.min(5) {
        let mut best = None;
        let mut best_score = -MATE;
        for mv in pos.legal_moves() {
            pos.make_move(mv);
            let score = table
                .get(&pos.zobrist_hash())
                .map(|entry| -entry.score)
                .unwrap_or_else(|| -evaluate(&pos));
            pos.unmake_move();
            if score > best_score {
                best_score = score;
                best = Some(mv);
            }
        }
        let Some(mv) = best else {
            break;
        };
        pv.push(mv);
        pos.make_move(mv);
    }
    pv
}

pub fn evaluate(pos: &Position) -> i32 {
    let mut score = 0;
    for sq in 0u8..64 {
        let Some(piece) = pos.piece_at(sq) else {
            continue;
        };
        let sign = if piece.color == Color::W { 1 } else { -1 };
        score += sign * (piece_value(piece.kind) + psqt(piece.kind, piece.color, sq));
    }

    let mut white = pos.clone();
    white.side_to_move = Color::W;
    let white_mobility = white.legal_moves().len() as i32;
    let mut black = pos.clone();
    black.side_to_move = Color::B;
    let black_mobility = black.legal_moves().len() as i32;
    score += 2 * (white_mobility - black_mobility);

    if pos.is_in_check(Color::W) {
        score -= 20;
    }
    if pos.is_in_check(Color::B) {
        score += 20;
    }

    if pos.side_to_move == Color::W {
        score
    } else {
        -score
    }
}

fn psqt(kind: PieceKind, color: Color, sq: u8) -> i32 {
    let file = (sq % 8) as i32;
    let rank = if color == Color::W {
        (sq / 8) as i32
    } else {
        7 - (sq / 8) as i32
    };
    let center_file = (file - 3).abs().min((file - 4).abs());
    let center_rank = (rank - 3).abs().min((rank - 4).abs());
    match kind {
        PieceKind::P => rank * 6 - center_file * 2,
        PieceKind::N => 18 - 4 * (center_file + center_rank),
        PieceKind::B => 12 - 3 * (center_file + center_rank),
        PieceKind::R => rank * 2,
        PieceKind::Q => 6 - (center_file + center_rank),
        PieceKind::K => {
            if rank <= 1 {
                8 - center_file
            } else {
                -4 * (center_file + center_rank)
            }
        }
    }
}

#[allow(dead_code)]
fn _side_after_move(color: Color) -> Color {
    opposite(color)
}
