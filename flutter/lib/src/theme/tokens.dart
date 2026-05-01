import 'package:flutter/material.dart' show ColorScheme;
import 'package:flutter/widgets.dart';

import '../rust/api.dart' as rust;

/// Design tokens extracted from `legacy/svelte/styles/app.css`.
/// Single source of truth for the visual spec.
///
/// All hex codes, rgba values, durations, and easing curves correspond
/// directly to the CSS custom properties on the Svelte side. See the
/// inline comments for line-numbered references.

/// Surface and ink palette per app theme.
@immutable
class AppPalette {
  const AppPalette({
    required this.bg,
    required this.bgSoft,
    required this.bgCard,
    required this.bgElev,
    required this.ink,
    required this.inkSoft,
    required this.inkMute,
    required this.inkFaint,
    required this.walnut,
    required this.walnutDeep,
    required this.hairline,
    required this.hairlineStrong,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.shadowBoard,
    required this.brightness,
  });

  final Color bg;
  final Color bgSoft;
  final Color bgCard;
  final Color bgElev;
  final Color ink;
  final Color inkSoft;
  final Color inkMute;
  final Color inkFaint;
  final Color walnut;
  final Color walnutDeep;
  final Color hairline;
  final Color hairlineStrong;
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;
  final List<BoxShadow> shadowBoard;
  final Brightness brightness;
}

/// app.css :root (light) — lines 7–77.
const _casualLightPalette = AppPalette(
  bg: Color(0xFFF4EDE0),
  bgSoft: Color(0xFFEFE6D4),
  bgCard: Color(0xFFFBF6EC),
  bgElev: Color(0xFFFFFAF0),
  ink: Color(0xFF1F1A14),
  inkSoft: Color(0xFF4A4136),
  inkMute: Color(0xFF7A6F60),
  inkFaint: Color(0xFFB3A692),
  walnut: Color(0xFF6E4A2A),
  walnutDeep: Color(0xFF3A2515),
  hairline: Color(0x242D1E0F), // rgba(45,30,15,0.14)
  hairlineStrong: Color(0x3D2D1E0F), // rgba(45,30,15,0.24)
  shadowSm: [
    BoxShadow(color: Color(0x0F28190A), blurRadius: 2, offset: Offset(0, 1)),
  ],
  shadowMd: [
    BoxShadow(color: Color(0x1428190A), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A28190A), blurRadius: 2, offset: Offset(0, 1)),
  ],
  shadowLg: [
    BoxShadow(color: Color(0x2E1E1206), blurRadius: 44, offset: Offset(0, 14)),
    BoxShadow(color: Color(0x0F1E1206), blurRadius: 6, offset: Offset(0, 2)),
  ],
  shadowBoard: [
    BoxShadow(color: Color(0x3D1E1206), blurRadius: 40, offset: Offset(0, 16)),
    BoxShadow(color: Color(0x141E1206), blurRadius: 4, offset: Offset(0, 2)),
  ],
  brightness: Brightness.light,
);

const _lightPalette = AppPalette(
  bg: Color(0xFFFFFFFF),
  bgSoft: Color(0xFFF4F4F5),
  bgCard: Color(0xFFFFFFFF),
  bgElev: Color(0xFFFFFFFF),
  ink: Color(0xFF09090B),
  inkSoft: Color(0xFF52525B),
  inkMute: Color(0xFFA1A1AA),
  inkFaint: Color(0xFFD4D4D8),
  walnut: Color(0xFF6E4A2A),
  walnutDeep: Color(0xFF3A2515),
  hairline: Color(0xFFE4E4E7),
  hairlineStrong: Color(0xFFD4D4D8),
  shadowSm: [],
  shadowMd: [],
  shadowLg: [],
  shadowBoard: [],
  brightness: Brightness.light,
);

