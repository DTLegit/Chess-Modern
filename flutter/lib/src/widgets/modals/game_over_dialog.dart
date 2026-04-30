import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../rust/api.dart' as rust;
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';
import '../primitives/app_button.dart';
import '../primitives/app_dialog.dart';
import '../primitives/app_icons.dart';

class GameOverDialog extends StatefulWidget {
  const GameOverDialog({
    super.key,
    required this.snapshot,
    required this.game,
    required this.onNewGame,
    required this.onRematch,
  });

  final rust.GameSnapshot snapshot;
  final GameController game;
  final VoidCallback onNewGame;
  final void Function(rust.NewGameOpts) onRematch;

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog> {
  bool _copied = false;

  Future<void> _copyPgn() async {
    final pgn = await widget.game.exportPgn();
    await Clipboard.setData(ClipboardData(text: pgn));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _exportPgn() async {
    final pgn = await widget.game.exportPgn();
    if (!mounted) return;
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      const typeGroup = XTypeGroup(
        label: 'PGN',
        extensions: ['pgn'],
        mimeTypes: ['application/x-chess-pgn'],
      );
      final location = await getSaveLocation(
        suggestedName: 'game.pgn',
        acceptedTypeGroups: const [typeGroup],
      );
      if (location == null) return;
      final file = File(location.path);
      await file.writeAsString(pgn);
    } else {
      // Mobile: documented fallback is "Copy" (see KNOWN_ISSUES.md
      // mobile-fallback note).
      await _copyPgn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final s = widget.snapshot;

    return AppDialog(
      width: 420,
      title: _resultTitle(s.result),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _resultDetail(s.status),
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: palette.inkSoft),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${s.history.length} ${s.history.length == 1 ? "move" : "moves"} played.',
            style: AppTextStyles.caption.copyWith(color: palette.inkMute),
          ),
          const SizedBox(height: AppSpacing.huge),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppButton(
                label: _copied ? 'Copied!' : 'Copy PGN',
                variant: AppButtonVariant.ghost,
                leading: const IconCopy(),
                onPressed: _copyPgn,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: 'Export PGN…',
                variant: AppButtonVariant.ghost,
                leading: const IconUpload(),
                onPressed: _exportPgn,
              ),
            ],
          ),
        ],
      ),
      actions: [
        AppButton(
          label: 'Close',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        if (s.mode == rust.GameMode.hva && s.aiDifficulty != null)
          AppButton(
            label: 'Rematch',
            variant: AppButtonVariant.ghost,
            onPressed: () {
              Navigator.of(context).maybePop();
              // Swap colors on rematch (mirrors Svelte GameOver.svelte rematch()).
              final swapped = s.humanColor == rust.Color.w
                  ? rust.HumanColorChoice.b
                  : rust.HumanColorChoice.w;
              widget.onRematch(rust.NewGameOpts(
                mode: s.mode,
                aiDifficulty: s.aiDifficulty,
                humanColor: swapped,
                timeControl: s.clock != null
                    ? rust.TimeControl(
                        initialMs: s.clock!.whiteMs,
                        incrementMs: BigInt.zero,
                      )
                    : null,
              ));
            },
          ),
        AppButton(
          label: 'New game',
          onPressed: () {
            Navigator.of(context).maybePop();
            widget.onNewGame();
          },
        ),
      ],
    );
  }
}

String _resultTitle(rust.GameResult r) {
  switch (r) {
    case rust.GameResult.white:
      return 'White wins';
    case rust.GameResult.black:
      return 'Black wins';
    case rust.GameResult.draw:
      return 'Draw';
    case rust.GameResult.ongoing:
      return 'Game over';
  }
}

String _resultDetail(rust.GameStatus s) {
  switch (s) {
    case rust.GameStatus.checkmate:
      return 'by checkmate';
    case rust.GameStatus.stalemate:
      return 'by stalemate';
    case rust.GameStatus.drawFiftyMove:
      return 'by the fifty-move rule';
    case rust.GameStatus.drawThreefold:
      return 'by threefold repetition';
    case rust.GameStatus.drawInsufficient:
      return 'by insufficient material';
    case rust.GameStatus.drawAgreement:
      return 'by agreement';
    case rust.GameStatus.resigned:
      return 'by resignation';
    case rust.GameStatus.timeForfeit:
      return 'on time';
    case rust.GameStatus.active:
      return '';
  }
}
