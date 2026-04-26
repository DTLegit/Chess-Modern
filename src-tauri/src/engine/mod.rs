//! Chess rules, board representation, FEN/SAN/UCI conversion, and perft.

use std::collections::HashMap;

use crate::api::{Color, GameResult, GameStatus, Piece, PieceKind, Promotion, SquareStr};

pub const STARTING_FEN: &str = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

const WHITE_KINGSIDE: u8 = 0b0001;
const WHITE_QUEENSIDE: u8 = 0b0010;
const BLACK_KINGSIDE: u8 = 0b0100;
const BLACK_QUEENSIDE: u8 = 0b1000;

const FLAG_CAPTURE: u8 = 0b0001;
const FLAG_EN_PASSANT: u8 = 0b0010;
const FLAG_CASTLE: u8 = 0b0100;
const FLAG_DOUBLE_PAWN: u8 = 0b1000;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct ChessMove {
    pub from: u8,
    pub to: u8,
    pub promotion: Option<Promotion>,
    pub flags: u8,
}

impl ChessMove {
    pub fn new(from: u8, to: u8, promotion: Option<Promotion>, flags: u8) -> Self {
        Self {
            from,
            to,
            promotion,
            flags,
        }
    }

    pub fn is_capture(self) -> bool {
        self.flags & FLAG_CAPTURE != 0
    }

    pub fn is_en_passant(self) -> bool {
        self.flags & FLAG_EN_PASSANT != 0
    }

    pub fn is_castle(self) -> bool {
        self.flags & FLAG_CASTLE != 0
    }

    pub fn uci(self) -> String {
        let mut out = format!("{}{}", square_name(self.from), square_name(self.to));
        if let Some(p) = self.promotion {
            out.push(match p {
                Promotion::N => 'n',
                Promotion::B => 'b',
                Promotion::R => 'r',
                Promotion::Q => 'q',
            });
        }
        out
    }
}

#[derive(Debug, Clone)]
struct Undo {
    mv: ChessMove,
    moved: Piece,
    captured: Option<Piece>,
    castling: u8,
    en_passant: Option<u8>,
    halfmove_clock: u32,
    fullmove_number: u32,
}

#[derive(Debug, Clone)]
pub struct Position {
    /// One bitboard per colored piece kind: white P,N,B,R,Q,K then black P,N,B,R,Q,K.
    pub bitboards: [u64; 12],
    pub side_to_move: Color,
    pub castling: u8,
    pub en_passant: Option<u8>,
    pub halfmove_clock: u32,
    pub fullmove_number: u32,
    history: Vec<Undo>,
    repetition: HashMap<u64, u32>,
}

impl Default for Position {
    fn default() -> Self {
        Self::from_fen(STARTING_FEN).expect("starting FEN is valid")
    }
}

impl Position {
    pub fn from_fen(fen: &str) -> Result<Self, String> {
        let mut parts = fen.split_whitespace();
        let board = parts.next().ok_or("missing board")?;
        let side = parts.next().ok_or("missing side to move")?;
        let castling = parts.next().ok_or("missing castling rights")?;
        let ep = parts.next().ok_or("missing en passant square")?;
        let halfmove = parts.next().unwrap_or("0");
        let fullmove = parts.next().unwrap_or("1");

        let mut bitboards = [0u64; 12];
        let mut rank: i32 = 7;
        let mut file: i32 = 0;
        for ch in board.chars() {
            match ch {
                '/' => {
                    if file != 8 {
                        return Err("invalid FEN rank width".into());
                    }
                    rank -= 1;
                    file = 0;
                }
                '1'..='8' => file += ch.to_digit(10).unwrap() as i32,
                _ => {
                    if !(0..8).contains(&rank) || !(0..8).contains(&file) {
                        return Err("invalid FEN board coordinates".into());
                    }
                    let piece = piece_from_fen(ch).ok_or_else(|| format!("invalid piece: {ch}"))?;
                    let sq = (rank * 8 + file) as u8;
                    bitboards[piece_index(piece)] |= bit(sq);
                    file += 1;
                }
            }
        }
        if rank != 0 || file != 8 {
            return Err("invalid FEN board".into());
        }

        let side_to_move = match side {
            "w" => Color::W,
            "b" => Color::B,
            _ => return Err("invalid side to move".into()),
        };

        let mut castle_bits = 0;
        if castling != "-" {
            for c in castling.chars() {
                castle_bits |= match c {
                    'K' => WHITE_KINGSIDE,
                    'Q' => WHITE_QUEENSIDE,
                    'k' => BLACK_KINGSIDE,
                    'q' => BLACK_QUEENSIDE,
                    _ => return Err("invalid castling rights".into()),
                };
            }
        }

        let en_passant = if ep == "-" {
            None
        } else {
            Some(square_index(ep).ok_or("invalid en passant square")?)
        };

        let mut pos = Self {
            bitboards,
            side_to_move,
            castling: castle_bits,
            en_passant,
            halfmove_clock: halfmove.parse().map_err(|_| "invalid halfmove clock")?,
            fullmove_number: fullmove.parse().map_err(|_| "invalid fullmove number")?,
            history: Vec::new(),
            repetition: HashMap::new(),
        };
        pos.repetition.insert(pos.zobrist_hash(), 1);
        Ok(pos)
    }