/// app.css [data-theme="dark"] — lines 79–104.
const _casualDarkPalette = AppPalette(
  bg: Color(0xFF1A1B1E),
  bgSoft: Color(0xFF25262B),
  bgCard: Color(0xFF2C2E33),
  bgElev: Color(0xFF3B3E45),
  ink: Color(0xFFF8F9FA),
  inkSoft: Color(0xFFD2D3D6),
  inkMute: Color(0xFFA9ADB3),
  inkFaint: Color(0xFF6E737B),
  walnut: Color(0xFF8A6642),
  walnutDeep: Color(0xFF5B3A20),
  hairline: Color(0x1AFFFFFF),
  hairlineStrong: Color(0x2EFFFFFF),
  shadowSm: [
    BoxShadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1)),
  ],
  shadowMd: [
    BoxShadow(color: Color(0x80000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x4D000000), blurRadius: 2, offset: Offset(0, 1)),
  ],
  shadowLg: [
    BoxShadow(color: Color(0x99000000), blurRadius: 44, offset: Offset(0, 14)),
    BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
  ],
  shadowBoard: [
    BoxShadow(color: Color(0xB3000000), blurRadius: 40, offset: Offset(0, 16)),
    BoxShadow(color: Color(0x80000000), blurRadius: 4, offset: Offset(0, 2)),
  ],
  brightness: Brightness.dark,
);

const _darkPalette = AppPalette(
  bg: Color(0xFF18181B),
  bgSoft: Color(0xFF27272A),
  bgCard: Color(0xFF18181B),
  bgElev: Color(0xFF27272A),
  ink: Color(0xFFFAFAFA),
  inkSoft: Color(0xFFD4D4D8),
  inkMute: Color(0xFFA1A1AA),
  inkFaint: Color(0xFF71717A),
  walnut: Color(0xFF8A6642),
  walnutDeep: Color(0xFF5B3A20),
  hairline: Color(0xFF3F3F46),
  hairlineStrong: Color(0xFF52525B),
  shadowSm: [],
  shadowMd: [],
  shadowLg: [],
  shadowBoard: [],
  brightness: Brightness.dark,
);

/// Charcoal Black Tactile Flat theme.
const _blackPalette = AppPalette(
  bg: Color(0xFF121212),
  bgSoft: Color(0xFF1E1E1E),
  bgCard: Color(0xFF121212),
  bgElev: Color(0xFF1E1E1E),
  ink: Color(0xFFFFFFFF),
  inkSoft: Color(0xFFE4E4E7),
  inkMute: Color(0xFFA1A1AA),
  inkFaint: Color(0xFF71717A),
  walnut: Color(0xFF8A6642),
  walnutDeep: Color(0xFF5B3A20),
  hairline: Color(0xFF27272A),
  hairlineStrong: Color(0xFF3F3F46),
  shadowSm: [],
  shadowMd: [],
  shadowLg: [],
  shadowBoard: [],
  brightness: Brightness.dark,
);

const _liquidGlassPalette = AppPalette(
  bg: Color(0xFFF2F2F7), // iOS grouped background
  bgSoft: Color(0xFFE5E5EA),
  bgCard: Color(0x99FFFFFF), // translucent glass
  bgElev: Color(0xCCFFFFFF),
  ink: Color(0xFF000000),
  inkSoft: Color(0xFF3A3A3C),
  inkMute: Color(0xFF8E8E93),
  inkFaint: Color(0xFFC7C7CC),
  walnut: Color(0xFF8A6642),
  walnutDeep: Color(0xFF5B3A20),
  hairline: Color(0x403C3C43), // iOS separator
  hairlineStrong: Color(0x593C3C43),
  shadowSm: [],
  shadowMd: [],
  shadowLg: [
    BoxShadow(color: Color(0x1A000000), blurRadius: 44, offset: Offset(0, 14)),
  ],
  shadowBoard: [],
  brightness: Brightness.light,
);

AppPalette materialPaletteFor(ColorScheme? lightDynamic, ColorScheme? darkDynamic, Brightness brightness) {
  final cs = brightness == Brightness.light 
      ? (lightDynamic ?? ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)))
      : (darkDynamic ?? ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4), brightness: Brightness.dark));
      
  return AppPalette(
    bg: cs.surface,
    bgSoft: cs.surfaceContainerHighest,
    bgCard: cs.surfaceContainer,
    bgElev: cs.surfaceContainerHigh,
    ink: cs.onSurface,
    inkSoft: cs.onSurfaceVariant,
    inkMute: cs.outline,
    inkFaint: cs.outlineVariant,
    walnut: const Color(0xFF8A6642),
    walnutDeep: const Color(0xFF5B3A20),
    hairline: cs.outlineVariant.withValues(alpha: 0.5),
    hairlineStrong: cs.outline,
    shadowSm: [],
    shadowMd: [],
    shadowLg: [
      BoxShadow(color: cs.shadow.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
    ],
    shadowBoard: [],
    brightness: brightness,
  );
}

