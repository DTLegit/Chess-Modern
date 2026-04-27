import 'package:flutter/material.dart';

import '../../rust/api.dart' as rust;
import '../board/piece_widget.dart';

Future<rust.Promotion?> showPromotionPicker(
  BuildContext context, {
  required rust.Color color,
}) async {
  return showDialog<rust.Promotion>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Promote to',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PromoTile(
                    color: color,
                    kind: rust.PieceKind.q,
                    promo: rust.Promotion.q),
                _PromoTile(
                    color: color,
                    kind: rust.PieceKind.r,
                    promo: rust.Promotion.r),
                _PromoTile(
                    color: color,
                    kind: rust.PieceKind.b,
                    promo: rust.Promotion.b),
                _PromoTile(
                    color: color,
                    kind: rust.PieceKind.n,
                    promo: rust.Promotion.n),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _PromoTile extends StatelessWidget {
  const _PromoTile({
    required this.color,
    required this.kind,
    required this.promo,
  });

  final rust.Color color;
  final rust.PieceKind kind;
  final rust.Promotion promo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(promo),
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 64,
        height: 64,
        child: PieceWidget(
          piece: rust.Piece(color: color, kind: kind),
        ),
      ),
    );
  }
}
