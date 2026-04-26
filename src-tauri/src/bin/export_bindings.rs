//! Regenerate `src/lib/api/bindings.ts` without launching the Tauri GUI.
//!
//! Useful in CI / headless environments where launching the webview is
//! not possible. Mirrors the export step that runs implicitly during
//! debug builds via `chess_lib::run`.

fn main() {
    let path = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "../src/lib/api/bindings.ts".to_string());

    if let Err(err) = chess_lib::export_typescript_bindings(&path) {
        eprintln!("failed to export TypeScript bindings: {err}");
        std::process::exit(1);
    }

    println!("wrote tauri-specta bindings to {path}");
}
