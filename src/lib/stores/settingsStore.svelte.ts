// Settings store wired to the API. Persisted by the backend (mock keeps an
// in-memory copy; real Tauri client persists to disk).

import { chess } from "../api";
import type { Accent, AppTheme, Settings } from "../api/contract";

const DEFAULT: Settings = {
  app_theme: "light",
  board_theme: "wood",
  piece_set: "merida",
  accent: "walnut",
  sound_enabled: true,
  sound_volume: 0.6,
  show_legal_moves: true,
  show_coordinates: true,
  show_last_move: true,
};

function normalizeSettings(s: Settings): Settings {
  return {
    ...DEFAULT,
    ...s,
    piece_set: "merida",
    accent: (s.accent ?? "walnut") as Accent,
    app_theme: (s.app_theme ?? "light") as AppTheme,
  };
}

class SettingsStore {
  settings = $state<Settings>({ ...DEFAULT });
  loaded = $state(false);

  async init() {
    try {
      const s = await chess.getSettings();
      this.settings = normalizeSettings(s);
    } catch {
      // keep defaults
    } finally {
      this.loaded = true;
    }
  }

  async update(patch: Partial<Settings>) {
    const next = normalizeSettings({ ...this.settings, ...patch });
    this.settings = next;
    try {
      const saved = await chess.setSettings(next);
      this.settings = normalizeSettings(saved);
    } catch {
      // ignore — local copy is still updated
    }
  }
}

export const settingsStore = new SettingsStore();
