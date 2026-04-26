//! Per-game chess clock.

use std::time::Instant;

use serde::{Deserialize, Serialize};

use crate::api::{ClockState, Color, TimeControl};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PersistedClock {
    pub white_ms: u64,
    pub black_ms: u64,
    pub increment_ms: u64,
    pub active: Option<Color>,
    pub paused: bool,
}

#[derive(Debug, Clone)]
pub struct ChessClock {
    white_ms: u64,
    black_ms: u64,
    increment_ms: u64,
    active: Option<Color>,
    paused: bool,
    last_tick: Option<Instant>,
}

impl ChessClock {
    pub fn new(tc: TimeControl) -> Self {
        Self {
            white_ms: tc.initial_ms,
            black_ms: tc.initial_ms,
            increment_ms: tc.increment_ms,
            active: Some(Color::W),
            paused: false,
            last_tick: Some(Instant::now()),
        }
    }

    pub fn from_persisted(persisted: PersistedClock) -> Self {
        Self {
            white_ms: persisted.white_ms,
            black_ms: persisted.black_ms,
            increment_ms: persisted.increment_ms,
            active: persisted.active,
            paused: persisted.paused,
            last_tick: persisted.active.map(|_| Instant::now()),
        }
    }

    pub fn persisted(&self) -> PersistedClock {
        let mut cloned = self.clone();
        cloned.tick();
        PersistedClock {
            white_ms: cloned.white_ms,
            black_ms: cloned.black_ms,
            increment_ms: cloned.increment_ms,
            active: cloned.active,
            paused: cloned.paused,
        }
    }

    pub fn state(&self) -> ClockState {
        let mut cloned = self.clone();
        cloned.tick();
        ClockState {
            white_ms: cloned.white_ms,
            black_ms: cloned.black_ms,
            active: cloned.active,
            paused: cloned.paused,
        }
    }

    pub fn start(&mut self, color: Color) {
        self.tick();
        self.active = Some(color);
        self.paused = false;
        self.last_tick = Some(Instant::now());
    }

    pub fn pause(&mut self) {
        self.tick();
        self.paused = true;
        self.last_tick = None;
    }

    pub fn resume(&mut self) {
        if self.active.is_some() {
            self.paused = false;
            self.last_tick = Some(Instant::now());
        }
    }

    pub fn switch_after_move(&mut self, moved: Color, next: Color) {
        self.tick();
        match moved {
            Color::W => self.white_ms = self.white_ms.saturating_add(self.increment_ms),
            Color::B => self.black_ms = self.black_ms.saturating_add(self.increment_ms),
        }
        self.active = Some(next);
        self.last_tick = Some(Instant::now());
    }

    pub fn tick(&mut self) {
        if self.paused {
            self.last_tick = None;
            return;
        }
        let Some(active) = self.active else {
            self.last_tick = None;
            return;
        };
        let now = Instant::now();
        let Some(last_tick) = self.last_tick.replace(now) else {
            return;
        };
        let elapsed = now.saturating_duration_since(last_tick).as_millis() as u64;
        match active {
            Color::W => self.white_ms = self.white_ms.saturating_sub(elapsed),
            Color::B => self.black_ms = self.black_ms.saturating_sub(elapsed),
        }
    }

    pub fn flag(&mut self) -> Option<Color> {
        self.tick();
        if self.white_ms == 0 {
            Some(Color::W)
        } else if self.black_ms == 0 {
            Some(Color::B)
        } else {
            None
        }
    }
}