    pub fn to_fen(&self) -> String {
        let mut board = String::new();
        for rank in (0..8).rev() {
            let mut empty = 0;
            for file in 0..8 {
                let sq = rank * 8 + file;
                if let Some(piece) = self.piece_at(sq) {
                    if empty > 0 {
                        board.push(char::from_digit(empty, 10).unwrap());
                        empty = 0;
                    }
                    board.push(piece_to_fen(piece));
                } else {
                    empty += 1;
                }
            }
            if empty > 0 {
                board.push(char::from_digit(empty, 10).unwrap());
            }
            if rank > 0 {
                board.push('/');
            }
        }

        let side = match self.side_to_move {
            Color::W => "w",
            Color::B => "b",
        };
        let mut castling = String::new();
        if self.castling & WHITE_KINGSIDE != 0 {
            castling.push('K');
        }
        if self.castling & WHITE_QUEENSIDE != 0 {
            castling.push('Q');
        }
        if self.castling & BLACK_KINGSIDE != 0 {
            castling.push('k');
        }
        if self.castling & BLACK_QUEENSIDE != 0 {
            castling.push('q');
        }
        if castling.is_empty() {
            castling.push('-');
        }
        let ep = self.en_passant.map(square_name).unwrap_or_else(|| "-".into());
        format!(
            "{board} {side} {castling} {ep} {} {}",
            self.halfmove_clock, self.fullmove_number
        )
    }

    pub fn piece_at(&self, sq: u8) -> Option<Piece> {
        let mask = bit(sq);
        for color in [Color::W, Color::B] {
            for kind in [
                PieceKind::P,
                PieceKind::N,
                PieceKind::B,
                PieceKind::R,
                PieceKind::Q,
                PieceKind::K,
            ] {
                let piece = Piece { color, kind };
                if self.bitboards[piece_index(piece)] & mask != 0 {
                    return Some(piece);
                }
            }
        }
        None
    }

    pub fn king_square(&self, color: Color) -> Option<u8> {
        let bb = self.bitboards[piece_index(Piece {
            color,
            kind: PieceKind::K,
        })];
        if bb == 0 {
            None
        } else {
            Some(bb.trailing_zeros() as u8)
        }
    }

    pub fn occupancy(&self) -> u64 {
        self.bitboards.iter().fold(0, |acc, bb| acc | bb)
    }

    pub fn color_occupancy(&self, color: Color) -> u64 {
        let offset = if color == Color::W { 0 } else { 6 };
        self.bitboards[offset..offset + 6]
            .iter()
            .fold(0, |acc, bb| acc | bb)
    }

    pub fn is_in_check(&self, color: Color) -> bool {
        self.king_square(color)
            .is_some_and(|sq| self.is_square_attacked(sq, opposite(color)))
    }

    pub fn is_square_attacked(&self, sq: u8, by: Color) -> bool {
        let file = file_of(sq);
        let rank = rank_of(sq);

        let pawn_sources: &[(i8, i8)] = match by {
            Color::W => &[(-1, -1), (1, -1)],
            Color::B => &[(-1, 1), (1, 1)],
        };
        for (df, dr) in pawn_sources {
            if let Some(from) = offset_square(file, rank, *df, *dr) {
                if self.piece_at(from)
                    == Some(Piece {
                        color: by,
                        kind: PieceKind::P,
                    })
                {
                    return true;
                }
            }
        }

        for (df, dr) in KNIGHT_DELTAS {
            if let Some(from) = offset_square(file, rank, df, dr) {
                if self.piece_at(from)
                    == Some(Piece {
                        color: by,
                        kind: PieceKind::N,
                    })
                {
                    return true;
                }
            }
        }

        for (df, dr) in KING_DELTAS {
            if let Some(from) = offset_square(file, rank, df, dr) {
                if self.piece_at(from)
                    == Some(Piece {
                        color: by,
                        kind: PieceKind::K,
                    })
                {
                    return true;
                }
            }
        }

        for (df, dr) in BISHOP_DELTAS {
            if self.ray_attacked(sq, by, df, dr, &[PieceKind::B, PieceKind::Q]) {
                return true;
            }
        }
        for (df, dr) in ROOK_DELTAS {
            if self.ray_attacked(sq, by, df, dr, &[PieceKind::R, PieceKind::Q]) {
                return true;
            }
        }
        false
    }

    fn ray_attacked(&self, sq: u8, by: Color, df: i8, dr: i8, sliders: &[PieceKind]) -> bool {
        let mut file = file_of(sq) as i8 + df;
        let mut rank = rank_of(sq) as i8 + dr;
        while (0..8).contains(&file) && (0..8).contains(&rank) {
            let target = (rank * 8 + file) as u8;
            if let Some(piece) = self.piece_at(target) {
                return piece.color == by && sliders.contains(&piece.kind);
            }
            file += df;
            rank += dr;
        }
        false
    }

