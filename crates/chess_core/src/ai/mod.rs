//! Hybrid AI controller.

pub mod custom;
pub(crate) mod difficulty;
pub mod stockfish;

use crate::{
    ai::custom::SearchOutput,
    ai::difficulty::profile_for,
    api::{AiProgressEvent, ApiResult},
    engine::Position,
    platform::StockfishSpawner,
};

/// Pick a move using whichever engine the difficulty profile says, with a
/// transparent fallback to the custom Rust engine whenever Stockfish is
/// unavailable on this platform (iOS, missing sidecar, no spawner, ...).
pub async fn choose_move(
    spawner: &dyn StockfishSpawner,
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
        stockfish::choose_move(spawner, game_id, &position, &history_uci, difficulty, progress)
            .await
    }
}
