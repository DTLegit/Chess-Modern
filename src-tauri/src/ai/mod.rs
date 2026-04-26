//! Hybrid AI controller.

pub mod custom;
pub(crate) mod difficulty;
pub mod stockfish;

use tauri::AppHandle;

use crate::{
    ai::custom::SearchOutput,
    ai::difficulty::profile_for,
    api::{AiProgressEvent, ApiResult},
    engine::Position,
};

pub async fn choose_move(
    app: Option<AppHandle>,
    game_id: &str,
    position: Position,
    history_uci: Vec<String>,
    difficulty: u8,
    progress: impl FnMut(AiProgressEvent) + Send + 'static,
) -> ApiResult<Option<SearchOutput>> {
    if !profile_for(difficulty).uses_stockfish() {
        Ok(custom::choose_move(
            game_id, &position, difficulty, progress,
        ))
    } else {
        stockfish::choose_move(app, game_id, &position, &history_uci, difficulty, progress).await
    }
}
