// Selects between the real Tauri client and the in-browser mock.
// Mock is used automatically when running `vite dev` outside of Tauri
// (e.g. `pnpm dev`), or when `VITE_USE_MOCK=1` is set.

import { tauriApi, type ChessApi } from "./client";
import { mockApi } from "./mock";

const isTauri = "__TAURI_INTERNALS__" in window || "__TAURI__" in window;
const forceMock = import.meta.env.VITE_USE_MOCK === "1";

export const chess: ChessApi = !isTauri || forceMock ? mockApi : tauriApi;
export type { ChessApi } from "./client";
export * from "./contract";
