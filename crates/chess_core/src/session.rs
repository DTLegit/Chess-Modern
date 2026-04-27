//! In-memory session registry plus lightweight persistence for the current game.

use std::{
    collections::{HashMap, HashSet},
    fs,
    path::PathBuf,
    sync::Arc,
};

use parking_lot::RwLock;
use serde::{Deserialize, Serialize};

use crate::{
    api::{
        ApiError, ApiResult, BackendEvent, ClockTickEvent, Color, GameId, GameMode, GameOverEvent,
        GameResult, GameSnapshot, GameStatus, HumanColorChoice, Move, NewGameOpts, Settings,
    },
    clock::{ChessClock, PersistedClock},
    engine::{opposite, Position, STARTING_FEN},
    platform::{ArcDirs, ArcSink, ArcSpawner, EphemeralAppDirs, NoStockfishSpawner, NullEventSink},
};

#[derive(Clone)]
pub struct SessionManager {
    inner: Arc<SessionInner>,
}

struct SessionInner {
    games: RwLock<HashMap<GameId, GameSession>>,
    settings: RwLock<Settings>,
    dirs: ArcDirs,
    sink: ArcSink,
    spawner: ArcSpawner,
    clock_tasks: RwLock<HashSet<GameId>>,
}

#[derive(Debug, Clone)]
pub struct GameSession {
    pub id: GameId,
    pub position: Position,
    pub history: Vec<Move>,
    pub clock: Option<ChessClock>,
    pub mode: GameMode,
    pub ai_difficulty: Option<u8>,
    pub human_color: Option<Color>,
    pub last_move: Option<Move>,
    pub status: GameStatus,
    pub result: GameResult,
}

#[derive(Debug, Serialize, Deserialize)]
struct PersistedGame {
    id: GameId,
    fen: String,
    history: Vec<Move>,
    clock: Option<PersistedClock>,
    mode: GameMode,
    ai_difficulty: Option<u8>,
    human_color: Option<Color>,
    last_move: Option<Move>,
    status: GameStatus,
    result: GameResult,
}

impl Default for SessionManager {
    fn default() -> Self {
        Self::new()
    }
}

impl SessionManager {
    /// Create a session with no persistence, no event sink, and no
    /// Stockfish spawner. Suitable for unit tests; the legacy integration
    /// test suite still relies on this.
    pub fn new() -> Self {
        Self::builder().build()
    }

    pub fn builder() -> SessionManagerBuilder {
        SessionManagerBuilder::default()
    }

    pub fn dirs(&self) -> ArcDirs {
        self.inner.dirs.clone()
    }

    pub fn sink(&self) -> ArcSink {
        self.inner.sink.clone()
    }

    pub fn spawner(&self) -> ArcSpawner {
        self.inner.spawner.clone()
    }

    /// Load any previously persisted settings + last-game from disk.
    /// Idempotent; safe to call once at app startup.
    pub fn hydrate(&self) {
        self.load_settings();
        self.load_last_game();
    }

    pub fn clone_handle(&self) -> Self {
        self.clone()
    }

    pub fn create_game(&self, id: GameId, opts: NewGameOpts) -> ApiResult<GameSnapshot> {
        let human_color = match opts.human_color {
            Some(HumanColorChoice::B) => Some(Color::B),
            Some(HumanColorChoice::Random) => {
                if rand::random::<bool>() {
                    Some(Color::W)
                } else {
                    Some(Color::B)
                }
            }
            Some(HumanColorChoice::W) | None => Some(Color::W),
        };
        let mut game = GameSession {
            id: id.clone(),
            position: Position::default(),
            history: Vec::new(),
            clock: opts.time_control.map(ChessClock::new),
            mode: opts.mode,
            ai_difficulty: opts.ai_difficulty,
            human_color,
            last_move: None,
            status: GameStatus::Active,
            result: GameResult::Ongoing,
        };
        let snapshot = game.snapshot();
        self.inner.games.write().insert(id.clone(), game);
        self.persist_game(&id);
        self.start_clock_task(id);
        Ok(snapshot)
    }

    pub fn insert(&self, id: GameId, snap: GameSnapshot) {
        let position = Position::from_fen(&snap.fen).unwrap_or_else(|_| Position::default());
        let game = GameSession {
            id: id.clone(),
            position,
            history: snap.history.clone(),
            clock: snap.clock.map(|state| {
                ChessClock::from_persisted(PersistedClock {
                    white_ms: state.white_ms,
                    black_ms: state.black_ms,
                    increment_ms: 0,
                    active: state.active,
                    paused: state.paused,
                })
            }),
            mode: snap.mode,
            ai_difficulty: snap.ai_difficulty,
            human_color: snap.human_color,
            last_move: snap.last_move.clone(),
            status: snap.status,
            result: snap.result,
        };
        self.inner.games.write().insert(id, game);
    }