    pub fn legal_moves(&mut self) -> Vec<ChessMove> {
        let us = self.side_to_move;
        let pseudo = self.pseudo_legal_moves(false);
        let mut legal = Vec::with_capacity(pseudo.len());
        for mv in pseudo {
            self.make_move(mv);
            if !self.is_in_check(us) {
                legal.push(mv);
            }
            self.unmake_move();
        }
        legal
    }

    pub fn legal_moves_from(&mut self, square: &str) -> Vec<SquareStr> {
        let Some(sq) = square_index(square) else {
            return Vec::new();
        };
        self.legal_moves()
            .into_iter()
            .filter(|mv| mv.from == sq)
            .map(|mv| square_name(mv.to))
            .collect()
    }

    pub fn legal_moves_map(&mut self) -> HashMap<SquareStr, Vec<SquareStr>> {
        let mut map: HashMap<SquareStr, Vec<SquareStr>> = HashMap::new();
        for mv in self.legal_moves() {
            map.entry(square_name(mv.from))
                .or_default()
                .push(square_name(mv.to));
        }
        for targets in map.values_mut() {
            targets.sort();
            targets.dedup();
        }
        map
    }

    pub fn pseudo_legal_moves(&self, captures_only: bool) -> Vec<ChessMove> {
        let mut moves = Vec::with_capacity(64);
        for sq in 0u8..64 {
            let Some(piece) = self.piece_at(sq) else {
                continue;
            };
            if piece.color != self.side_to_move {
                continue;
            }
            match piece.kind {
                PieceKind::P => self.gen_pawn_moves(sq, piece.color, captures_only, &mut moves),
                PieceKind::N => self.gen_leaper_moves(sq, piece, &KNIGHT_DELTAS, captures_only, &mut moves),
                PieceKind::B => self.gen_slider_moves(sq, piece, &BISHOP_DELTAS, captures_only, &mut moves),
                PieceKind::R => self.gen_slider_moves(sq, piece, &ROOK_DELTAS, captures_only, &mut moves),
                PieceKind::Q => self.gen_slider_moves(sq, piece, &QUEEN_DELTAS, captures_only, &mut moves),
                PieceKind::K => {
                    self.gen_leaper_moves(sq, piece, &KING_DELTAS, captures_only, &mut moves);
                    if !captures_only {
                        self.gen_castles(sq, piece.color, &mut moves);
                    }
                }
            }
        }
        moves
    }

    fn gen_pawn_moves(&self, sq: u8, color: Color, captures_only: bool, moves: &mut Vec<ChessMove>) {
        let rank = rank_of(sq);
        let file = file_of(sq);
        let dir: i8 = if color == Color::W { 1 } else { -1 };
        let start_rank = if color == Color::W { 1 } else { 6 };
        let promotion_rank = if color == Color::W { 6 } else { 1 };

        if !captures_only {
            if let Some(one) = offset_square(file, rank, 0, dir) {
                if self.piece_at(one).is_none() {
                    self.push_pawn_move(sq, one, rank == promotion_rank, 0, moves);
                    if rank == start_rank {
                        if let Some(two) = offset_square(file, rank, 0, dir * 2) {
                            if self.piece_at(two).is_none() {
                                moves.push(ChessMove::new(sq, two, None, FLAG_DOUBLE_PAWN));
                            }
                        }
                    }
                }
            }
        }

        for df in [-1, 1] {
            if let Some(to) = offset_square(file, rank, df, dir) {
                let mut flags = 0;
                let capture = self
                    .piece_at(to)
                    .is_some_and(|p| p.color == opposite(color));
                let ep = self.en_passant == Some(to);
                if capture {
                    flags |= FLAG_CAPTURE;
                } else if ep {
                    flags |= FLAG_CAPTURE | FLAG_EN_PASSANT;
                } else {
                    continue;
                }
                self.push_pawn_move(sq, to, rank == promotion_rank, flags, moves);
            }
        }
    }

    fn push_pawn_move(
        &self,
        from: u8,
        to: u8,
        promotes: bool,
        flags: u8,
        moves: &mut Vec<ChessMove>,
    ) {
        if promotes {
            for promotion in [Promotion::Q, Promotion::R, Promotion::B, Promotion::N] {
                moves.push(ChessMove::new(from, to, Some(promotion), flags));
            }
        } else {
            moves.push(ChessMove::new(from, to, None, flags));
        }
    }

    fn gen_leaper_moves(
        &self,
        sq: u8,
        piece: Piece,
        deltas: &[(i8, i8)],
        captures_only: bool,
        moves: &mut Vec<ChessMove>,
    ) {
        let file = file_of(sq);
        let rank = rank_of(sq);
        for (df, dr) in deltas {
            if let Some(to) = offset_square(file, rank, *df, *dr) {
                match self.piece_at(to) {
                    Some(target) if target.color == piece.color => {}
                    Some(_) => moves.push(ChessMove::new(sq, to, None, FLAG_CAPTURE)),
                    None if !captures_only => moves.push(ChessMove::new(sq, to, None, 0)),
                    None => {}
                }
            }
        }
    }

