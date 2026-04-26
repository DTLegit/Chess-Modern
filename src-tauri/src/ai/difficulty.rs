//! Central difficulty calibration for local and Stockfish-backed AI.

#[derive(Debug, Clone, Copy)]
pub(crate) struct DifficultyProfile {
    pub custom_depth: u32,
    pub custom_noise: f64,
    pub stockfish_skill: Option<u8>,
    pub stockfish_depth: Option<u32>,
    pub fallback_custom_level: u8,
}

impl DifficultyProfile {
    pub(crate) fn uses_stockfish(self) -> bool {
        self.stockfish_skill.is_some() && self.stockfish_depth.is_some()
    }

    pub(crate) fn stockfish_settings(self) -> Option<(u8, u32)> {
        Some((self.stockfish_skill?, self.stockfish_depth?))
    }
}

pub(crate) fn profile_for(difficulty: u8) -> DifficultyProfile {
    match difficulty.clamp(1, 10) {
        1 => DifficultyProfile {
            custom_depth: 1,
            custom_noise: 0.45,
            stockfish_skill: None,
            stockfish_depth: None,
            fallback_custom_level: 1,
        },
        2 => DifficultyProfile {
            custom_depth: 2,
            custom_noise: 0.30,
            stockfish_skill: None,
            stockfish_depth: None,
            fallback_custom_level: 2,
        },
        3 => DifficultyProfile {
            custom_depth: 3,
            custom_noise: 0.12,
            stockfish_skill: None,
            stockfish_depth: None,
            fallback_custom_level: 3,
        },
        4 => DifficultyProfile {
            custom_depth: 4,
            custom_noise: 0.03,
            stockfish_skill: None,
            stockfish_depth: None,
            fallback_custom_level: 4,
        },
        5 => DifficultyProfile {
            custom_depth: 4,
            custom_noise: 0.02,
            stockfish_skill: Some(4),
            stockfish_depth: Some(6),
            fallback_custom_level: 4,
        },
        6 => DifficultyProfile {
            custom_depth: 4,
            custom_noise: 0.01,
            stockfish_skill: Some(8),
            stockfish_depth: Some(8),
            fallback_custom_level: 4,
        },
        7 => DifficultyProfile {
            custom_depth: 4,
            custom_noise: 0.0,
            stockfish_skill: Some(12),
            stockfish_depth: Some(10),
            fallback_custom_level: 4,
        },
        8 => DifficultyProfile {
            custom_depth: 4,
            custom_noise: 0.0,
            stockfish_skill: Some(15),
            stockfish_depth: Some(13),
            fallback_custom_level: 4,
        },
        9 => DifficultyProfile {
            custom_depth: 4,
            custom_noise: 0.0,
            stockfish_skill: Some(18),
            stockfish_depth: Some(17),
            fallback_custom_level: 4,
        },
        10 => DifficultyProfile {
            custom_depth: 4,
            custom_noise: 0.0,
            stockfish_skill: Some(20),
            stockfish_depth: Some(22),
            fallback_custom_level: 4,
        },
        _ => unreachable!("difficulty is clamped to 1..=10"),
    }
}

#[cfg(test)]
mod tests {
    use super::profile_for;

    #[test]
    fn profiles_are_bounded_for_all_public_levels() {
        for difficulty in 1..=10 {
            let profile = profile_for(difficulty);
            assert!((1..=4).contains(&profile.custom_depth));
            assert!((0.0..=0.45).contains(&profile.custom_noise));
            assert!((1..=4).contains(&profile.fallback_custom_level));

            if let Some((skill, depth)) = profile.stockfish_settings() {
                assert!(profile.uses_stockfish());
                assert!(skill <= 20);
                assert!((1..=22).contains(&depth));
            } else {
                assert!(!profile.uses_stockfish());
            }
        }
    }

    #[test]
    fn stockfish_curve_is_monotonic_once_enabled() {
        let mut previous = None;
        for difficulty in 1..=10 {
            if let Some((skill, depth)) = profile_for(difficulty).stockfish_settings() {
                if let Some((prev_skill, prev_depth)) = previous {
                    assert!(skill >= prev_skill);
                    assert!(depth >= prev_depth);
                }
                previous = Some((skill, depth));
            }
        }
    }

    #[test]
    fn level_four_is_custom_bridge_before_stockfish() {
        assert!(!profile_for(4).uses_stockfish());
        assert!(profile_for(5).uses_stockfish());
    }

    #[test]
    fn stockfish_fallback_uses_strongest_custom_tier() {
        for difficulty in 5..=10 {
            assert_eq!(profile_for(difficulty).fallback_custom_level, 4);
        }
    }
}
