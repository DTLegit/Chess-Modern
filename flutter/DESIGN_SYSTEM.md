# Tactile Flat Design System

## Overview
This design system defines the aesthetic and layout principles for the game suite, focusing on the "Tactile Flat" style. This design merges minimalist layout and typography (reminiscent of Vercel/Apple) with playful, highly legible flat component design (reminiscent of Duolingo).

The "Tactile Flat" design language heavily relies on bold color fills, ample whitespace, round/pill-shaped components, and 1px hairline borders for elevation and grouping instead of drop shadows.

## Themes
The system supports themes grouped into 3 distinct categories:

### 1. Modern (Tactile Flat)
- **Light**: The default "Tactile Flat" light theme. Clean white backgrounds, crisp text, and solid component fills. No shadows.
- **Dark**: The default "Tactile Flat" dark theme. Sleek dark backgrounds, crisp text. No shadows.
- **Black**: The "Tactile Flat" charcoal black theme. Uses a very dark charcoal/gray (`#121212`), high contrast text, and subtle vibrant accents. No shadows.

### 2. Casual
- **Casual Light**: A legacy theme preserving the original skeuomorphic light aesthetic (with drop shadows and subtle gradients).
- **Casual Dark**: A legacy theme preserving the original skeuomorphic dark aesthetic (with drop shadows and subtle gradients).

### 3. Native
- **Liquid Glass**: Matches modern iOS (26+) aesthetics with extensive use of translucent, frosted glass (`BackdropFilter`) materials and subtle styling.
- **Material**: Matches modern Android aesthetics (Material 3/You). Extensively utilizes `dynamic_color` to adapt seamlessly to the user's system color scheme and wallpaper.

## Visual Guidelines (Tactile Flat)
### Elevation
- **No Drop Shadows**: Components should not use `box-shadow` in Tactile Flat themes.
- **Hairline Borders**: Separate distinct areas (e.g., top bars, panels, cards) using a 1px solid border (often `hairline` or `hairlineStrong` from the palette).
- **Background Contrast**: Use subtle contrast between the base background (`bg`) and elevated surfaces (`bgElev` or `bgCard`).

### Shapes
- **Pill-shaped Components**: Buttons, chips, and segmented controls should use generous border radii (e.g., `AppRadii.pill` or `AppRadii.lg`).
- **Cards and Panels**: Use slightly tighter border radii (e.g., `AppRadii.md` or `AppRadii.lg`) with hairline borders.

### Typography & Spacing
- Rely on `AppTextStyles` and `AppSpacing` defined in the existing theme system.
- Ensure generous padding (`AppSpacing.lg`, `AppSpacing.xl`, or `AppSpacing.bigGap`) around major layout sections to maintain a clean, breathable aesthetic.

## Game Suite Architecture
This application is evolving into a full Games Suite.
The UI architecture follows a **Universal Game Shell** model:
- **GameShell Widget**: A universal scaffold providing the suite-wide navigation.
  - **Top App Bar**: Houses a hamburger menu button (for suite navigation) and context titles.
  - **Hamburger Drawer**: The suite's global navigation menu, linking back to the Games Hub, Settings, and About screens.
  - **Bottom Navigation**: Contextual actions specific to the currently active game. For example, in Chess, this is a bottom action bar with icon-only buttons that can be dragged up (via a pill-shaped drag handle) to reveal button text labels.
- **Game Viewport**: The central area of the `GameShell` dynamically renders the active game (e.g., `BoardWidget` for Chess).

By using the `GameShell`, new games can be added to the suite with a consistent outer UI, while focusing solely on their core game logic and viewport representation. All UI components (like `AppDialog`, `GameShell`, `AppSegmented`, `AppButton`) are decoupled from chess logic and are fully reusable.

## Motion & Animations
To maintain a premium, modern feel across the suite, animations should be **fluid, subtle, and non-blocking**. Motion should never get in the user's way; it should only serve to clarify state changes and add a layer of polish.

### Philosophy
- **Fluid & Subtle**: Use smooth easing curves that start quickly and settle gently.
- **Non-blocking**: Users should not have to wait for an animation to finish before they can interact with the app.
- **Purposeful**: Animate state transitions (like theme changes, drawer reveals, and expanded action bars) to give context to the user, not just for decoration.

### Timing & Curves
Always use the standardized durations and curves defined in `AppDurations` and `AppCurves` to ensure consistency:
- **`AppDurations.fast`** (e.g., 150ms): Use for micro-interactions, hovers, small layout shifts, and drawer toggles.
- **`AppDurations.base`** (e.g., 300ms): Use for larger screen transitions, modal appearances, theme crossfades, and full-page switches.
- **`AppCurves.easeOut`**: The default curve for almost all UI animations. It provides a snappy entrance and a graceful deceleration.

### Standard Widgets
For future games and components, prefer Flutter's built-in implicit animation widgets over manual controllers where possible to keep the code declarative and clean:
- **`AnimatedContainer`**: The go-to tool for animating changes in color (like theme switches), padding, border radius, and simple layout adjustments.
- **`AnimatedSwitcher`**: Use for gracefully crossfading or scaling between completely different widgets (e.g., fading out the Welcome Screen or swapping icons).
- **`AnimatedSize` / `AnimatedOpacity`**: Perfect for revealing or hiding content, such as expanding the text labels in the bottom action bar.
- **Staggered Animations**: When revealing lists (like the Game Shell drawer items), use small incremental delays combined with `FadeTransition` and `SlideTransition` to create a cascading entrance effect.