    fn gen_slider_moves(
        &self,
        sq: u8,
        piece: Piece,
        deltas: &[(i8, i8)],
        captures_only: bool,
        moves: &mut Vec<ChessMove>,
    ) {
        for (df, dr) in deltas {
            let mut file = file_of(sq) as i8 + df;
            let mut rank = rank_of(sq) as i8 + dr;
            while (0..8).contains(&file) && (0..8).contains(&rank) {
                let to = (rank * 8 + file) as u8;
                match self.piece_at(to) {
                    Some(target) if target.color == piece.color => break,
                    Some(_) => {
                        moves.push(ChessMove::new(sq, to, None, FLAG_CAPTURE));
                        break;
                    }
                    None if !captures_only => moves.push(ChessMove::new(sq, to, None, 0)),
                    None => {}
                }
                file += df;
                rank += dr;
            }
        }
    }

    fn gen_castles(&self, sq: u8, color: Color, moves: &mut Vec<ChessMove>) {
        if color == Color::W && sq == 4 && !self.is_in_check(Color::W) {
            if self.castling & WHITE_KINGSIDE != 0
                && self.piece_at(7)
                    == Some(Piece {
                        color,
                        kind: PieceKind::R,
                    })
                && self.piece_at(5).is_none()
                && self.piece_at(6).is_none()
                && !self.is_square_attacked(5, Color::B)
                && !self.is_square_attacked(6, Color::B)
            {
                moves.push(ChessMove::new(4, 6, None, FLAG_CASTLE));
            }
            if self.castling & WHITE_QUEENSIDE != 0
                && self.piece_at(0)
                    == Some(Piece {
                        color,
                        kind: PieceKind::R,
                    })
                && self.piece_at(1).is_none()
                && self.piece_at(2).is_none()
                && self.piece_at(3).is_none()
                && !self.is_square_attacked(2, Color::B)
                && !self.is_square_attacked(3, Color::B)
            {
                moves.push(ChessMove::new(4, 2, None, FLAG_CASTLE));
            }
        } else if color == Color::B && sq == 60 && !self.is_in_check(Color::B) {
            if self.castling & BLACK_KINGSIDE != 0
                && self.piece_at(63)
                    == Some(Piece {
                        color,
                        kind: PieceKind::R,
                    })
                && self.piece_at(61).is_none()
                && self.piece_at(62).is_none()
                && !self.is_square_attacked(61, Color::W)
                && !self.is_square_attacked(62, Color::W)
            {
                moves.push(ChessMove::new(60, 62, None, FLAG_CASTLE));
            }
            if self.castling & BLACK_QUEENSIDE != 0
                && self.piece_at(56)
                    == Some(Piece {
                        color,
                        kind: PieceKind::R,
                    })
                && self.piece_at(57).is_none()
                && self.piece_at(58).is_none()
                && self.piece_at(59).is_none()
                && !self.is_square_attacked(58, Color::W)
                && !self.is_square_attacked(59, Color::W)
            {
                moves.push(ChessMove::new(60, 58, None, FLAG_CASTLE));
            }
        }
    }

    pub fn make_move(&mut self, mv: ChessMove) {
        let moved = self.piece_at(mv.from).expect("move has a piece on from-square");
        let captured_square = if mv.is_en_passant() {
            Some(if moved.color == Color::W { mv.to - 8 } else { mv.to + 8 })
        } else {
            Some(mv.to)
        };
        let captured = captured_square.and_then(|sq| self.piece_at(sq));
        let undo = Undo {
            mv,
            moved,
            captured,
            castling: self.castling,
            en_passant: self.en_passant,
            halfmove_clock: self.halfmove_clock,
            fullmove_number: self.fullmove_number,
        };
        self.history.push(undo);

        self.remove_piece(mv.from, moved);
        if let (Some(piece), Some(sq)) = (captured, captured_square) {
            self.remove_piece(sq, piece);
        }

        if mv.is_castle() {
            match (moved.color, mv.to) {
                (Color::W, 6) => {
                    self.remove_piece(
                        7,
                        Piece {
                            color: Color::W,
                            kind: PieceKind::R,
                        },
                    );
                    self.set_piece(
                        5,
                        Piece {
                            color: Color::W,
                            kind: PieceKind::R,
                        },
                    );
                }
                (Color::W, 2) => {
                    self.remove_piece(
                        0,
                        Piece {
                            color: Color::W,
                            kind: PieceKind::R,
                        },
                    );
                    self.set_piece(
                        3,
                        Piece {
                            color: Color::W,
                            kind: PieceKind::R,
                        },
                    );
                }
                (Color::B, 62) => {
                    self.remove_piece(
                        63,
                        Piece {
                            color: Color::B,
                            kind: PieceKind::R,
                        },
                    );
                    self.set_piece(
                        61,
                        Piece {
                            color: Color::B,
                            kind: PieceKind::R,
                        },
                    );
                }
                (Color::B, 58) => {
                    self.remove_piece(
                        56,
                        Piece {
                            color: Color::B,
                            kind: PieceKind::R,
                        },
                    );
                    self.set_piece(
                        59,
                        Piece {
                            color: Color::B,
                            kind: PieceKind::R,
                        },
                    );
                }
                _ => {}
            }
        }

        let placed = Piece {
            color: moved.color,
            kind: mv.promotion.map(promotion_kind).unwrap_or(moved.kind),
        };
        self.set_piece(mv.to, placed);

        self.update_castling_rights(mv, moved, captured);
        self.en_passant = if mv.flags & FLAG_DOUBLE_PAWN != 0 {
            Some(if moved.color == Color::W { mv.from + 8 } else { mv.from - 8 })
        } else {
            None
        };
        self.halfmove_clock = if moved.kind == PieceKind::P || captured.is_some() {
            0
        } else {
            self.halfmove_clock + 1
        };
        if moved.color == Color::B {
            self.fullmove_number += 1;
        }
        self.side_to_move = opposite(self.side_to_move);
        *self.repetition.entry(self.zobrist_hash()).or_insert(0) += 1;
    }