AppPalette palettesFor(
  rust.AppTheme theme, {
  ColorScheme? lightDynamic,
  ColorScheme? darkDynamic,
  Brightness platformBrightness = Brightness.light,
}) {
  switch (theme) {
    case rust.AppTheme.light:
      return _lightPalette;
    case rust.AppTheme.dark:
      return _darkPalette;
    case rust.AppTheme.black:
      return _blackPalette;
    case rust.AppTheme.casualLight:
      return _casualLightPalette;
    case rust.AppTheme.casualDark:
      return _casualDarkPalette;
    case rust.AppTheme.liquidGlass:
      return _liquidGlassPalette;
    case rust.AppTheme.material:
      return materialPaletteFor(lightDynamic, darkDynamic, platformBrightness);
  }
}

/// Accent quartet (base / mid / soft / ink-on-accent).
@immutable
class AppAccent {
  const AppAccent({
    required this.base,
    required this.mid,
    required this.soft,
    required this.ink,
  });
  final Color base;
  final Color mid;
  final Color soft;
  final Color ink;
}

/// app.css [data-accent="*"] — lines 133–163.
const _walnut = AppAccent(
  base: Color(0xFF9A6F2E),
  mid: Color(0xFFC2933B),
  soft: Color(0xFFD6B06B),
  ink: Color(0xFFFFFAEE),
);
const _forest = AppAccent(
  base: Color(0xFF1B4D3E),
  mid: Color(0xFF2D6A4F),
  soft: Color(0xFF52B788),
  ink: Color(0xFFF0FDF8),
);
const _violet = AppAccent(
  base: Color(0xFF5B21B6),
  mid: Color(0xFF7C3AED),
  soft: Color(0xFFC4B5FD),
  ink: Color(0xFFFAF5FF),
);
const _teal = AppAccent(
  base: Color(0xFF0F766E),
  mid: Color(0xFF14B8A6),
  soft: Color(0xFF5EEAD4),
  ink: Color(0xFFF0FDFA),
);
const _rose = AppAccent(
  base: Color(0xFF9F1239),
  mid: Color(0xFFE11D48),
  soft: Color(0xFFFDA4AF),
  ink: Color(0xFFFFF1F2),
);

AppAccent accentFor(rust.Accent a) {
  switch (a) {
    case rust.Accent.walnut:
      return _walnut;
    case rust.Accent.forest:
      return _forest;
    case rust.Accent.violet:
      return _violet;
    case rust.Accent.teal:
      return _teal;
    case rust.Accent.rose:
      return _rose;
  }
}

/// app.css highlight overlays — lines 47–52.
@immutable
class AppHighlights {
  const AppHighlights();
  Color get last => const Color(0x6BCCA238); // rgba(204,162,56,0.42)
  Color get select => const Color(0x6B789952); // rgba(120,153,82,0.42)
  Color get check => const Color(0x8CC25B4F); // rgba(194,91,79,0.55)
  Color get dot => const Color(0x52281E14); // rgba(40,30,20,0.32)
  Color get dotCap => const Color(0x8C281E14); // rgba(40,30,20,0.55)
}

/// Spacing scale used across Svelte CSS (component paddings, gaps).
class AppSpacing {
  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 14;
  static const double xxl = 16;
  static const double huge = 18;
  static const double bigGap = 22;
  static const double pageMargin = 24;
}

class AppRadii {
  static const double tiny = 4;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 14;
  static const double pill = 999;
}

/// app.css motion — lines 69–74.
class AppDurations {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration pieceMove = Duration(milliseconds: 240);
  static const Duration checkPulse = Duration(milliseconds: 1400);
}

class AppCurves {
  /// cubic-bezier(0.22, 1, 0.36, 1)
  static const Cubic easeOut = Cubic(0.22, 1, 0.36, 1);

