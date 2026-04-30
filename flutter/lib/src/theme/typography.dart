import 'package:flutter/widgets.dart';

/// Typography roles, mirroring `legacy/svelte/styles/app.css` font stacks
/// (lines 63–67, 178–183) plus per-component sizes scattered through the
/// Svelte components.
///
/// The `fontFamily` entries reference asset-bundled fonts declared in
/// `pubspec.yaml`. `fontFamilyFallback` lets the renderer fall back to
/// system fonts on platforms where the bundled font is missing.
class AppFontFamilies {
  static const String sans = 'Inter';
  static const String serif = 'EBGaramond';
  static const String mono = 'JetBrainsMono';

  static const List<String> sansFallback = [
    'Inter',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Helvetica Neue',
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  static const List<String> serifFallback = [
    'New York',
    'Iowan Old Style',
    'Palatino',
    'Palatino Linotype',
    'Georgia',
    'Times New Roman',
    'serif',
  ];

  static const List<String> monoFallback = [
    'SF Mono',
    'Menlo',
    'Consolas',
    'Liberation Mono',
    'Courier New',
    'monospace',
  ];
}

class AppTextStyles {
  /// Body text — Svelte body: 14px / 1.5 line-height, Inter.
  static const TextStyle body = TextStyle(
    fontFamily: AppFontFamilies.sans,
    fontFamilyFallback: AppFontFamilies.sansFallback,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    fontFeatures: [FontFeature('ss01')],
  );

  /// Slightly subdued body text (--c-ink-soft / mute applied via color).
  static const TextStyle bodyMuted = TextStyle(
    fontFamily: AppFontFamilies.sans,
    fontFamilyFallback: AppFontFamilies.sansFallback,
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// Small helper text — captions, hints.
  static const TextStyle caption = TextStyle(
    fontFamily: AppFontFamilies.sans,
    fontFamilyFallback: AppFontFamilies.sansFallback,
    fontSize: 12,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  /// Tiny uppercase label (e.g. "Main Menu", "Mode") — letter-spacing 0.14em.
  static const TextStyle label = TextStyle(
    fontFamily: AppFontFamilies.sans,
    fontFamilyFallback: AppFontFamilies.sansFallback,
    fontSize: 10,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4, // ~0.14em at 10px
    // Color set per theme via inkMute.
  );

  /// Button label.
  static const TextStyle button = TextStyle(
    fontFamily: AppFontFamilies.sans,
    fontFamilyFallback: AppFontFamilies.sansFallback,
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// Serif h2 — used in modal headers (22px, -0.012em letter-spacing).
  static const TextStyle serifTitle = TextStyle(
    fontFamily: AppFontFamilies.serif,
    fontFamilyFallback: AppFontFamilies.serifFallback,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.27, // ~-0.012em at 22px
  );

  /// Serif hero title — used in WelcomeScreen ("Chess", 28px).
  static const TextStyle serifHero = TextStyle(
    fontFamily: AppFontFamilies.serif,
    fontFamilyFallback: AppFontFamilies.serifFallback,
    fontSize: 28,
    height: 1.1,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.34,
  );

  /// h1 sans (page-level headings inside dialogs other than serif).
  static const TextStyle heading1 = TextStyle(
    fontFamily: AppFontFamilies.sans,
    fontFamilyFallback: AppFontFamilies.sansFallback,
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  );

  /// Section heading (e.g. settings sub-section).
  static const TextStyle heading2 = TextStyle(
    fontFamily: AppFontFamilies.sans,
    fontFamilyFallback: AppFontFamilies.sansFallback,
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  /// Tabular monospace — clocks, SAN, custom-time inputs.
  static const TextStyle mono = TextStyle(
    fontFamily: AppFontFamilies.mono,
    fontFamilyFallback: AppFontFamilies.monoFallback,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Clock face — mm:ss.d, big tabular figures. Matches Svelte Clock.svelte 28px.
  static const TextStyle clock = TextStyle(
    fontFamily: AppFontFamilies.mono,
    fontFamilyFallback: AppFontFamilies.monoFallback,
    fontSize: 28,
    height: 1.0,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.28, // -0.01em at 28px
  );

  /// AI badge / very tiny label.
  static const TextStyle badge = TextStyle(
    fontFamily: AppFontFamilies.sans,
    fontFamilyFallback: AppFontFamilies.sansFallback,
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );
}