    pub fn unmake_move(&mut self) {
        let current_hash = self.zobrist_hash();
        if let Some(count) = self.repetition.get_mut(&current_hash) {
            *count = count.saturating_sub(1);
            if *count == 0 {
                self.repetition.remove(&current_hash);
            }
        }

        let undo = self.history.pop().expect("move history is not empty");
        let mv = undo.mv;
        self.side_to_move = undo.moved.color;
        self.castling = undo.castling;
        self.en_passant = undo.en_passant;
        self.halfmove_clock = undo.halfmove_clock;
        self.fullmove_number = undo.fullmove_number;

        if let Some(piece) = self.piece_at(mv.to) {
            self.remove_piece(mv.to, piece);
        }
        if mv.is_castle() {
            match (undo.moved.color, mv.to) {
                (Color::W, 6) => {
                    self.remove_piece(
                        5,
                        Piece {
                            color: Color::W,
                            kind: PieceKind::R,
                        },
                    );
                    self.set_piece(
                        7,
                        Piece {
                            color: Color::W,
                            kind: PieceKind::R,
                        },
                    );
                }
                (Color::W, 2) => {
                    self.remove_piece(
                        3,
                        Piece {
                            color: Color::W,
                            kind: PieceKind::R,
                        },
                    );
                    self.set_piece(
                        0,
                        Piece {
                            color: Color::W,
                            kind: PieceKind::R,
                        },
                    );
                }
                (Color::B, 62) => {
                    self.remove_piece(
                        61,
                        Piece {
                            color: Color::B,
                            kind: PieceKind::R,
                        },
                    );
                    self.set_piece(
                        63,
                        Piece {
                            color: Color::B,
                            kind: PieceKind::R,
                        },
                    );
                }
                (Color::B, 58) => {
                    self.remove_piece(
                        59,
                        Piece {
                            color: Color::B,
                            kind: PieceKind::R,
                        },
                    );
                    self.set_piece(
                        56,
                        Piece {
                            color: Color::B,
                            kind: PieceKind::R,
                        },
                    );
                }
                _ => {}
            }
        }
        self.set_piece(mv.from, undo.moved);
        if let Some(captured) = undo.captured {
            let captured_square = if mv.is_en_passant() {
                if undo.moved.color == Color::W {
                    mv.to - 8
                } else {
                    mv.to + 8
                }
            } else {
                mv.to
            };
            self.set_piece(captured_square, captured);
        }
    }

    fn update_castling_rights(&mut self, mv: ChessMove, moved: Piece, captured: Option<Piece>) {
        match (moved.color, moved.kind, mv.from) {
            (Color::W, PieceKind::K, _) => self.castling &= !(WHITE_KINGSIDE | WHITE_QUEENSIDE),
            (Color::B, PieceKind::K, _) => self.castling &= !(BLACK_KINGSIDE | BLACK_QUEENSIDE),
            (Color::W, PieceKind::R, 0) => self.castling &= !WHITE_QUEENSIDE,
            (Color::W, PieceKind::R, 7) => self.castling &= !WHITE_KINGSIDE,
            (Color::B, PieceKind::R, 56) => self.castling &= !BLACK_QUEENSIDE,
            (Color::B, PieceKind::R, 63) => self.castling &= !BLACK_KINGSIDE,
            _ => {}
        }
        if captured.is_some_and(|p| p.kind == PieceKind::R) {
            match mv.to {
                0 => self.castling &= !WHITE_QUEENSIDE,
                7 => self.castling &= !WHITE_KINGSIDE,
                56 => self.castling &= !BLACK_QUEENSIDE,
                63 => self.castling &= !BLACK_KINGSIDE,
                _ => {}
            }
        }
    }

    fn remove_piece(&mut self, sq: u8, piece: Piece) {
        self.bitboards[piece_index(piece)] &= !bit(sq);
    }

