import 'package:flutter/foundation.dart';

import '../rust/api.dart' as rust;

class SettingsController extends ChangeNotifier
    implements ValueListenable<rust.Settings> {
  rust.Settings _settings = _defaults;
  bool _loaded = false;

  static const _defaults = rust.Settings(
    appTheme: rust.AppTheme.light,
    boardTheme: rust.BoardTheme.wood,
    pieceSet: rust.PieceSet.merida,
    accent: rust.Accent.walnut,
    soundEnabled: true,
    soundVolume: 0.6,
    showLegalMoves: true,
    showCoordinates: true,
    showLastMove: true,
  );

  @override
  rust.Settings get value => _settings;
  bool get loaded => _loaded;

  Future<void> init() async {
    try {
      _settings = _normalize(await rust.getSettings());
    } catch (_) {
      // keep defaults
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> update(rust.Settings Function(rust.Settings) fn) async {
    final next = _normalize(fn(_settings));
    _settings = next;
    notifyListeners();
    try {
      final saved = await rust.setSettings(settings: next);
      _settings = _normalize(saved);
      notifyListeners();
    } catch (_) {
      // ignore — local copy is still updated
    }
  }

  rust.Settings _normalize(rust.Settings s) {
    return rust.Settings(
      appTheme: s.appTheme,
      boardTheme: s.boardTheme,
      pieceSet: rust.PieceSet.merida, // only piece set actually shipped
      accent: s.accent,
      soundEnabled: s.soundEnabled,
      soundVolume: s.soundVolume.clamp(0, 1),
      showLegalMoves: s.showLegalMoves,
      showCoordinates: s.showCoordinates,
      showLastMove: s.showLastMove,
    );
  }
}