  /// cubic-bezier(0.65, 0, 0.35, 1)
  static const Cubic easeInOut = Cubic(0.65, 0, 0.35, 1);

  /// cubic-bezier(0.5, -0.4, 0.55, 1.4) — bounce-out used on captured pieces.
  static const Cubic captureBounce = Cubic(0.5, -0.4, 0.55, 1.4);
}

/// Soft red used by clock low-time and danger buttons. app.css line 45.
const Color appRedSoft = Color(0xFFC25B4F);

/// Sage green from app.css line 44.
const Color appSage = Color(0xFF8AA17B);

/// Per-board-theme square colors. Mirrors `legacy/svelte/lib/board/Board.svelte`
/// theme classes and CSS variables from app.css lines 26–35 (wood/slate) plus
/// the 7 additional themes defined in Board.svelte's class blocks.
@immutable
class BoardPalette {
  const BoardPalette({
    required this.light,
    required this.dark,
    required this.bezel,
    required this.lightAlt,
    required this.darkAlt,
  });

  final Color light;
  final Color dark;
  final Color bezel;
  final Color lightAlt;
  final Color darkAlt;
}

const _woodPalette = BoardPalette(
  light: Color(0xFFEFD9B3),
  lightAlt: Color(0xFFE6CB9A),
  dark: Color(0xFFA4763E),
  darkAlt: Color(0xFF8A5E2C),
  bezel: Color(0xFF6E4A2A),
);

const _slatePalette = BoardPalette(
  light: Color(0xFFE9EAEE),
  lightAlt: Color(0xFFD8DADE),
  dark: Color(0xFF6D7785),
  darkAlt: Color(0xFF5C6776),
  bezel: Color(0xFF2A2F36),
);

const _marblePalette = BoardPalette(
  light: Color(0xFFECEFF3),
  lightAlt: Color(0xFFD9DEE6),
  dark: Color(0xFF8B939F),
  darkAlt: Color(0xFF6F7785),
  bezel: Color(0xFF5E6878),
);

const _emeraldPalette = BoardPalette(
  light: Color(0xFFD8EFE3),
  lightAlt: Color(0xFFB7DCC6),
  dark: Color(0xFF2F6F56),
  darkAlt: Color(0xFF1F4F3D),
  bezel: Color(0xFF13362B),
);

const _obsidianPalette = BoardPalette(
  light: Color(0xFF7B8797),
  lightAlt: Color(0xFF5E6A78),
  dark: Color(0xFF151B26),
  darkAlt: Color(0xFF0E141C),
  bezel: Color(0xFF131820),
);

const _sandstonePalette = BoardPalette(
  light: Color(0xFFEFD8B8),
  lightAlt: Color(0xFFE2C397),
  dark: Color(0xFFB58959),
  darkAlt: Color(0xFF976B3E),
  bezel: Color(0xFF7A5738),
);

const _midnightPalette = BoardPalette(
  light: Color(0xFF4B5F86),
  lightAlt: Color(0xFF374A6D),
  dark: Color(0xFF101A30),
  darkAlt: Color(0xFF080F22),
  bezel: Color(0xFF0B1323),
);

BoardPalette boardPaletteFor(rust.BoardTheme theme) {
  switch (theme) {
    case rust.BoardTheme.wood:
    case rust.BoardTheme.woodRealistic:
      return _woodPalette;
    case rust.BoardTheme.slate:
    case rust.BoardTheme.slateRealistic:
      return _slatePalette;
    case rust.BoardTheme.marble:
      return _marblePalette;
    case rust.BoardTheme.emerald:
      return _emeraldPalette;
    case rust.BoardTheme.obsidian:
      return _obsidianPalette;
    case rust.BoardTheme.sandstone:
      return _sandstonePalette;
    case rust.BoardTheme.midnight:
      return _midnightPalette;
  }
}

/// Per-theme grain overlay config for squares.
/// Mimics CSS `linear-gradient` noise layers on the Svelte board.
@immutable
class BoardGrainConfig {
  const BoardGrainConfig({
    required this.lightGrain,
    required this.darkGrain,
    this.lightHighlight = const Color(0x00FFFFFF),
    this.darkHighlight = const Color(0x00FFFFFF),
  });
  /// Subtle gradient overlay color on light squares.
  final Color lightGrain;
  /// Subtle gradient overlay color on dark squares.
  final Color darkGrain;
  final Color lightHighlight;
  final Color darkHighlight;
}