    fn set_piece(&mut self, sq: u8, piece: Piece) {
        self.bitboards[piece_index(piece)] |= bit(sq);
    }

    pub fn move_to_san(&self, mv: ChessMove) -> String {
        let mut work = self.clone();
        work.move_to_san_mut(mv)
    }

    fn move_to_san_mut(&mut self, mv: ChessMove) -> String {
        let piece = self.piece_at(mv.from).expect("SAN move has source piece");
        if mv.is_castle() {
            let mut san = if mv.to > mv.from { "O-O" } else { "O-O-O" }.to_string();
            self.make_move(mv);
            if self.is_in_check(self.side_to_move) {
                if self.legal_moves().is_empty() {
                    san.push('#');
                } else {
                    san.push('+');
                }
            }
            self.unmake_move();
            return san;
        }

        let mut san = String::new();
        if piece.kind != PieceKind::P {
            san.push(piece_letter(piece.kind));
            let ambiguous: Vec<_> = self
                .legal_moves()
                .into_iter()
                .filter(|other| {
                    other.to == mv.to
                        && other.from != mv.from
                        && self
                            .piece_at(other.from)
                            .is_some_and(|p| p.color == piece.color && p.kind == piece.kind)
                })
                .collect();
            if !ambiguous.is_empty() {
                let same_file = ambiguous.iter().any(|other| file_of(other.from) == file_of(mv.from));
                let same_rank = ambiguous.iter().any(|other| rank_of(other.from) == rank_of(mv.from));
                if !same_file {
                    san.push(file_char(mv.from));
                } else if !same_rank {
                    san.push(rank_char(mv.from));
                } else {
                    san.push(file_char(mv.from));
                    san.push(rank_char(mv.from));
                }
            }
        } else if mv.is_capture() {
            san.push(file_char(mv.from));
        }

        if mv.is_capture() {
            san.push('x');
        }
        san.push_str(&square_name(mv.to));
        if let Some(promotion) = mv.promotion {
            san.push('=');
            san.push(piece_letter(promotion_kind(promotion)));
        }

        self.make_move(mv);
        if self.is_in_check(self.side_to_move) {
            if self.legal_moves().is_empty() {
                san.push('#');
            } else {
                san.push('+');
            }
        }
        self.unmake_move();
        san
    }

    pub fn parse_san(&self, san: &str) -> Option<ChessMove> {
        let target = normalize_san(san);
        let mut work = self.clone();
        work.legal_moves()
            .into_iter()
            .find(|mv| normalize_san(&self.move_to_san(*mv)) == target)
    }

    pub fn parse_uci(&mut self, uci: &str) -> Option<ChessMove> {
        if uci.len() < 4 {
            return None;
        }
        let from = square_index(&uci[0..2])?;
        let to = square_index(&uci[2..4])?;
        let promotion = uci.as_bytes().get(4).and_then(|b| match b.to_ascii_lowercase() {
            b'n' => Some(Promotion::N),
            b'b' => Some(Promotion::B),
            b'r' => Some(Promotion::R),
            b'q' => Some(Promotion::Q),
            _ => None,
        });
        self.legal_moves()
            .into_iter()
            .find(|mv| mv.from == from && mv.to == to && mv.promotion == promotion)
    }

    pub fn captured_piece_for(&self, mv: ChessMove) -> Option<Piece> {
        if mv.is_en_passant() {
            let moved = self.piece_at(mv.from)?;
            let sq = if moved.color == Color::W { mv.to - 8 } else { mv.to + 8 };
            self.piece_at(sq)
        } else {
            self.piece_at(mv.to)
        }
    }

    pub fn reversible_ply_count(&self) -> usize {
        self.history.len()
    }

    pub fn perft(&mut self, depth: u32) -> u64 {
        if depth == 0 {
            return 1;
        }
        let moves = self.legal_moves();
        if depth == 1 {
            return moves.len() as u64;
        }
        let mut nodes = 0;
        for mv in moves {
            self.make_move(mv);
            nodes += self.perft(depth - 1);
            self.unmake_move();
        }
        nodes
    }

    pub fn game_status(&mut self) -> (GameStatus, GameResult) {
        if self.halfmove_clock >= 100 {
            return (GameStatus::DrawFiftyMove, GameResult::Draw);
        }
        if self.is_threefold_repetition() {
            return (GameStatus::DrawThreefold, GameResult::Draw);
        }
        if self.has_insufficient_material() {
            return (GameStatus::DrawInsufficient, GameResult::Draw);
        }
        if self.legal_moves().is_empty() {
            if self.is_in_check(self.side_to_move) {
                return (
                    GameStatus::Checkmate,
                    match self.side_to_move {
                        Color::W => GameResult::Black,
                        Color::B => GameResult::White,
                    },
                );
            }
            return (GameStatus::Stalemate, GameResult::Draw);
        }
        (GameStatus::Active, GameResult::Ongoing)
    }

    pub fn is_threefold_repetition(&self) -> bool {
        self.repetition
            .get(&self.zobrist_hash())
            .copied()
            .unwrap_or_default()
            >= 3
    }

