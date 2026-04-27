import 'package:flutter/material.dart';

import '../rust/api.dart' as rust;

class ChessThemeData {
  const ChessThemeData({
    required this.material,
    required this.brightness,
    required this.boardLight,
    required this.boardDark,
    required this.boardBezel,
    required this.lastMoveHighlight,
    required this.selectedHighlight,
    required this.legalDot,
    required this.captureRing,
  });

  final ThemeData material;
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
    final brightness = switch (s.appTheme) {
      rust.AppTheme.dark => Brightness.dark,
      rust.AppTheme.light => Brightness.light,
      rust.AppTheme.blue => Brightness.dark,
    };
    final accent = switch (s.accent) {
      rust.Accent.walnut => const Color(0xFFB58959),
      rust.Accent.forest => const Color(0xFF2F6F56),
      rust.Accent.violet => const Color(0xFF8467d4),
      rust.Accent.teal => const Color(0xFF3aa3a3),
      rust.Accent.rose => const Color(0xFFc25b6f),
    };
    final board = _boardPalette(s.boardTheme);

    final material = ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );

    return ChessThemeData(
      material: material,
      brightness: brightness,
      boardLight: board.light,
      boardDark: board.dark,
      boardBezel: board.bezel,
      lastMoveHighlight: board.lastMove,
      selectedHighlight: board.selected,
      legalDot: board.dot,
      captureRing: board.ring,
    );
  }
}

class _BoardPalette {
  const _BoardPalette({
    required this.light,
    required this.dark,
    required this.bezel,
    required this.lastMove,
    required this.selected,
    required this.dot,
    required this.ring,
  });
  final Color light;
  final Color dark;
  final Color bezel;
  final Color lastMove;
  final Color selected;
  final Color dot;
  final Color ring;
}

_BoardPalette _boardPalette(rust.BoardTheme theme) {
  switch (theme) {
    case rust.BoardTheme.wood:
    case rust.BoardTheme.woodRealistic:
      return const _BoardPalette(
        light: Color(0xFFEED9B5),
        dark: Color(0xFFB58A56),
        bezel: Color(0xFF6E4A2A),
        lastMove: Color(0x88E2C166),
        selected: Color(0x66ECC369),
        dot: Color(0x66222222),
        ring: Color(0xAA222222),
      );
    case rust.BoardTheme.slate:
    case rust.BoardTheme.slateRealistic:
      return const _BoardPalette(
        light: Color(0xFFB1B8C2),
        dark: Color(0xFF54606C),
        bezel: Color(0xFF2A2F36),
        lastMove: Color(0x88CCA238),
        selected: Color(0x88789952),
        dot: Color(0xAA000000),
        ring: Color(0xAA000000),
      );
    case rust.BoardTheme.marble:
      return const _BoardPalette(
        light: Color(0xFFECEFF3),
        dark: Color(0xFF8B939F),
        bezel: Color(0xFF5E6878),
        lastMove: Color(0x88E2C166),
        selected: Color(0x77AED88E),
        dot: Color(0x88333333),
        ring: Color(0xAA333333),
      );
    case rust.BoardTheme.emerald:
      return const _BoardPalette(
        light: Color(0xFFD8EFE3),
        dark: Color(0xFF2F6F56),
        bezel: Color(0xFF13362B),
        lastMove: Color(0x88E2C166),
        selected: Color(0x77B6D580),
        dot: Color(0xAA113322),
        ring: Color(0xAA113322),
      );
    case rust.BoardTheme.obsidian:
      return const _BoardPalette(
        light: Color(0xFF7B8797),
        dark: Color(0xFF151B26),
        bezel: Color(0xFF131820),
        lastMove: Color(0x99CCA238),
        selected: Color(0x88789952),
        dot: Color(0xAAEFE5C5),
        ring: Color(0xAAEFE5C5),
      );
    case rust.BoardTheme.sandstone:
      return const _BoardPalette(
        light: Color(0xFFEFD8B8),
        dark: Color(0xFFB58959),
        bezel: Color(0xFF7A5738),
        lastMove: Color(0x88E2C166),
        selected: Color(0x77B6D580),
        dot: Color(0xAA663311),
        ring: Color(0xAA663311),
      );
    case rust.BoardTheme.midnight:
      return const _BoardPalette(
        light: Color(0xFF4B5F86),
        dark: Color(0xFF101A30),
        bezel: Color(0xFF0B1323),
        lastMove: Color(0x99CCA238),
        selected: Color(0x88789952),
        dot: Color(0xAAA9C0E9),
        ring: Color(0xAAA9C0E9),
      );
  }
}