const _woodGrain = BoardGrainConfig(
  lightGrain: Color(0x14C8A060),
  darkGrain: Color(0x1F000000),
  lightHighlight: Color(0x0AFFFFFF),
  darkHighlight: Color(0x0DFFFFFF),
);

const _slateGrain = BoardGrainConfig(
  lightGrain: Color(0x0AFFFFFF),
  darkGrain: Color(0x14000000),
);

const _marbleGrain = BoardGrainConfig(
  lightGrain: Color(0x14FFFFFF),
  darkGrain: Color(0x0A000000),
  lightHighlight: Color(0x0CFFFFFF),
);

const _emeraldGrain = BoardGrainConfig(
  lightGrain: Color(0x1400CC66),
  darkGrain: Color(0x1F001F11),
  darkHighlight: Color(0x0FFFFFFF),
);

const _obsidianGrain = BoardGrainConfig(
  lightGrain: Color(0x14FFFFFF),
  darkGrain: Color(0x1F000000),
);

const _sandstoneGrain = BoardGrainConfig(
  lightGrain: Color(0x14D4A860),
  darkGrain: Color(0x1F000000),
  lightHighlight: Color(0x0AFFFFFF),
);

const _midnightGrain = BoardGrainConfig(
  lightGrain: Color(0x14AABBEE),
  darkGrain: Color(0x1F000714),
);

BoardGrainConfig boardGrainFor(rust.BoardTheme theme) {
  switch (theme) {
    case rust.BoardTheme.woodRealistic:
      return const BoardGrainConfig(
        lightGrain: Color(0x22C8A060),
        darkGrain: Color(0x33000000),
        lightHighlight: Color(0x14FFFFFF),
        darkHighlight: Color(0x14FFFFFF),
      );
    case rust.BoardTheme.wood:
      return _woodGrain;
    case rust.BoardTheme.slateRealistic:
      return const BoardGrainConfig(
        lightGrain: Color(0x14FFFFFF),
        darkGrain: Color(0x22000000),
        lightHighlight: Color(0x0EFFFFFF),
      );
    case rust.BoardTheme.slate:
      return _slateGrain;
    case rust.BoardTheme.marble:
      return _marbleGrain;
    case rust.BoardTheme.emerald:
      return _emeraldGrain;
    case rust.BoardTheme.obsidian:
      return _obsidianGrain;
    case rust.BoardTheme.sandstone:
      return _sandstoneGrain;
    case rust.BoardTheme.midnight:
      return _midnightGrain;
  }
}

/// Per-theme bezel gradient configuration.
@immutable
class BoardBezelConfig {
  const BoardBezelConfig({
    required this.topColor,
    required this.bottomColor,
    this.innerHighlight = const Color(0x12FFFFFF),
  });
  final Color topColor;
  final Color bottomColor;
  final Color innerHighlight;
}

BoardBezelConfig boardBezelFor(rust.BoardTheme theme) {
  final b = boardPaletteFor(theme).bezel;
  // Each theme darkens the bezel 20% toward black at the bottom.
  final darker = Color.lerp(b, const Color(0xFF000000), 0.2)!;
  switch (theme) {
    case rust.BoardTheme.wood:
    case rust.BoardTheme.woodRealistic:
    case rust.BoardTheme.sandstone:
      return BoardBezelConfig(
        topColor: b,
        bottomColor: darker,
        innerHighlight: const Color(0x18FFFFFF),
      );
    case rust.BoardTheme.slate:
    case rust.BoardTheme.slateRealistic:
    case rust.BoardTheme.marble:
    case rust.BoardTheme.obsidian:
    case rust.BoardTheme.midnight:
      return BoardBezelConfig(
        topColor: b,
        bottomColor: darker,
        innerHighlight: const Color(0x0EFFFFFF),
      );
    case rust.BoardTheme.emerald:
      return BoardBezelConfig(
        topColor: b,
        bottomColor: darker,
        innerHighlight: const Color(0x10FFFFFF),
      );
  }
}