    pub fn has_insufficient_material(&self) -> bool {
        let mut minors = Vec::new();
        for sq in 0u8..64 {
            let Some(piece) = self.piece_at(sq) else {
                continue;
            };
            match piece.kind {
                PieceKind::K => {}
                PieceKind::B | PieceKind::N => minors.push((piece, sq)),
                PieceKind::P | PieceKind::R | PieceKind::Q => return false,
            }
        }
        match minors.len() {
            0 | 1 => true,
            _ => minors
                .iter()
                .all(|(piece, _)| piece.kind == PieceKind::B)
                && minors
                    .iter()
                    .map(|(_, sq)| (file_of(*sq) + rank_of(*sq)) % 2)
                    .all(|color| color == (file_of(minors[0].1) + rank_of(minors[0].1)) % 2),
        }
    }

    pub fn zobrist_hash(&self) -> u64 {
        let mut h = 0u64;
        for idx in 0..12 {
            let mut bb = self.bitboards[idx];
            while bb != 0 {
                let sq = bb.trailing_zeros() as u8;
                h ^= splitmix64(0x9e3779b97f4a7c15 ^ ((idx as u64) << 8) ^ sq as u64);
                bb &= bb - 1;
            }
        }
        if self.side_to_move == Color::B {
            h ^= splitmix64(0xfeed_fade_dead_beef);
        }
        h ^= splitmix64(0x1234_5678_90ab_cdef ^ self.castling as u64);
        if let Some(ep) = self.en_passant {
            h ^= splitmix64(0xabcd_ef01_2345_6789 ^ file_of(ep) as u64);
        }
        h
    }
}

pub fn square_index(square: &str) -> Option<u8> {
    let bytes = square.as_bytes();
    if bytes.len() != 2 {
        return None;
    }
    let file = bytes[0].to_ascii_lowercase();
    let rank = bytes[1];
    if !(b'a'..=b'h').contains(&file) || !(b'1'..=b'8').contains(&rank) {
        return None;
    }
    Some((rank - b'1') * 8 + (file - b'a'))
}

pub fn square_name(sq: u8) -> String {
    format!("{}{}", file_char(sq), rank_char(sq))
}

pub fn opposite(color: Color) -> Color {
    match color {
        Color::W => Color::B,
        Color::B => Color::W,
    }
}

pub fn piece_value(kind: PieceKind) -> i32 {
    match kind {
        PieceKind::P => 100,
        PieceKind::N => 320,
        PieceKind::B => 330,
        PieceKind::R => 500,
        PieceKind::Q => 900,
        PieceKind::K => 0,
    }
}

fn normalize_san(san: &str) -> String {
    san.trim()
        .replace("0-0-0", "O-O-O")
        .replace("0-0", "O-O")
        .trim_end_matches(['+', '#', '!', '?'])
        .to_string()
}

fn bit(sq: u8) -> u64 {
    1u64 << sq
}

fn file_of(sq: u8) -> u8 {
    sq % 8
}

fn rank_of(sq: u8) -> u8 {
    sq / 8
}

fn file_char(sq: u8) -> char {
    (b'a' + file_of(sq)) as char
}

fn rank_char(sq: u8) -> char {
    (b'1' + rank_of(sq)) as char
}

fn offset_square(file: u8, rank: u8, df: i8, dr: i8) -> Option<u8> {
    let nf = file as i8 + df;
    let nr = rank as i8 + dr;
    if (0..8).contains(&nf) && (0..8).contains(&nr) {
        Some((nr * 8 + nf) as u8)
    } else {
        None
    }
}

fn piece_index(piece: Piece) -> usize {
    let color_offset = if piece.color == Color::W { 0 } else { 6 };
    color_offset
        + match piece.kind {
            PieceKind::P => 0,
            PieceKind::N => 1,
            PieceKind::B => 2,
            PieceKind::R => 3,
            PieceKind::Q => 4,
            PieceKind::K => 5,
        }
}

fn promotion_kind(promotion: Promotion) -> PieceKind {
    match promotion {
        Promotion::N => PieceKind::N,
        Promotion::B => PieceKind::B,
        Promotion::R => PieceKind::R,
        Promotion::Q => PieceKind::Q,
    }
}

fn piece_from_fen(ch: char) -> Option<Piece> {
    let color = if ch.is_ascii_uppercase() {
        Color::W
    } else {
        Color::B
    };
    let kind = match ch.to_ascii_lowercase() {
        'p' => PieceKind::P,
        'n' => PieceKind::N,
        'b' => PieceKind::B,
        'r' => PieceKind::R,
        'q' => PieceKind::Q,
        'k' => PieceKind::K,
        _ => return None,
    };
    Some(Piece { color, kind })
}

fn piece_to_fen(piece: Piece) -> char {
    let ch = match piece.kind {
        PieceKind::P => 'p',
        PieceKind::N => 'n',
        PieceKind::B => 'b',
        PieceKind::R => 'r',
        PieceKind::Q => 'q',
        PieceKind::K => 'k',
    };
    if piece.color == Color::W {
        ch.to_ascii_uppercase()
    } else {
        ch
    }
}

