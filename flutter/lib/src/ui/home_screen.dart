import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/synth.dart';
import '../rust/api.dart' as rust;
import '../state/game_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/board/board_widget.dart';
import '../widgets/modals/about_dialog.dart';
import '../widgets/modals/game_over_dialog.dart';
import '../widgets/modals/new_game_dialog.dart';
import '../widgets/modals/promotion_dialog.dart';
import '../widgets/modals/settings_dialog.dart';
import '../widgets/modals/welcome_dialog.dart';
import '../widgets/panels/captures.dart';
import '../widgets/panels/clock_panel.dart';
import '../widgets/panels/move_history.dart';

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
  String? _promotionShownFor;
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
        await showDialog(
          context: context,
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

    // Game-over modal auto-pop.
    if (live.status != rust.GameStatus.active &&
        live.result != rust.GameResult.ongoing &&
        live.gameId != _gameOverDismissedFor) {
      _gameOverDismissedFor = live.gameId;
      _showGameOver(live);
    }

    // Promotion modal.
    final pending = widget.game.pendingPromotion;
    if (pending != null && _promotionShownFor != _pendingKey(pending)) {
      _promotionShownFor = _pendingKey(pending);
      _showPromotionPicker(pending);
    }
  }

  String _pendingKey(PendingPromotion p) => '${p.from}->${p.to}@${p.color}';

  Future<void> _showPromotionPicker(PendingPromotion p) async {
    final choice = await showPromotionPicker(context, color: p.color);
    if (choice == null) {
      widget.game.cancelPromotion();
    } else {
      await widget.game.commitPromotion(choice);
    }
    _promotionShownFor = null;
  }

  Future<void> _showGameOver(rust.GameSnapshot snap) async {
    await showDialog(
      context: context,
      builder: (_) => GameOverDialog(
        snapshot: snap,
        onNewGame: () => _openNewGameDialog(),
        onRematch: (opts) => widget.game.newGame(opts),
      ),
    );
  }

  Future<void> _openNewGameDialog() async {
    final opts = await showDialog<rust.NewGameOpts?>(
      context: context,
      builder: (_) => const NewGameDialog(),
    );
    if (opts != null) {
      _gameOverDismissedFor = null;
      await widget.game.newGame(opts);
    }
  }

  Future<void> _openSettings() async {
    await showDialog(
      context: context,
      builder: (_) => SettingsDialog(controller: widget.settings),
    );
  }

  Future<void> _openAbout() async {
    await showDialog(
      context: context,
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
        const SingleActivator(LogicalKeyboardKey.home):
            const _ScrubToIntent(0),
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
          child: Scaffold(
            appBar: _buildAppBar(context),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < _mobileBreakpoint;
                  return isMobile
                      ? _MobileLayout(
                          game: widget.game,
                          settings: widget.settings,
                          onOpenSettings: _openSettings,
                          onOpenNewGame: _openNewGameDialog,
                        )
                      : _DesktopLayout(
                          game: widget.game,
                          settings: widget.settings,
                        );
                },
              ),
            ),
            floatingActionButton: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < _mobileBreakpoint;
                return isMobile
                    ? FloatingActionButton.extended(
                        onPressed: _openNewGameDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('New game'),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: ListenableBuilder(
        listenable: widget.game,
        builder: (_, __) {
          final l = widget.game.live;
          final label = l == null
              ? 'Choose how to play'
              : (l.status != rust.GameStatus.active
                  ? 'Game over'
                  : (l.turn == rust.Color.w
                      ? 'White to move'
                      : 'Black to move'));
          return Row(
            children: [
              const Text('Chess', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton.icon(
          onPressed: _openNewGameDialog,
          icon: const Icon(Icons.add),
          label: const Text('New game'),
        ),
        ListenableBuilder(
          listenable: widget.game,
          builder: (_, __) {
            final canUndo = (widget.game.live?.history.length ?? 0) > 0;
            return IconButton(
              tooltip: 'Undo (U)',
              onPressed: canUndo ? widget.game.undo : null,
              icon: const Icon(Icons.undo),
            );
          },
        ),
        IconButton(
          tooltip: 'Flip board (F)',
          onPressed: widget.game.flip,
          icon: const Icon(Icons.swap_vert),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: _openSettings,
          icon: const Icon(Icons.settings),
        ),
        IconButton(
          tooltip: 'About',
          onPressed: _openAbout,
          icon: const Icon(Icons.info_outline),
        ),
        const SizedBox(width: 4),
      ],
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
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _BoardColumn(game: game, settings: settings),
          ),
          const SizedBox(width: 20),
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

class _MobileLayout extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: _PlayerStrip(
              game: game, side: rust.Color.b, label: 'Opponent'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: BoardWidget(game: game, settings: settings),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: _PlayerStrip(
              game: game, side: rust.Color.w, label: 'You'),
        ),
        const Divider(height: 1),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Moves'),
                    Tab(text: 'Actions'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      MoveHistoryPanel(game: game),
                      _ActionsPanel(
                        game: game,
                        onSettings: onOpenSettings,
                        onNewGame: onOpenNewGame,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
        const SizedBox(height: 8),
        BoardWidget(game: game, settings: settings),
        const SizedBox(height: 8),
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
    return ListenableBuilder(
      listenable: game,
      builder: (_, __) {
        final live = game.live;
        final mode = live?.mode ?? rust.GameMode.hvh;
        final hc = live?.humanColor;
        final ai =
            mode == rust.GameMode.hva && hc != null && hc != side;
        final aiBadge = ai && live?.aiDifficulty != null
            ? ' · AI ${live!.aiDifficulty}'
            : '';
        final thinking = game.thinking && live?.turn == side;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
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
                  border: Border.all(color: const Color(0x33000000)),
                ),
              ),
              Text(
                ai ? 'Computer$aiBadge' : label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (thinking)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'thinking…',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const Spacer(),
              CapturesRow(game: game, side: side),
              const SizedBox(width: 8),
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
      padding: const EdgeInsets.all(12),
      child: ListenableBuilder(
        listenable: game,
        builder: (_, __) {
          final live = game.live;
          final canUndo = (live?.history.length ?? 0) > 0;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onNewGame,
                icon: const Icon(Icons.add),
                label: const Text('New game'),
              ),
              OutlinedButton.icon(
                onPressed: canUndo ? game.undo : null,
                icon: const Icon(Icons.undo),
                label: const Text('Undo'),
              ),
              OutlinedButton.icon(
                onPressed: () => game.flip(),
                icon: const Icon(Icons.swap_vert),
                label: const Text('Flip board'),
              ),
              OutlinedButton.icon(
                onPressed: live == null ? null : () => game.resign(),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Resign'),
              ),
              OutlinedButton.icon(
                onPressed: () => game.scrubStep(-1),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Prev'),
              ),
              OutlinedButton.icon(
                onPressed: () => game.scrubStep(1),
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
              ),
              OutlinedButton.icon(
                onPressed: () => game.scrubLive(),
                icon: const Icon(Icons.fast_forward),
                label: const Text('Live'),
              ),
              OutlinedButton.icon(
                onPressed: onSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
              ),
              OutlinedButton.icon(
                onPressed: live == null
                    ? null
                    : () async {
                        final pgn = await game.exportPgn();
                        if (!context.mounted) return;
                        await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Export PGN'),
                            content: SingleChildScrollView(
                              child: SelectableText(
                                pgn,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                icon: const Icon(Icons.file_upload),
                label: const Text('Export PGN'),
              ),
            ],
          );
        },
      ),
    );
  }
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