    pub fn get(&self, id: &str) -> Option<GameSnapshot> {
        let mut games = self.inner.games.write();
        games.get_mut(id).map(GameSession::snapshot)
    }

    pub fn game(&self, id: &str) -> Option<GameSession> {
        self.inner.games.read().get(id).cloned()
    }

    pub fn with_game_mut<R>(
        &self,
        id: &str,
        f: impl FnOnce(&mut GameSession) -> ApiResult<R>,
    ) -> ApiResult<R> {
        let result = {
            let mut games = self.inner.games.write();
            let game = games
                .get_mut(id)
                .ok_or_else(|| ApiError::GameNotFound(id.to_string()))?;
            f(game)?
        };
        self.persist_game(id);
        Ok(result)
    }

    pub fn get_settings(&self) -> Settings {
        self.inner.settings.read().clone()
    }

    pub fn set_settings(&self, mut s: Settings) {
        // Merida is the only supported piece style in the UI; keep persisted value consistent.
        s.piece_set = crate::api::PieceSet::Merida;
        *self.inner.settings.write() = s;
        self.persist_settings();
    }

    /// Push an event through the configured sink. The legacy Tauri shell
    /// turns this back into `app.emit(name, payload)`; the Flutter bridge
    /// forwards it to a `flutter_rust_bridge::StreamSink`.
    pub fn emit(&self, event: BackendEvent) {
        self.inner.sink.emit(event);
    }

    pub fn start_clock_task(&self, game_id: GameId) {
        let has_clock = self
            .inner
            .games
            .read()
            .get(&game_id)
            .is_some_and(|g| g.clock.is_some());
        if !has_clock {
            return;
        }
        if tokio::runtime::Handle::try_current().is_err() {
            log::debug!("no tokio runtime; skipping clock task for game {game_id}");
            return;
        }
        if self.inner.clock_tasks.write().insert(game_id.clone()) {
            let manager = self.clone();
            tokio::spawn(async move {
                loop {
                    tokio::time::sleep(std::time::Duration::from_millis(250)).await;
                    let (tick, over) = {
                        let mut games = manager.inner.games.write();
                        let Some(game) = games.get_mut(&game_id) else {
                            manager.inner.clock_tasks.write().remove(&game_id);
                            break;
                        };
                        if game.status != GameStatus::Active {
                            manager.inner.clock_tasks.write().remove(&game_id);
                            break;
                        }
                        let Some(clock) = game.clock.as_mut() else {
                            manager.inner.clock_tasks.write().remove(&game_id);
                            break;
                        };
                        let flagged = clock.flag();
                        let state = clock.state();
                        let tick = ClockTickEvent {
                            game_id: game_id.clone(),
                            white_ms: state.white_ms,
                            black_ms: state.black_ms,
                            active: state.active,
                        };
                        let over = flagged.map(|flagged_color| {
                            game.status = GameStatus::TimeForfeit;
                            game.result = match opposite(flagged_color) {
                                Color::W => GameResult::White,
                                Color::B => GameResult::Black,
                            };
                            GameOverEvent {
                                game_id: game_id.clone(),
                                result: game.result,
                                reason: game.status,
                            }
                        });
                        (tick, over)
                    };
                    manager.persist_game(&game_id);
                    manager.emit(BackendEvent::ClockTick(tick));
                    if let Some(over) = over {
                        manager.emit(BackendEvent::GameOver(over));
                        manager.inner.clock_tasks.write().remove(&game_id);
                        break;
                    }
                }
            });
        }
    }

    fn load_settings(&self) {
        let Some(path) = self.settings_path() else {
            return;
        };
        let Ok(bytes) = fs::read(path) else {
            return;
        };
        if let Ok(mut settings) = serde_json::from_slice::<Settings>(&bytes) {
            settings.piece_set = crate::api::PieceSet::Merida;
            *self.inner.settings.write() = settings;
        }
    }

    fn persist_settings(&self) {
        let Some(path) = self.settings_path() else {
            return;
        };
        if let Some(parent) = path.parent() {
            let _ = fs::create_dir_all(parent);
        }
        if let Ok(json) = serde_json::to_vec_pretty(&*self.inner.settings.read()) {
            let _ = fs::write(path, json);
        }
    }

