# Cursor Agent Prompt — Flutter Visual Parity with Legacy Svelte+Tauri UI

Copy everything **below the horizontal rule** into the Cursor agent. This is a self-contained brief; the agent will not have access to the conversation that produced it.

---

## Mission

You are working in the **Chess-Test** repository on branch **`master`**. The Flutter migration has already landed (`flutter/` is the shipping UI). Your job is to make the Flutter UI a **faithful visual clone of the previous Svelte 5 + Tauri 2 UI** — same colors, typography, spacing, shadows, layouts, animations, modals, panels, menus, settings options, and overall feel.

The previous Svelte UI is preserved at **`legacy/svelte/`** and is the **single source of truth for the visual spec**. Treat its CSS, component structure, and interaction model as authoritative. When the current Flutter implementation diverges from the Svelte original, the Svelte original wins unless there is a documented platform reason otherwise.

To get there cleanly, you will also **drop `MaterialApp` and Material 3** in favor of a custom widget framework rooted in `WidgetsApp`. Material's design language has too many opinionated defaults (button heights, dialog padding, ripple semantics, surface tints, M3 shape system) that fight visual parity at every step. A small primitive widget library — under ~10 components — covers the entire UI surface of this app.

This is a **bounded UI rewrite**, not a re-architecture. The Rust core, the bridge contract, the state controllers, the audio synth, and the platform plumbing all stay as they are.

## Hard constraints (do not violate)

- **Do not modify `crates/chess_core/` or the Rust bridge command/event contract.** All 15 commands and the `BackendEvent` broadcast stream must continue to work unchanged.
- **Do not modify `crates/chess_bridge/src/api.rs` types or signatures.** If you genuinely need a new field, document why and re-run `flutter_rust_bridge_codegen generate`. Avoid this if at all possible.
- **Do not touch `legacy/`.** It is the visual spec and the fallback. Read it; do not edit it.
- **Do not break `cargo test --workspace`** or **`flutter test`**. Extend tests if you add new widgets that warrant coverage.
- **Do not run `flutter_rust_bridge_codegen integrate`.** It overwrites runner files. The bindings are already generated; only `... codegen generate` should run, and only if you change `crates/chess_bridge/src/api.rs` (which you should not).
- **Do not `git push`** unless explicitly asked. Commit locally as logical chunks land.
- **Do not introduce new top-level dependencies casually.** `file_selector` is approved (see "Restoring product divergences" below). Anything else, ask first.
- **Keep `flutter analyze` clean** at every commit.

## Files to read first (in order)

Read each file in full before writing any code. Build a mental model of the system, not a search index.

1. `README.md` — project overview, stack, run commands.
2. `CLAUDE.md` — architecture summary; this is the canonical short brief.
3. `MIGRATION.md` — what moved from Svelte/Tauri to Flutter/FRB and why.
4. `KNOWN_ISSUES.md` — intentional divergences. Several of these will be reverted as part of this work; see "Restoring product divergences."
5. `legacy/svelte/` — read the whole tree. Especially:
   - The component source for the App shell, board, panels, modals, settings.
   - All CSS files / `<style>` blocks. Extract design tokens (colors, spacing, radii, shadows, line-heights, font weights, transition durations and curves).
   - Any global theme file or CSS variables file (`:root { --... }`).
6. `flutter/lib/main.dart` and `flutter/lib/src/app.dart` — current entry points; you will replace `MaterialApp` here.
7. `flutter/lib/src/ui/home_screen.dart` — main screen.
8. `flutter/lib/src/state/game_controller.dart` and `settings_controller.dart` — state plumbing. Do not change behavior; just consume from your new widgets.
9. `flutter/lib/src/widgets/board/` — board widget and the Merida piece set.
10. `flutter/lib/src/widgets/modals/` and `flutter/lib/src/widgets/panels/` — current Material-flavored implementations to be rewritten.
11. `flutter/lib/src/audio/synth.dart` and `flutter/lib/src/bridge/stockfish_setup.dart` — leave alone; just confirm they're not affected.
12. `flutter/pubspec.yaml` — current dependencies and asset list.

After reading, **write a short plan** (in chat, not as a file) summarizing: the design tokens you extracted from Svelte, the primitive widgets you will build, the screens/widgets you will migrate, and any open questions.

## Visual spec: legacy Svelte is the source of truth

The Svelte UI defines the look and feel. Concretely, extract from `legacy/svelte/` and reproduce in Flutter:

- **Color palette** — every `--color-*` CSS variable, hex codes, and where each is used (background, surface, primary, accent, text-primary, text-muted, border, etc.). Light and dark themes if both exist.
- **Typography** — font family stack, font weights used, base size, scale ratios, line heights, letter-spacing per role (heading, body, mono, button, label).
- **Spacing scale** — every `--space-*` token or padding/margin value used. Reproduce the same scale in Flutter.
- **Border radii** — square/rounded variants per component class.
- **Shadows** — every `box-shadow` value used. Reproduce as `BoxShadow` lists with matching `blurRadius`, `spreadRadius`, `offset`, and color.
- **Transitions** — durations and easing curves used for hovers, modal opens, board highlights. Reproduce with `Curves.*` and matching `Duration` values.
- **Layout** — exact paddings, gaps, alignments, widths of panels, board sizing rules, responsive breakpoints (the Svelte version had desktop and the Flutter version added mobile; preserve desktop layout fidelity and adapt mobile from it consistently).
- **Iconography** — icon set/library used in Svelte, exact glyph choices and sizes.
- **Sound mapping** — the synth is procedural; confirm the same `SoundKind` values are mapped to the same waveforms (look in `legacy/svelte/lib/audio/synth.ts` vs `flutter/lib/src/audio/synth.dart`).

If the Svelte version uses a custom font file, **bundle that exact font** as a Flutter asset under `flutter/assets/fonts/` and reference it in your `AppTextTheme`.

If the Svelte version is currently dead code (no `package.json` at the root anymore — see `MIGRATION.md` last section), you do not need to revive it to *run* it. Reading the source files for visual values is enough. If you want side-by-side visual comparison, follow the revival steps in `MIGRATION.md` ("Reviving the legacy Tauri shell" / restoring root `package.json` from commit `cc34907`).

## Implementation work order

Execute in this order. Commit at each milestone with a clear message.

### 1. Extract the design system

Create `flutter/lib/src/theme/` with:

- `tokens.dart` — raw values pulled from Svelte CSS. Pure constants: `AppColors`, `AppSpacing`, `AppRadii`, `AppShadows`, `AppDurations`, `AppCurves`. No widgets.
- `typography.dart` — `AppTextStyles` with named roles (`heading1`, `body`, `bodyMuted`, `button`, `label`, `mono`, etc.) using the bundled font.
- `app_theme.dart` — an `InheritedWidget` exposing the above to the widget tree (`AppTheme.of(context)`). This replaces `Theme.of(context)`.

Bundle fonts in `pubspec.yaml`'s `flutter:` section if needed.

### 2. Build the primitive widget library

Create `flutter/lib/src/widgets/primitives/` with these widgets. Each should be a thin custom implementation matching the Svelte CSS for the equivalent role. Keep each file small.

- `app_button.dart` — `AppButton` (filled, outlined, ghost variants via an enum). No ripple, no Material elevation. Use `MouseRegion` + `GestureDetector` + an `AnimatedContainer` or `AnimatedOpacity` for the hover/press states defined in the Svelte CSS.
- `app_icon_button.dart` — square variant of `AppButton` for toolbar icons.
- `app_dialog.dart` — modal dialog frame. Title, content slot, action row. Used via `showAppDialog(context, ...)` which internally uses `Navigator.push(PageRouteBuilder(opaque: false, barrierDismissible: true, ...))`.
- `app_modal_sheet.dart` — bottom-anchored modal for mobile breakpoints if the Svelte design uses one; otherwise omit.
- `app_panel.dart` — `Card`-equivalent surface with the Svelte panel padding, border, radius, shadow.
- `app_list_row.dart` — `ListTile`-equivalent for settings rows and move-list rows. Match Svelte row metrics exactly.
- `app_slider.dart`, `app_switch.dart`, `app_checkbox.dart`, `app_radio.dart` — settings controls. Match Svelte form-control styling.
- `app_divider.dart`, `app_label.dart`, `app_text_field.dart` — small utility widgets for forms and labels.
- `app_scaffold.dart` — replaces `Scaffold`. A thin `WidgetsApp`-friendly page frame with optional title bar and body slot.

Rules for primitives:

- **No Material widgets in primitive implementations.** Build from `Container`, `DecoratedBox`, `GestureDetector`, `MouseRegion`, `Focus`, `Semantics`, `AnimatedContainer`, `Stack`, `Row`, `Column`, `Padding`, `Align`, `ConstrainedBox`, `CustomPaint`.
- **No `InkWell`, no `Material`, no `Theme`.** All styling reads from `AppTheme.of(context)`.
- **Splash/ripple is forbidden** unless the Svelte original explicitly had one (it almost certainly did not).
- **Accessibility**: wrap interactive primitives in `Semantics(button: true, label: ...)` etc. Don't lose what `MaterialApp` was giving you for free here.

### 3. Replace `MaterialApp` with `WidgetsApp`

In `flutter/lib/src/app.dart`:

