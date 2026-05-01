import 'package:flutter/material.dart' show ColorScheme;
import 'package:flutter/widgets.dart';

import '../rust/api.dart' as rust;
import 'tokens.dart';

/// Aggregated theme data — palette + accent + highlights + board palette.
/// All visual decisions in primitives and screens flow from this.
@immutable
class AppThemeData {
  const AppThemeData({
    required this.palette,
    required this.accent,
    required this.highlights,
    required this.board,
    required this.appTheme,
    required this.accentEnum,
    required this.boardThemeEnum,
  });

  final AppPalette palette;
  final AppAccent accent;
  final AppHighlights highlights;
  final BoardPalette board;
  final rust.AppTheme appTheme;
  final rust.Accent accentEnum;
  final rust.BoardTheme boardThemeEnum;

  Brightness get brightness => palette.brightness;

  /// Build from a Rust Settings record.
  factory AppThemeData.fromSettings(
    rust.Settings s, {
    ColorScheme? lightDynamic,
    ColorScheme? darkDynamic,
    Brightness platformBrightness = Brightness.light,
  }) {
    return AppThemeData(
      palette: palettesFor(s.appTheme, lightDynamic: lightDynamic, darkDynamic: darkDynamic, platformBrightness: platformBrightness),
      accent: accentFor(s.accent),
      highlights: const AppHighlights(),
      board: boardPaletteFor(s.boardTheme),
      appTheme: s.appTheme,
      accentEnum: s.accent,
      boardThemeEnum: s.boardTheme,
    );
  }
}

/// `InheritedWidget` exposing [AppThemeData] to descendants.
///
/// Replaces `Theme.of(context)` everywhere outside `legacy/`. Read with
/// `AppTheme.of(context)` from any descendant build method.
class AppTheme extends InheritedWidget {
  const AppTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final AppThemeData data;

  static AppThemeData of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(widget != null, 'No AppTheme ancestor in context.');
    return widget!.data;
  }

  /// Read once without subscribing — use sparingly (e.g. inside a one-shot
  /// callback where rebuilding on theme change is unnecessary).
  static AppThemeData? maybeOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    return widget?.data;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) => oldWidget.data != data;
}

// ---------------------------------------------------------------------------
// Legacy bridge — preserved during phased migration.
//
// The board widget (and its subwidgets) currently consume `ChessThemeData`
// via `ChessThemeBuilder.of(settings)`. Until the board migration in Phase 4
// rewires it onto AppTheme.of(context) directly, expose the same shape so
// nothing breaks.
// ---------------------------------------------------------------------------

@immutable
class ChessThemeData {
  const ChessThemeData({
    required this.brightness,
    required this.boardLight,
    required this.boardDark,
    required this.boardBezel,
    required this.lastMoveHighlight,
    required this.selectedHighlight,
    required this.legalDot,
    required this.captureRing,
  });

  final Brightness brightness;
  final Color boardLight;
  final Color boardDark;
  final Color boardBezel;
  final Color lastMoveHighlight;
  final Color selectedHighlight;
  final Color legalDot;
  final Color captureRing;
}

class ChessThemeBuilder {
  static ChessThemeData of(rust.Settings s) {
    final palette = palettesFor(s.appTheme);
    final board = boardPaletteFor(s.boardTheme);
    const highlights = AppHighlights();
    return ChessThemeData(
      brightness: palette.brightness,
      boardLight: board.light,
      boardDark: board.dark,
      boardBezel: board.bezel,
      lastMoveHighlight: highlights.last,
      selectedHighlight: highlights.select,
      legalDot: highlights.dot,
      captureRing: highlights.dotCap,
    );
  }
}
