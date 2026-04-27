//! Platform-agnostic command surface.
//!
//! Both the Tauri shell and the Flutter bridge call these functions; they
//! wrap `SessionManager` orchestration plus event emission and exactly
//! match the behaviour of the original `#[tauri::command]` set in
//! `legacy/tauri/src/commands.rs`.

use crate::{
    ai,
    api::*,
    clock::ChessClock,
    engine::{square_index, square_name, ChessMove},
    pgn,
    session::{GameSession, SessionManager},
};

// ---------------------------------------------------------------------------
// Helpers (re-exported for the integration test suite)
// ---------------------------------------------------------------------------

pub fn api_move_from_engine(game: &GameSession, mv: ChessMove) -> Move {
    let san = game.position.move_to_san(mv);
    let mut after = game.position.clone();
    after.make_move(mv);
    let is_check = after.is_in_check(after.side_to_move);
    let is_mate = is_check && after.legal_moves().is_empty();
    Move {
        from: square_name(mv.from),
        to: square_name(mv.to),
        promotion: mv.promotion,
        san,
        uci: mv.uci(),
        captured: game.position.captured_piece_for(mv),
        is_check,
        is_mate,
        is_castle: mv.is_castle(),
        is_en_passant: mv.is_en_passant(),
    }
}

pub fn find_legal_move(
    game: &mut GameSession,
    from: &str,
    to: &str,
    promotion: Option<Promotion>,
) -> ApiResult<ChessMove> {
    let from_idx = square_index(from).ok_or_else(|| ApiError::InvalidInput(from.into()))?;
    let to_idx = square_index(to).ok_or_else(|| ApiError::InvalidInput(to.into()))?;
    game.position
        .legal_moves()
        .into_iter()
        .find(|mv| mv.from == from_idx && mv.to == to_idx && mv.promotion == promotion)
        .ok_or_else(|| ApiError::IllegalMove(format!("{from}->{to}")))
}

pub fn apply_engine_move(
    session: &SessionManager,
    game_id: &str,
    mv: ChessMove,
) -> ApiResult<MoveResult> {
    let result = session.with_game_mut(game_id, |game| {
        if game.status != GameStatus::Active {
            return Err(ApiError::IllegalMove("game is not active".into()));
        }
        let moving_color = game.position.side_to_move;
        let api_mv = api_move_from_engine(game, mv);
        game.position.make_move(mv);
        if let Some(clock) = game.clock.as_mut() {
            clock.switch_after_move(moving_color, game.position.side_to_move);
            if let Some(flagged) = clock.flag() {
                game.status = GameStatus::TimeForfeit;
                game.result = match flagged {
                    Color::W => GameResult::Black,
                    Color::B => GameResult::White,
                };
            }
        }
        game.history.push(api_mv.clone());
        game.last_move = Some(api_mv.clone());
        if game.status == GameStatus::Active {
            let (status, result) = game.position.game_status();
            game.status = status;
            game.result = result;
        }
        let snapshot = game.snapshot();
        Ok(MoveResult { mv: api_mv, snapshot })
    })?;

    session.emit(BackendEvent::MoveMade(MoveMadeEvent {
        game_id: game_id.to_string(),
        mv: result.mv.clone(),
        snapshot: result.snapshot.clone(),
    }));
    if result.snapshot.status != GameStatus::Active {
        session.emit(BackendEvent::GameOver(GameOverEvent {
            game_id: game_id.to_string(),
            result: result.snapshot.result,
            reason: result.snapshot.status,
        }));
    }
    Ok(result)
}

// ---------------------------------------------------------------------------
// Commands (one entry point per legacy `#[tauri::command]`)
// ---------------------------------------------------------------------------

pub async fn new_game(session: &SessionManager, opts: NewGameOpts) -> ApiResult<GameSnapshot> {
    let id = uuid::Uuid::new_v4().to_string();
    session.create_game(id, opts)
}

pub async fn legal_moves_from(
    session: &SessionManager,
    game_id: GameId,
    square: SquareStr,
) -> ApiResult<Vec<SquareStr>> {
    let snap = session
        .get(&game_id)
        .ok_or_else(|| ApiError::GameNotFound(game_id.clone()))?;
    Ok(snap.legal_moves.get(&square).cloned().unwrap_or_default())
}

pub async fn make_move(
    session: &SessionManager,
    game_id: GameId,
    from: SquareStr,
    to: SquareStr,
    promotion: Option<Promotion>,
) -> ApiResult<MoveResult> {
    let mv = session.with_game_mut(&game_id, |game| find_legal_move(game, &from, &to, promotion))?;
    apply_engine_move(session, &game_id, mv)
}

pub async fn request_ai_move(session: &SessionManager, game_id: GameId) -> ApiResult<()> {
    let game = session
        .game(&game_id)
        .ok_or_else(|| ApiError::GameNotFound(game_id.clone()))?;
    if game.status != GameStatus::Active {
        return Err(ApiError::IllegalMove("game is not active".into()));
    }
    let difficulty = game.ai_difficulty.unwrap_or(3).clamp(1, 10);
    let position = game.position.clone();
    let history_uci = game.history.iter().map(|mv| mv.uci.clone()).collect::<Vec<_>>();
    let manager = session.clone_handle();
    let spawner = manager.spawner();
    tokio::spawn(async move {
        let progress_manager = manager.clone();
        let result = ai::choose_move(
            spawner.as_ref(),
            &game_id,
            position,
            history_uci,
            difficulty,
            move |event| {
                progress_manager.emit(BackendEvent::AiProgress(event));
            },
        )
        .await;
        match result {
            Ok(Some(output)) => {
                let _ = apply_engine_move(&manager, &game_id, output.mv);
            }
            Ok(None) => log::warn!("AI found no legal move for game {game_id}"),
            Err(err) => log::warn!("AI move failed for game {game_id}: {err}"),
        }
    });
    Ok(())
}

