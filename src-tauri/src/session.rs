//! Phase 0 stub session manager. The backend subagent replaces this with a
//! real implementation that owns engine `Position`s, manages clocks, persists
//! the active game to disk, etc. The public API (methods on `SessionManager`)
//! is intentionally minimal so the swap is mechanical.

use std::collections::HashMap;

use parking_lot::RwLock;

use crate::api::{GameId, GameSnapshot, Settings};

#[derive(Default)]
pub struct SessionManager {
    games: RwLock<HashMap<GameId, GameSnapshot>>,
    settings: RwLock<Settings>,
}

impl SessionManager {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn insert(&self, id: GameId, snap: GameSnapshot) {
        self.games.write().insert(id, snap);
    }

    pub fn get(&self, id: &str) -> Option<GameSnapshot> {
        self.games.read().get(id).cloned()
    }

    pub fn get_settings(&self) -> Settings {
        self.settings.read().clone()
    }

    pub fn set_settings(&self, s: Settings) {
        *self.settings.write() = s;
    }
}
