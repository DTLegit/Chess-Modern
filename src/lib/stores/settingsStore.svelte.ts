// Settings store wired to the API. Persisted by the backend (mock keeps an
// in-memory copy; real Tauri client persists to disk).

import { chess } from "../api";
import type { Settings } from "../api/contract";

const DEFAULT: Settings = {
  app_theme: "light",
  board_theme: "wood",
  piece_set: "classic",
  sound_enabled: true,
  sound_volume: 0.6,
  show_legal_moves: true,
  show_coordinates: true,
  show_last_move: true,
};

class SettingsStore {
  settings = $state<Settings>({ ...DEFAULT });
  loaded = $state(false);

  async init() {
    try {
      const s = await chess.getSettings();
      this.settings = s;
    } catch {
      // keep defaults
    } finally {
      this.loaded = true;
    }
  }

  async update(patch: Partial<Settings>) {
    const next: Settings = { ...this.settings, ...patch };
    this.settings = next;
    try {
      const saved = await chess.setSettings(next);
      this.settings = saved;
    } catch {
      // ignore — local copy is still updated
    }
  }
}

export const settingsStore = new SettingsStore();
