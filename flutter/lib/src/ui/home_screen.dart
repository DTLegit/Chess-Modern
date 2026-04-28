import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../audio/synth.dart';
import '../rust/api.dart' as rust;
import '../state/game_controller.dart';
import '../state/settings_controller.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/board/board_widget.dart';
import '../widgets/modals/about_dialog.dart';
import '../widgets/modals/game_over_dialog.dart';
import '../widgets/modals/new_game_dialog.dart';
import '../widgets/modals/settings_dialog.dart';
import '../widgets/modals/welcome_dialog.dart';
import '../widgets/panels/captures.dart';
import '../widgets/panels/clock_panel.dart';
import '../widgets/panels/move_history.dart';
import '../widgets/primitives/app_button.dart';
import '../widgets/primitives/app_dialog.dart';
import '../widgets/primitives/app_divider.dart';
import '../widgets/primitives/app_icon_button.dart';
import '../widgets/primitives/app_icons.dart';
import '../widgets/primitives/app_panel.dart';
import '../widgets/primitives/app_scaffold.dart';
import '../widgets/primitives/app_segmented.dart';

const double _mobileBreakpoint = 720;

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.game,
    required this.settings,
  });

  final GameController game;
  final SettingsController settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SoundSynth _synth;
  StreamSubscription? _soundSub;
  String? _gameOverDismissedFor;
  bool _welcomeShown = false;

  @override
  void initState() {
    super.initState();
    _synth = SoundSynth(widget.settings);
    _soundSub = widget.game.sounds.listen(_synth.play);
    widget.game.addListener(_onGameChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_welcomeShown && widget.game.live == null) {
        _welcomeShown = true;
        await showAppDialog(
          context,
          builder: (_) => WelcomeDialog(
            onNewGame: () => _openNewGameDialog(),
            onSettings: () => _openSettings(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _soundSub?.cancel();
    widget.game.removeListener(_onGameChanged);
    super.dispose();
  }

  void _onGameChanged() {
    final live = widget.game.live;
    if (live == null) return;

    if (live.status != rust.GameStatus.active &&
        live.result != rust.GameResult.ongoing &&
        live.gameId != _gameOverDismissedFor) {
      _gameOverDismissedFor = live.gameId;
      _showGameOver(live);
    }
  }

  Future<void> _showGameOver(rust.GameSnapshot snap) async {
    await showAppDialog(
      context,
      builder: (_) => GameOverDialog(
        snapshot: snap,
        game: widget.game,
        onNewGame: () => _openNewGameDialog(),
        onRematch: (opts) => widget.game.newGame(opts),
      ),
    );
  }

  Future<void> _openNewGameDialog() async {
    final opts = await showAppDialog<rust.NewGameOpts?>(
      context,
      builder: (_) => const NewGameDialog(),
    );
    if (opts != null) {
      _gameOverDismissedFor = null;
      await widget.game.newGame(opts);
    }
  }

  Future<void> _openSettings() async {
    await showAppDialog(
      context,
      builder: (_) => SettingsDialog(controller: widget.settings),
    );
  }

  Future<void> _openAbout() async {
    await showAppDialog(
      context,
      builder: (_) => const ChessAboutDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.keyN): const _NewGameIntent(),
        const SingleActivator(LogicalKeyboardKey.keyU): const _UndoIntent(),
        const SingleActivator(LogicalKeyboardKey.keyF): const _FlipIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            const _ScrubIntent(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            const _ScrubIntent(1),
        const SingleActivator(LogicalKeyboardKey.home): const _ScrubToIntent(0),
        const SingleActivator(LogicalKeyboardKey.end):
            const _ScrubLiveIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const _EscapeIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewGameIntent: CallbackAction<_NewGameIntent>(
              onInvoke: (_) => _openNewGameDialog()),
          _UndoIntent:
              CallbackAction<_UndoIntent>(onInvoke: (_) => widget.game.undo()),
          _FlipIntent: CallbackAction<_FlipIntent>(
              onInvoke: (_) => widget.game.flip()),
          _ScrubIntent: CallbackAction<_ScrubIntent>(
              onInvoke: (intent) => widget.game.scrubStep(intent.delta)),
          _ScrubToIntent: CallbackAction<_ScrubToIntent>(
              onInvoke: (intent) => widget.game.scrubTo(intent.index)),
          _ScrubLiveIntent: CallbackAction<_ScrubLiveIntent>(
              onInvoke: (_) => widget.game.scrubLive()),
          _EscapeIntent: CallbackAction<_EscapeIntent>(onInvoke: (_) {
            widget.game.deselect();
            widget.game.scrubLive();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < _mobileBreakpoint;
              return AppScaffold(
                topBar: _TopBar(
                  game: widget.game,
                  onNewGame: _openNewGameDialog,
                  onSettings: _openSettings,
                  onAbout: _openAbout,
                  isMobile: isMobile,
                ),
                statusBar: _StatusBar(game: widget.game),
                body: isMobile
                    ? _MobileLayout(
                        game: widget.game,
                        settings: widget.settings,
                        onOpenSettings: _openSettings,
                        onOpenNewGame: _openNewGameDialog,
                      )
                    : _DesktopLayout(
                        game: widget.game,
                        settings: widget.settings,
                      ),
                floatingActionButton: isMobile
                    ? AppButton(
                        label: 'New game',
                        onPressed: _openNewGameDialog,
                        leading: const IconPlus(),
                      )
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.game,
    required this.onNewGame,
    required this.onSettings,
    required this.onAbout,
    required this.isMobile,
  });

  final GameController game;
  final VoidCallback onNewGame;
  final VoidCallback onSettings;
  final VoidCallback onAbout;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final accent = theme.accent;
    return ListenableBuilder(
      listenable: game,
      builder: (_, __) {
        final l = game.live;
        final label = l == null
            ? 'Choose how to play'
            : (l.status != rust.GameStatus.active
                ? 'Game over'
                : (l.turn == rust.Color.w ? 'White to move' : 'Black to move'));
        final canUndo = (l?.history.length ?? 0) > 0;
        return Row(
          children: [
            // Brand mark (♛) + wordmark.
            Text(
              '♛',
              style: AppTextStyles.serifTitle.copyWith(
                color: accent.mid,
                fontSize: 22,
                height: 1.0,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Chess',
              style: AppTextStyles.serifTitle.copyWith(
                fontSize: 18,
                color: theme.palette.ink,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Container(
              width: 1,
              height: 18,
              color: theme.palette.hairline,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(label, style: AppTextStyles.bodyMuted.copyWith(
                  color: theme.palette.inkSoft,
                )),
            const Spacer(),
            if (!isMobile) ...[
              AppButton(
                label: 'New game',
                size: AppButtonSize.small,
                leading: const IconPlus(),
                onPressed: onNewGame,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIconButton(
                tooltip: 'Undo (U)',
                icon: const IconUndo(),
                onPressed: canUndo ? game.undo : null,
              ),
              const SizedBox(width: 4),
              AppIconButton(
                tooltip: 'Flip board (F)',
                icon: const IconFlip(),
                onPressed: game.flip,
              ),
              const SizedBox(width: 4),
              AppIconButton(
                tooltip: 'Settings',
                icon: const IconSettings(),
                onPressed: onSettings,
              ),
              const SizedBox(width: 4),
              AppIconButton(
                tooltip: 'About',
                icon: const IconInfo(),
                onPressed: onAbout,
              ),
            ] else
              AppIconButton(
                tooltip: 'Settings',
                icon: const IconSettings(),
                onPressed: onSettings,
              ),
          ],
        );
      },
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.game});
  final GameController game;
  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context).palette;
    return ListenableBuilder(
      listenable: game,
      builder: (_, __) {
        final live = game.live;
        final mode = live == null
            ? 'Welcome'
            : (live.mode == rust.GameMode.hva
                ? 'Human vs AI · level ${live.aiDifficulty ?? "?"}'
                : 'Human vs Human');
        return Row(
          children: [
            Text(
              mode,
              style: AppTextStyles.caption.copyWith(color: palette.inkMute),
            ),
            const Spacer(),
            Text(
              'N new · U undo · F flip · ← → scrub · Esc cancel',
              style: AppTextStyles.caption.copyWith(color: palette.inkFaint),
            ),
          ],
        );
      },
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.game, required this.settings});

  final GameController game;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.bigGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _BoardColumn(game: game, settings: settings),
          ),
          const SizedBox(width: AppSpacing.bigGap),
          SizedBox(
            width: 320,
            child: MoveHistoryPanel(game: game),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatefulWidget {
  const _MobileLayout({
    required this.game,
    required this.settings,
    required this.onOpenSettings,
    required this.onOpenNewGame,
  });

  final GameController game;
  final SettingsController settings;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenNewGame;

  @override
  State<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<_MobileLayout> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _PlayerStrip(
              game: widget.game, side: rust.Color.b, label: 'Opponent'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: BoardWidget(game: widget.game, settings: widget.settings),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _PlayerStrip(
              game: widget.game, side: rust.Color.w, label: 'You'),
        ),
        const AppDivider(),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppSegmented<int>(
            equalWidth: true,
            value: _tabIndex,
            onChanged: (v) => setState(() => _tabIndex = v),
            options: const [
              AppSegmentOption(value: 0, label: 'Moves'),
              AppSegmentOption(value: 1, label: 'Actions'),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _tabIndex,
            children: [
              MoveHistoryPanel(game: widget.game),
              _ActionsPanel(
                game: widget.game,
                onSettings: widget.onOpenSettings,
                onNewGame: widget.onOpenNewGame,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({required this.game, required this.settings});

  final GameController game;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PlayerStrip(game: game, side: rust.Color.b, label: 'Opponent'),
        const SizedBox(height: AppSpacing.sm),
        BoardWidget(game: game, settings: settings),
        const SizedBox(height: AppSpacing.sm),
        _PlayerStrip(game: game, side: rust.Color.w, label: 'You'),
      ],
    );
  }
}

class _PlayerStrip extends StatelessWidget {
  const _PlayerStrip({
    required this.game,
    required this.side,
    required this.label,
  });

  final GameController game;
  final rust.Color side;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    return ListenableBuilder(
      listenable: game,
      builder: (_, __) {
        final live = game.live;
        final mode = live?.mode ?? rust.GameMode.hvh;
        final hc = live?.humanColor;
        final ai = mode == rust.GameMode.hva && hc != null && hc != side;
        final aiBadge = ai && live?.aiDifficulty != null
            ? ' · AI ${live!.aiDifficulty}'
            : '';
        final thinking = game.thinking && live?.turn == side;
        return AppPanel(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: side == rust.Color.w
                      ? const Color(0xFFF7EEDB)
                      : const Color(0xFF1F1813),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x33000000), width: 1),
                ),
              ),
              Text(
                ai ? 'Computer$aiBadge' : label,
                style: AppTextStyles.body.copyWith(color: palette.ink),
              ),
              if (thinking)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Text(
                    'thinking…',
                    style: AppTextStyles.caption.copyWith(
                        color: palette.inkMute, fontStyle: FontStyle.italic),
                  ),
                ),
              const Spacer(),
              CapturesRow(game: game, side: side),
              const SizedBox(width: AppSpacing.lg),
              ClockPanel(game: game, side: side),
            ],
          ),
        );
      },
    );
  }
}

class _ActionsPanel extends StatelessWidget {
  const _ActionsPanel({
    required this.game,
    required this.onSettings,
    required this.onNewGame,
  });

  final GameController game;
  final VoidCallback onSettings;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ListenableBuilder(
        listenable: game,
        builder: (_, __) {
          final live = game.live;
          final canUndo = (live?.history.length ?? 0) > 0;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: 'New game',
                onPressed: onNewGame,
                leading: const IconPlus(),
              ),
              AppButton(
                label: 'Undo',
                variant: AppButtonVariant.ghost,
                onPressed: canUndo ? game.undo : null,
                leading: const IconUndo(),
              ),
              AppButton(
                label: 'Flip',
                variant: AppButtonVariant.ghost,
                onPressed: game.flip,
                leading: const IconFlip(),
              ),
              AppButton(
                label: 'Resign',
                variant: AppButtonVariant.ghost,
                onPressed: live == null ? null : () => game.resign(),
                leading: const IconFlag(),
              ),
              AppButton(
                label: 'Prev',
                variant: AppButtonVariant.ghost,
                onPressed: () => game.scrubStep(-1),
                leading: const IconChevronLeft(),
              ),
              AppButton(
                label: 'Next',
                variant: AppButtonVariant.ghost,
                onPressed: () => game.scrubStep(1),
                leading: const IconChevronRight(),
              ),
              AppButton(
                label: 'Live',
                variant: AppButtonVariant.ghost,
                onPressed: () => game.scrubLive(),
                leading: const IconLive(),
              ),
              AppButton(
                label: 'Settings',
                variant: AppButtonVariant.ghost,
                onPressed: onSettings,
                leading: const IconSettings(),
              ),
              AppButton(
                label: 'Export PGN',
                variant: AppButtonVariant.ghost,
                onPressed: live == null
                    ? null
                    : () async {
                        final pgn = await game.exportPgn();
                        if (!context.mounted) return;
                        await _showPgnDialog(context, pgn);
                      },
                leading: const IconUpload(),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _showPgnDialog(BuildContext context, String pgn) async {
  // Inline PGN preview dialog. The full file-save flow lives in
  // GameOverDialog (Phase 5b); this is a quick text preview/export.
  final palette = AppTheme.of(context).palette;
  await showAppDialog(
    context,
    builder: (ctx) => AppDialog(
      title: 'Export PGN',
      width: 520,
      body: Container(
        height: 300,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: palette.bgCard,
          border: Border.all(color: palette.hairline, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: Text(
            pgn,
            style: AppTextStyles.mono.copyWith(color: palette.ink),
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'Copy',
          variant: AppButtonVariant.ghost,
          leading: const IconCopy(),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: pgn));
          },
        ),
        AppButton(
          label: 'Close',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(ctx).maybePop(),
        ),
      ],
    ),
  );
}

class _NewGameIntent extends Intent {
  const _NewGameIntent();
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _FlipIntent extends Intent {
  const _FlipIntent();
}

class _ScrubIntent extends Intent {
  const _ScrubIntent(this.delta);
  final int delta;
}

class _ScrubToIntent extends Intent {
  const _ScrubToIntent(this.index);
  final int index;
}

class _ScrubLiveIntent extends Intent {
  const _ScrubLiveIntent();
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}
