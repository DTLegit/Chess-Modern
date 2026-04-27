import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../rust/api.dart' as rust;
import 'merida.dart';

/// Renders a single chess piece via SVG. The Merida piece set is the
/// only one shipped today (matches the legacy Svelte UI which already
/// forced `piece_set = Merida` in `SessionManager::set_settings`).
class PieceWidget extends StatelessWidget {
  const PieceWidget({super.key, required this.piece, this.size});

  final rust.Piece piece;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final svg = meridaSvg(piece.kind, piece.color);
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
