//! Smoke test confirming `chess_lib` re-exports the platform-agnostic
//! core. The exhaustive scenarios live in
//! `crates/chess_core/tests/integration.rs`.

use chess_lib::api::{GameMode, GameStatus, HumanColorChoice, NewGameOpts};
use chess_lib::session::SessionManager;

#[test]
fn chess_lib_reexports_chess_core() {
    let session = SessionManager::new();
    let snap = session
        .create_game(
            "smoke".into(),
            NewGameOpts {
                mode: GameMode::Hvh,
                ai_difficulty: None,
                human_color: Some(HumanColorChoice::W),
                time_control: None,
            },
        )
        .expect("create_game");
    assert_eq!(snap.status, GameStatus::Active);
    assert_eq!(snap.history.len(), 0);
}