- Replace `MaterialApp(...)` with `WidgetsApp(...)`.
- Provide `color:` (required by `WidgetsApp`), a `pageRouteBuilder` returning `PageRouteBuilder` instances with the transition behavior matching the Svelte original (likely a quick fade or none), and a `builder:` that wraps the child in your `AppTheme` `InheritedWidget` and a `DefaultTextStyle` using your base text style.
- Provide `localizationsDelegates: [DefaultMaterialLocalizations.delegate, DefaultWidgetsLocalizations.delegate, DefaultCupertinoLocalizations.delegate]` to keep stuff like text-selection menus working.
- Remove every direct `Theme.of(context)` and `MediaQuery`-based Material color lookup; replace with `AppTheme.of(context)`.

### 4. Migrate screens and widgets

For each file under `flutter/lib/src/ui/`, `flutter/lib/src/widgets/modals/`, and `flutter/lib/src/widgets/panels/`:

- Replace `AlertDialog` → `AppDialog` (and `showDialog` → `showAppDialog`).
- Replace `ElevatedButton`/`TextButton`/`OutlinedButton`/`FilledButton` → `AppButton` with the right variant.
- Replace `IconButton` → `AppIconButton`.
- Replace `Card` → `AppPanel`.
- Replace `ListTile` → `AppListRow`.
- Replace `Switch`/`Slider`/`Checkbox`/`Radio` → their `App*` equivalents.
- Replace `Scaffold` → `AppScaffold`.
- Replace `SnackBar` calls → an `AppToast` overlay you build (or skip if Svelte didn't use them).
- Remove `Theme.of(context)` calls; use `AppTheme.of(context)`.

The board widget (`flutter/lib/src/widgets/board/`) is already mostly `CustomPainter`-based — touch it only to (a) match exact Svelte square colors, last-move highlight, check highlight, legal-move dot styling, coordinate label styling, and piece sizing, and (b) wire in any interactions changed by "Restoring product divergences" below.

### 5. Restore product divergences from `KNOWN_ISSUES.md`

The Flutter port intentionally simplified three things. The Svelte version did them differently and should be restored:

- **In-board promotion picker** — Svelte drew the picker on top of the destination square. Replace the current centered Material dialog promotion picker with an in-board overlay matching the Svelte component. Position it over the promotion target square.
- **Real file-save dialog for PGN export** — currently a `SelectableText` dialog. Add the `file_selector` package (`file_selector: ^1.0.0`) to `pubspec.yaml`, use `getSaveLocation()` for desktop, and on mobile fall back to `Share` or the existing copy-to-clipboard path. Document the mobile fallback in `KNOWN_ISSUES.md`.
- **Drag-to-move on the board** — Svelte supported pointer drag. Implement drag-to-move in the Flutter board widget alongside the existing tap-to-select / tap-to-target flow. Use `Draggable` from the framework or hand-rolled `GestureDetector` + `Overlay` if `Draggable`'s feedback positioning doesn't match.

After restoring, **update `KNOWN_ISSUES.md`** to remove these three entries.

### 6. Side-by-side visual review

Open the legacy Svelte UI source side by side with each Flutter screen. Walk every state:

- Idle board (white to move, black to move).
- Mid-game with several moves played.
- Check highlight on the king.
- Checkmate end-of-game banner.
- Stalemate / draw banners.
- Promotion in progress.
- Settings modal — every option (board theme, piece set, AI difficulty, time control, sound on/off, accent color, etc.).
- About dialog.
- PGN export dialog / save flow.
- Clock running, low-time visual state, time-forfeit state.
- AI thinking indicator state.

For each state, the Flutter rendering should be visually faithful. Adjust tokens and primitives where it isn't. Pixel-perfect parity is structurally impossible (Skia vs WebKit text/shadow rendering), but indistinguishable-to-a-casual-eye is the bar.

### 7. Cleanup and documentation

- Delete the now-unused old Material-flavored widget files (don't leave shims).
- Confirm zero references to `MaterialApp`, `Material`, `Theme.of`, `AlertDialog`, `ElevatedButton`, `TextButton`, `OutlinedButton`, `FilledButton`, `Card`, `ListTile`, `Scaffold` (other than your `AppScaffold`), `IconButton`, `showDialog`, `showModalBottomSheet`, `Switch`, `Slider`, `Checkbox`, `Radio` outside of `legacy/`. Use `grep -r` from `flutter/lib/` to verify.
- Run `flutter analyze` and ensure clean.
- Run `flutter test` and ensure clean.
- Add or update Dart tests for the primitive widgets where reasonable (e.g. golden tests for `AppButton`, `AppDialog`).
- Update `MIGRATION.md` with a new section "Visual parity pass" describing the design-token approach and the move off `MaterialApp`. Keep it short.
- Update `CLAUDE.md` if any guidance there is now wrong.

## Gotchas and how to handle them

- **`WidgetsApp` requires a `color:` parameter.** Set it to your background color from tokens.
- **`Navigator` works without `MaterialApp`.** It's provided by `WidgetsApp`. You do not lose routing.
- **`showDialog` does require a Material ancestor.** That's why you build `showAppDialog` using `Navigator.push(PageRouteBuilder(...))` directly. Do not wrap your whole app in a `Material` to "fix" `showDialog`.
- **Some third-party widgets assume Material context.** None of the deps in `pubspec.yaml` (`flutter_rust_bridge`, `audioplayers`, `flutter_svg`, `path_provider`, `freezed_annotation`, `uuid`, `collection`, `meta`, `cupertino_icons`) require Material context. If you need to add a dep that does, wrap the minimal subtree in `Material(type: MaterialType.transparency, child: ...)` rather than reintroducing `MaterialApp`.
- **Text selection menus**: providing `DefaultMaterialLocalizations.delegate` keeps the system text-selection toolbar working in `SelectableText` etc. without a `MaterialApp`.
- **Keyboard navigation / focus rings**: the Svelte version presumably had focus styles. Use `Focus` + `FocusableActionDetector` and paint your own focus ring matching the Svelte CSS `:focus-visible` rules.
- **Page transitions**: `WidgetsApp` defaults to `_DefaultPageTransitionsBuilder` which uses `MaterialPageRoute` semantics. Provide your own `pageRouteBuilder` that returns a `PageRouteBuilder` with the fade/slide that matches Svelte route changes.
- **Don't reintroduce M3 surface tints accidentally.** If you find yourself reaching for `Theme.of(context).colorScheme`, stop — use `AppTheme.of(context)` instead.
- **Don't use Material `Icons.*` without checking.** Material icon set may differ from the Svelte icon set. Match the Svelte iconography. If Svelte used Lucide / Feather / Heroicons / a custom set, bundle the same set as SVG via `flutter_svg`.

## Acceptance criteria

The work is done when **all** of the following are true:

1. `grep -r "MaterialApp\|AlertDialog\|ElevatedButton\|TextButton\|OutlinedButton\|FilledButton\|^[^/]*Card\b\|ListTile\|^[^/]*Scaffold\b\|InkWell" flutter/lib/` returns nothing outside of imports the framework forces. (Tune the regex; the spirit is "no Material widgets in `flutter/lib/`.")
2. `flutter analyze` is clean.
3. `flutter test` passes; new primitive widgets have at least smoke tests.
4. `cargo test --workspace --all-targets` passes (you should not have changed any Rust, but verify).
5. The app launches on macOS desktop and renders every screen visually faithful to the Svelte original. Document any unavoidable divergences with reasons.
6. The three product divergences (in-board promotion, file-save PGN export, drag-to-move) are restored, and `KNOWN_ISSUES.md` no longer lists them.
7. `MIGRATION.md` has a new "Visual parity pass" section.
8. No new top-level dependencies beyond `file_selector` (and its required transitives).

## Out of scope (do not do)

- Rewriting `chess_core` or `chess_bridge`.
- Changing the 15-command + 4-event API contract.
- Reviving or modifying `legacy/tauri/` or `legacy/svelte/`.
- Native library wiring for macOS/Windows/iOS/Android (separate work item; Linux is already wired).
- Adding new game features (analysis mode, opening book, online play, etc.).
- Performance optimization of the Rust core or AI.
- Refactoring the state controllers beyond what's needed to consume new widgets.

## Open questions to flag rather than guess

If any of these are ambiguous after reading the Svelte source, ask before deciding:

- Mobile-specific layout adaptations not covered by the Svelte CSS (Svelte was desktop-only; the Flutter version added phones).
- Whether to support a system-driven dark mode toggle if Svelte had a manual switch only.
- Whether the bundled fonts have license terms requiring attribution in the About dialog.

## Final notes

- Work in small commits, one logical chunk at a time. A reasonable sequence: tokens → typography → primitives (one PR-sized chunk) → app shell migration → screen-by-screen migration → product divergences → cleanup.
- Do not wholesale `git rm` files until the new equivalents compile and render.
- If you hit a blocker that requires a real architectural decision, stop and ask. Document the blocker, the smallest safe partial state to leave behind, and the options.
- The bar is "indistinguishable to a casual eye when placed next to the Svelte original," not "byte-identical screenshot." Skia and WebKit cannot produce byte-identical output; chasing the last 1% is a sink.

Confirm you have read this entire document and the files in "Files to read first," then post your short plan before writing code.