pub async fn undo_move(session: &SessionManager, game_id: GameId) -> ApiResult<GameSnapshot> {
    session.with_game_mut(&game_id, |game| {
        let mut count = if game.mode == GameMode::Hva
            && game.human_color == Some(game.position.side_to_move)
            && game.history.len() >= 2
        {
            2
        } else {
            1
        };
        count = count.min(game.position.reversible_ply_count()).min(game.history.len());
        if count == 0 {
            return Err(ApiError::InvalidInput("no move to undo".into()));
        }
        for _ in 0..count {
            game.position.unmake_move();
            game.history.pop();
        }
        game.last_move = game.history.last().cloned();
        game.status = GameStatus::Active;
        game.result = GameResult::Ongoing;
        Ok(game.snapshot())
    })
}

pub async fn resign(session: &SessionManager, game_id: GameId) -> ApiResult<GameSnapshot> {
    let snapshot = session.with_game_mut(&game_id, |game| {
        game.status = GameStatus::Resigned;
        game.result = match game.position.side_to_move {
            Color::W => GameResult::Black,
            Color::B => GameResult::White,
        };
        Ok(game.snapshot())
    })?;
    session.emit(BackendEvent::GameOver(GameOverEvent {
        game_id,
        result: snapshot.result,
        reason: snapshot.status,
    }));
    Ok(snapshot)
}

pub async fn offer_draw(session: &SessionManager, game_id: GameId) -> ApiResult<GameSnapshot> {
    session.with_game_mut(&game_id, |game| {
        game.status = GameStatus::DrawAgreement;
        game.result = GameResult::Draw;
        Ok(game.snapshot())
    })
}

pub async fn claim_draw(session: &SessionManager, game_id: GameId) -> ApiResult<GameSnapshot> {
    session.with_game_mut(&game_id, |game| {
        let (status, result) = game.position.game_status();
        if matches!(
            status,
            GameStatus::DrawFiftyMove | GameStatus::DrawThreefold | GameStatus::DrawInsufficient
        ) {
            game.status = status;
            game.result = result;
            Ok(game.snapshot())
        } else {
            Err(ApiError::IllegalMove("no drawable claim is available".into()))
        }
    })
}

pub async fn load_pgn(session: &SessionManager, pgn_text: String) -> ApiResult<GameSnapshot> {
    let parsed = pgn::parse(&pgn_text)?;
    let id = uuid::Uuid::new_v4().to_string();
    let mut game = GameSession::from_loaded_game(id.clone(), parsed.position, parsed.history);
    game.result = parsed.result;
    if parsed.result != GameResult::Ongoing {
        game.status = GameStatus::DrawAgreement;
    }
    let snapshot = game.snapshot();
    session.insert(id, snapshot.clone());
    session.with_game_mut(&snapshot.game_id, |stored| {
        *stored = game;
        Ok(())
    })?;
    Ok(snapshot)
}

pub async fn export_pgn(session: &SessionManager, game_id: GameId) -> ApiResult<String> {
    let game = session
        .game(&game_id)
        .ok_or_else(|| ApiError::GameNotFound(game_id.clone()))?;
    Ok(pgn::serialize(&game.history, game.result, None, None))
}

pub async fn set_clock(
    session: &SessionManager,
    game_id: GameId,
    time_control: TimeControl,
) -> ApiResult<GameSnapshot> {
    let snapshot = session.with_game_mut(&game_id, |game| {
        game.clock = Some(ChessClock::new(time_control));
        Ok(game.snapshot())
    })?;
    session.start_clock_task(game_id);
    Ok(snapshot)
}

pub async fn pause_clock(session: &SessionManager, game_id: GameId) -> ApiResult<GameSnapshot> {
    session.with_game_mut(&game_id, |game| {
        let clock = game
            .clock
            .as_mut()
            .ok_or_else(|| ApiError::InvalidInput("game has no clock".into()))?;
        clock.pause();
        Ok(game.snapshot())
    })
}

pub async fn resume_clock(session: &SessionManager, game_id: GameId) -> ApiResult<GameSnapshot> {
    let snapshot = session.with_game_mut(&game_id, |game| {
        let clock = game
            .clock
            .as_mut()
            .ok_or_else(|| ApiError::InvalidInput("game has no clock".into()))?;
        clock.resume();
        Ok(game.snapshot())
    })?;
    session.start_clock_task(game_id);
    Ok(snapshot)
}

pub async fn get_settings(session: &SessionManager) -> ApiResult<Settings> {
    Ok(session.get_settings())
}

pub async fn set_settings(session: &SessionManager, settings: Settings) -> ApiResult<Settings> {
    session.set_settings(settings.clone());
    Ok(settings)
}