fn piece_letter(kind: PieceKind) -> char {
    match kind {
        PieceKind::N => 'N',
        PieceKind::B => 'B',
        PieceKind::R => 'R',
        PieceKind::Q => 'Q',
        PieceKind::K => 'K',
        PieceKind::P => unreachable!("pawns do not have SAN piece letters"),
    }
}

fn splitmix64(mut x: u64) -> u64 {
    x = x.wrapping_add(0x9e3779b97f4a7c15);
    let mut z = x;
    z = (z ^ (z >> 30)).wrapping_mul(0xbf58476d1ce4e5b9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94d049bb133111eb);
    z ^ (z >> 31)
}

const KNIGHT_DELTAS: [(i8, i8); 8] = [
    (1, 2),
    (2, 1),
    (2, -1),
    (1, -2),
    (-1, -2),
    (-2, -1),
    (-2, 1),
    (-1, 2),
];
const KING_DELTAS: [(i8, i8); 8] = [
    (1, 1),
    (1, 0),
    (1, -1),
    (0, -1),
    (-1, -1),
    (-1, 0),
    (-1, 1),
    (0, 1),
];
const BISHOP_DELTAS: [(i8, i8); 4] = [(1, 1), (1, -1), (-1, -1), (-1, 1)];
const ROOK_DELTAS: [(i8, i8); 4] = [(1, 0), (0, -1), (-1, 0), (0, 1)];
const QUEEN_DELTAS: [(i8, i8); 8] = [
    (1, 1),
    (1, -1),
    (-1, -1),
    (-1, 1),
    (1, 0),
    (0, -1),
    (-1, 0),
    (0, 1),
];

#[cfg(test)]
mod tests {
    use super::*;

    const KIWIPETE: &str =
        "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1";

    fn play_san(pos: &mut Position, san: &str) {
        let mv = pos.parse_san(san).unwrap_or_else(|| panic!("failed to parse SAN {san}"));
        let generated = pos.move_to_san(mv);
        assert_eq!(normalize_san(&generated), normalize_san(san));
        pos.make_move(mv);
    }

    #[test]
    fn perft_starting_position_depth_4() {
        let mut pos = Position::default();
        assert_eq!(pos.perft(4), 197_281);
    }

    #[test]
    fn perft_starting_position_depth_5() {
        let mut pos = Position::default();
        assert_eq!(pos.perft(5), 4_865_609);
    }

    #[test]
    fn perft_kiwipete_depth_3() {
        let mut pos = Position::from_fen(KIWIPETE).unwrap();
        assert_eq!(pos.perft(3), 97_862);
    }

    #[test]
    fn fen_roundtrip_positions() {
        for fen in [
            STARTING_FEN,
            KIWIPETE,
            "8/8/8/4k3/8/8/4K3/8 w - - 37 91",
        ] {
            assert_eq!(Position::from_fen(fen).unwrap().to_fen(), fen);
        }
    }

    #[test]
    fn san_roundtrip_morphy_opera_game_first_ten_moves() {
        let mut pos = Position::default();
        for san in [
            "e4", "e5", "Nf3", "d6", "d4", "Bg4", "dxe5", "Bxf3", "Qxf3", "dxe5", "Bc4",
            "Nf6", "Qb3", "Qe7", "Nc3", "c6", "Bg5", "b5", "Nxb5", "cxb5",
        ] {
            play_san(&mut pos, san);
        }
    }

    #[test]
    fn insufficient_material_detection() {
        for fen in [
            "8/8/8/8/8/8/4k3/4K3 w - - 0 1",
            "8/8/8/8/8/8/4k3/3NK3 w - - 0 1",
            "8/8/8/8/8/8/4k3/3BK3 w - - 0 1",
            "8/8/8/8/8/2b5/4k3/2B1K3 w - - 0 1",
        ] {
            assert!(Position::from_fen(fen).unwrap().has_insufficient_material(), "{fen}");
        }
        assert!(!Position::from_fen("8/8/8/8/8/8/4k3/2BNK3 w - - 0 1")
            .unwrap()
            .has_insufficient_material());
    }

    #[test]
    fn threefold_repetition_detection() {
        let mut pos = Position::default();
        for san in ["Nf3", "Nf6", "Ng1", "Ng8", "Nf3", "Nf6", "Ng1", "Ng8"] {
            let mv = pos.parse_san(san).unwrap();
            pos.make_move(mv);
        }
        assert!(pos.is_threefold_repetition());
    }

    #[test]
    fn stalemate_vs_checkmate_distinction() {
        let mut stalemate = Position::from_fen("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1").unwrap();
        assert_eq!(stalemate.game_status(), (GameStatus::Stalemate, GameResult::Draw));

        let mut mate = Position::from_fen("7k/6Q1/6K1/8/8/8/8/8 b - - 0 1").unwrap();
        assert_eq!(mate.game_status(), (GameStatus::Checkmate, GameResult::White));
    }
}