    fn load_last_game(&self) {
        let Some(path) = self.last_game_path() else {
            return;
        };
        let Ok(bytes) = fs::read(path) else {
            return;
        };
        let Ok(persisted) = serde_json::from_slice::<PersistedGame>(&bytes) else {
            return;
        };
        let Ok(position) = Position::from_fen(&persisted.fen) else {
            return;
        };
        let game = GameSession {
            id: persisted.id.clone(),
            position,
            history: persisted.history,
            clock: persisted.clock.map(ChessClock::from_persisted),
            mode: persisted.mode,
            ai_difficulty: persisted.ai_difficulty,
            human_color: persisted.human_color,
            last_move: persisted.last_move,
            status: persisted.status,
            result: persisted.result,
        };
        self.inner.games.write().insert(persisted.id.clone(), game);
        self.start_clock_task(persisted.id);
    }

    fn persist_game(&self, id: &str) {
        let Some(path) = self.last_game_path() else {
            return;
        };
        let Some(game) = self.inner.games.read().get(id).cloned() else {
            return;
        };
        if let Some(parent) = path.parent() {
            let _ = fs::create_dir_all(parent);
        }
        let persisted = PersistedGame {
            id: game.id,
            fen: game.position.to_fen(),
            history: game.history,
            clock: game.clock.map(|clock| clock.persisted()),
            mode: game.mode,
            ai_difficulty: game.ai_difficulty,
            human_color: game.human_color,
            last_move: game.last_move,
            status: game.status,
            result: game.result,
        };
        if let Ok(json) = serde_json::to_vec_pretty(&persisted) {
            let _ = fs::write(path, json);
        }
    }

    fn settings_path(&self) -> Option<PathBuf> {
        Some(self.data_dir()?.join("settings.json"))
    }

    fn last_game_path(&self) -> Option<PathBuf> {
        Some(self.data_dir()?.join("last-game.json"))
    }

    fn data_dir(&self) -> Option<PathBuf> {
        self.inner.dirs.data_dir().map(|root| root.join("chess"))
    }
}

#[derive(Default)]
pub struct SessionManagerBuilder {
    dirs: Option<ArcDirs>,
    sink: Option<ArcSink>,
    spawner: Option<ArcSpawner>,
}

impl SessionManagerBuilder {
    pub fn dirs(mut self, dirs: ArcDirs) -> Self {
        self.dirs = Some(dirs);
        self
    }

    pub fn sink(mut self, sink: ArcSink) -> Self {
        self.sink = Some(sink);
        self
    }

    pub fn spawner(mut self, spawner: ArcSpawner) -> Self {
        self.spawner = Some(spawner);
        self
    }

    pub fn build(self) -> SessionManager {
        let dirs = self
            .dirs
            .unwrap_or_else(|| Arc::new(EphemeralAppDirs) as ArcDirs);
        let sink = self
            .sink
            .unwrap_or_else(|| Arc::new(NullEventSink) as ArcSink);
        let spawner = self
            .spawner
            .unwrap_or_else(|| Arc::new(NoStockfishSpawner) as ArcSpawner);
        SessionManager {
            inner: Arc::new(SessionInner {
                games: RwLock::new(HashMap::new()),
                settings: RwLock::new(Settings::default()),
                dirs,
                sink,
                spawner,
                clock_tasks: RwLock::new(HashSet::new()),
            }),
        }
    }
}

impl GameSession {
    pub fn from_loaded_game(id: GameId, position: Position, history: Vec<Move>) -> Self {
        let mut game = Self {
            id,
            position,
            history,
            clock: None,
            mode: GameMode::Hvh,
            ai_difficulty: None,
            human_color: Some(Color::W),
            last_move: None,
            status: GameStatus::Active,
            result: GameResult::Ongoing,
        };
        game.last_move = game.history.last().cloned();
        let (status, result) = game.position.game_status();
        game.status = status;
        game.result = result;
        game
    }

    pub fn snapshot(&mut self) -> GameSnapshot {
        let (status, result) = if self.status == GameStatus::Active {
            self.position.game_status()
        } else {
            (self.status, self.result)
        };
        self.status = status;
        self.result = result;
        GameSnapshot {
            game_id: self.id.clone(),
            fen: self.position.to_fen(),
            turn: self.position.side_to_move,
            in_check: self.position.is_in_check(self.position.side_to_move),
            status,
            result,
            history: self.history.clone(),
            legal_moves: if status == GameStatus::Active {
                self.position.legal_moves_map()
            } else {
                HashMap::new()
            },
            clock: self.clock.as_ref().map(ChessClock::state),
            mode: self.mode,
            ai_difficulty: self.ai_difficulty,
            human_color: self.human_color,
            last_move: self.last_move.clone(),
        }
    }
}

pub fn default_snapshot(id: GameId) -> GameSnapshot {
    let mut game = GameSession::from_loaded_game(id, Position::from_fen(STARTING_FEN).unwrap(), vec![]);
    game.snapshot()
}
