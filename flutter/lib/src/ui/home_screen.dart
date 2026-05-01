import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show showModalBottomSheet;

import '../audio/synth.dart';
import '../rust/api.dart' as rust;
import '../state/game_controller.dart';
import '../state/settings_controller.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/board/board_widget.dart';
import '../widgets/modals/about_dialog.dart';
import '../widgets/modals/appearance_dialog.dart';
import '../widgets/modals/game_over_dialog.dart';
import '../widgets/modals/new_game_dialog.dart';
import '../widgets/modals/settings_dialog.dart';
import '../widgets/modals/welcome_dialog.dart';
import '../widgets/panels/captures.dart';
import '../widgets/panels/clock_panel.dart';
import '../widgets/panels/move_history.dart';
import '../widgets/primitives/app_button.dart';
import '../widgets/primitives/game_logo.dart';
import '../widgets/primitives/app_dialog.dart';
import '../widgets/primitives/app_icons.dart';
import '../widgets/primitives/app_panel.dart';
import '../widgets/primitives/app_scaffold.dart';
import '../widgets/primitives/game_shell.dart';

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
  bool _welcomeOpen = false;

  @override
  void initState() {
    super.initState();
    _synth = SoundSynth(widget.settings);
    _soundSub = widget.game.sounds.listen(_synth.play);
    widget.game.addListener(_onGameChanged);
    // Show welcome screen if no game is active.
    _welcomeOpen = widget.game.live == null;
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
    // On first launch (no active game) the user must start a game — hide the
    // cancel button and prevent scrim-tap dismissal.
    final isFirstGame = widget.game.live == null;
    final opts = await showAppDialog<rust.NewGameOpts?>(
      context,
      barrierDismissible: !isFirstGame,
      builder: (_) => NewGameDialog(canDismiss: !isFirstGame),
    );
    if (opts != null) {
      _gameOverDismissedFor = null;
      await widget.game.newGame(opts);
    }
  }

  Future<void> _openSettings({bool showBoardTheme = true}) async {
    await showAppDialog(
      context,
      builder: (_) => SettingsDialog(
        controller: widget.settings,
      ),
    );
  }

  Future<void> _openAppearance({bool showBoardTheme = true}) async {
    await showAppDialog(
      context,
      builder: (_) => AppearanceDialog(
        controller: widget.settings,
        showBoardTheme: showBoardTheme,
      ),
    );
  }

  Future<void> _openAbout() async {
    await showAppDialog(
      context,
      builder: (_) => const ChessAboutDialog(),
    );
  }

  void _openWelcome() {
    setState(() => _welcomeOpen = true);
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
              final ui = isMobile
                  ? _MobileLayout(
                      game: widget.game,
                      settings: widget.settings,
                      onOpenSettings: _openSettings,
                      onOpenAppearance: _openAppearance,
                      onOpenNewGame: _openNewGameDialog,
                      onOpenWelcome: _openWelcome,
                      onOpenAbout: _openAbout,
                    )
                  : AppScaffold(
                      topBar: _TopBar(
                        game: widget.game,
                        onNewGame: _openNewGameDialog,
                        onWelcome: _openWelcome,
                        onAppearance: _openAppearance,
                        onSettings: _openSettings,
                        onAbout: _openAbout,
                        isMobile: false,
                      ),
                      statusBar: _StatusBar(game: widget.game),
                      body: _DesktopLayout(
                        game: widget.game,
                        settings: widget.settings,
                      ),
                    );

              // Welcome screen as a full-screen Stack overlay with AnimatedSwitcher
              return Stack(
                children: [
                  // Underlying scaffold is non-interactive while welcome is open.
                  IgnorePointer(
                    ignoring: _welcomeOpen,
                    child: ui,
                  ),
                  AnimatedSwitcher(
                    duration: AppDurations.base,
                    switchInCurve: AppCurves.easeOut,
                    switchOutCurve: AppCurves.easeOut,
                    child: _welcomeOpen
                        ? Positioned.fill(
                            key: const ValueKey('welcome-screen'),
                            child: WelcomeScreen(
                              onNewGame: () {
                                setState(() => _welcomeOpen = false);
                                _openNewGameDialog();
                              },
                              onSettings: () => _openAppearance(showBoardTheme: false),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty-welcome')),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.game,
    required this.onNewGame,
    required this.onWelcome,
    required this.onAppearance,
    required this.onSettings,
    required this.onAbout,
    required this.isMobile,
  });

  final GameController game;
  final VoidCallback onNewGame;
  final VoidCallback onWelcome;
  final VoidCallback onAppearance;
  final VoidCallback onSettings;
  final VoidCallback onAbout;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
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
            // Brand mark — knight + king silhouette tile.
            const GameLogo(size: 28),
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
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMuted.copyWith(
                  color: theme.palette.inkSoft,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (!isMobile) ...[
              AppButton(
                label: 'New game',
                size: AppButtonSize.small,
                leading: const IconPlus(),
                onPressed: onNewGame,
              ),
              const SizedBox(width: 4),
              AppButton(
                label: 'Start screen',
                variant: AppButtonVariant.subtle,
                size: AppButtonSize.small,
                onPressed: onWelcome,
              ),
              const SizedBox(width: 4),
              AppButton(
                label: 'Undo',
                variant: AppButtonVariant.subtle,
                size: AppButtonSize.small,
                onPressed: canUndo ? game.undo : null,
              ),
              const SizedBox(width: 4),
              AppButton(
                label: 'Flip',
                variant: AppButtonVariant.subtle,
                size: AppButtonSize.small,
                onPressed: game.flip,
              ),
              const SizedBox(width: 4),
              AppButton(
                label: 'Appearance',
                variant: AppButtonVariant.subtle,
                size: AppButtonSize.small,
                onPressed: onAppearance,
              ),
              const SizedBox(width: 4),
              AppButton(
                label: 'Settings',
                variant: AppButtonVariant.subtle,
                size: AppButtonSize.small,
                onPressed: onSettings,
              ),
              const SizedBox(width: 4),
              AppButton(
                label: 'About',
                variant: AppButtonVariant.subtle,
                size: AppButtonSize.small,
                onPressed: onAbout,
              ),
            ] else
              Row(
                children: [
                  AppButton(
                    label: 'Appearance',
                    variant: AppButtonVariant.subtle,
                    size: AppButtonSize.small,
                    onPressed: onAppearance,
                  ),
                  const SizedBox(width: 4),
                  AppButton(
                    label: 'Settings',
                    variant: AppButtonVariant.subtle,
                    size: AppButtonSize.small,
                    onPressed: onSettings,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Status bar
// ---------------------------------------------------------------------------

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
            Flexible(
              child: Wrap(
                spacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.end,
                children: [
                  _KbdChip('N', palette),
                  _StatusText(' new · ', palette),
                  _KbdChip('U', palette),
                  _StatusText(' undo · ', palette),
                  _KbdChip('F', palette),
                  _StatusText(' flip · ', palette),
                  _KbdChip('←', palette),
                  _StatusText('/', palette),
                  _KbdChip('→', palette),
                  _StatusText(' scrub · ', palette),
                  _KbdChip('Esc', palette),
                  _StatusText(' cancel', palette),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KbdChip extends StatelessWidget {
  const _KbdChip(this.key_, this.palette);
  final String key_;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 1, 5, 1),
      decoration: BoxDecoration(
        color: palette.bgCard,
        borderRadius: BorderRadius.circular(4),
        // Uniform border required for borderRadius; simulate thicker bottom
        // with a boxShadow offset downward (matches the Svelte kbd border-bottom: 2px).
        border: Border.all(color: palette.hairline, width: 1),
        boxShadow: [
          BoxShadow(
            color: palette.hairlineStrong,
            offset: const Offset(0, 1),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        key_,
        style: AppTextStyles.mono.copyWith(
          fontSize: 10,
          color: palette.inkSoft,
          height: 1.3,
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText(this.text, this.palette);
  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(color: palette.inkFaint),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop layout
// ---------------------------------------------------------------------------

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.game, required this.settings});

  final GameController game;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.bigGap),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Hide the move history panel when the window is too narrow to avoid
          // overflow — the panel reappears once there's enough room.
          final showPanel = constraints.maxWidth >= 860;
          final panelWidth = constraints.maxWidth >= 1000 ? 280.0 : 240.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BoardColumn(game: game, settings: settings),
              ),
              if (showPanel) ...[
                const SizedBox(width: AppSpacing.bigGap),
                SizedBox(
                  width: panelWidth,
                  child: MoveHistoryPanel(game: game),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile layout
// ---------------------------------------------------------------------------

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.game,
    required this.settings,
    required this.onOpenAppearance,
    required this.onOpenSettings,
    required this.onOpenNewGame,
    required this.onOpenWelcome,
    required this.onOpenAbout,
  });

  final GameController game;
  final SettingsController settings;
  final VoidCallback onOpenAppearance;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenNewGame;
  final VoidCallback onOpenWelcome;
  final VoidCallback onOpenAbout;

  void _openHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0x00000000),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
          child: MoveHistoryPanel(game: game),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _MinimalGameInfo(game: game, side: rust.Color.b),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Center(
              child: BoardWidget(game: game, settings: settings),
            ),
          ),
        ),
        _MinimalGameInfo(game: game, side: rust.Color.w),
      ],
    );

    return GameShell(
      title: 'Chess',
      topBarTrailing: _MinimalTurnIndicator(game: game),
      body: body,
      bottomBar: _IconActionsBar(
        game: game,
        onSettings: onOpenSettings,
        onNewGame: onOpenNewGame,
      ),
      drawerItemsBuilder: (closeDrawer) => [
        AppButton(
          label: 'Games Hub',
          variant: AppButtonVariant.ghost,
          leading: const IconLive(),
          fullWidth: true,
          onPressed: () {
            closeDrawer();
            onOpenWelcome();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'History',
          variant: AppButtonVariant.ghost,
          leading: const IconChevronRight(), // Placeholder for a history icon
          fullWidth: true,
          onPressed: () {
            closeDrawer();
            _openHistory(context);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Appearance',
          variant: AppButtonVariant.ghost,
          leading: const IconSettings(), // Using settings icon for appearance
          fullWidth: true,
          onPressed: () {
            closeDrawer();
            onOpenAppearance();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Settings',
          variant: AppButtonVariant.ghost,
          leading: const IconSettings(),
          fullWidth: true,
          onPressed: () {
            closeDrawer();
            onOpenSettings();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'About',
          variant: AppButtonVariant.ghost,
          leading: const IconInfo(),
          fullWidth: true,
          onPressed: () {
            closeDrawer();
            onOpenAbout();
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Board column (desktop) with scrub banner
// ---------------------------------------------------------------------------

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
        Expanded(
          child: ListenableBuilder(
            listenable: game,
            builder: (context, _) {
              final isAtLive = game.isAtLive;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // The board sizes itself via AspectRatio; the Stack fills
                  // the full Expanded height so the board is centered.
                  Center(child: BoardWidget(game: game, settings: settings)),
                  if (!isAtLive)
                    Positioned(
                      top: -34,
                      child: _ScrubBanner(onGoLive: game.scrubLive),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PlayerStrip(game: game, side: rust.Color.w, label: 'You'),
      ],
    );
  }
}

class _ScrubBanner extends StatelessWidget {
  const _ScrubBanner({required this.onGoLive});
  final VoidCallback onGoLive;

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.of(context).accent;
    // Approximates Svelte's color-mix(in oklab, var(--c-accent) 88%, black).
    final bg = Color.lerp(accent.base, const Color(0xFF000000), 0.12)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Viewing past position',
            style: TextStyle(
              fontFamily: AppFontFamilies.sans,
              fontSize: 12,
              color: accent.ink,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onGoLive,
            child: Text(
              '← back to live',
              style: TextStyle(
                fontFamily: AppFontFamilies.sans,
                fontSize: 12,
                color: const Color(0xFFD4A84B),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFFD4A84B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Minimal turn indicator (Mobile)
// ---------------------------------------------------------------------------

class _MinimalTurnIndicator extends StatelessWidget {
  const _MinimalTurnIndicator({required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    return ListenableBuilder(
      listenable: game,
      builder: (_, __) {
        final live = game.live;
        if (live == null || live.status != rust.GameStatus.active) {
          return const SizedBox.shrink();
        }
        
        final hc = live.humanColor;
        final turn = live.turn;
        final mode = live.mode;

        String label;
        if (mode == rust.GameMode.hvh) {
          label = turn == rust.Color.w ? 'White to move' : 'Black to move';
        } else {
          if (hc != null && turn == hc) {
            label = 'Your turn';
          } else {
            label = 'Opponent\'s turn';
          }
        }

        final color = turn == rust.Color.w ? const Color(0xFFF7EEDB) : const Color(0xFF1F1813);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: palette.bgCard,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: palette.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x33000000), width: 1),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: palette.ink, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Minimal game info (Mobile)
// ---------------------------------------------------------------------------

class _MinimalGameInfo extends StatelessWidget {
  const _MinimalGameInfo({required this.game, required this.side});
  final GameController game;
  final rust.Color side;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CapturesRow(game: game, side: side),
          ClockPanel(game: game, side: side),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Player strip (Desktop)
// ---------------------------------------------------------------------------

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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: ListenableBuilder(
        listenable: game,
        builder: (_, __) {
          final live = game.live;
          final mode = live?.mode ?? rust.GameMode.hvh;
          final hc = live?.humanColor;
          final isAi = mode == rust.GameMode.hva && hc != null && hc != side;
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
                    border:
                        Border.all(color: const Color(0x33000000), width: 1),
                  ),
                ),
                // Left portion wrapped in Flexible so it shrinks at narrow widths.
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          isAi ? 'Computer' : label,
                          style: AppTextStyles.body.copyWith(color: palette.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAi && live?.aiDifficulty != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.walnutDeep,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'AI · ${live!.aiDifficulty}',
                            style: AppTextStyles.badge.copyWith(
                              color: palette.bgElev,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                      if (thinking)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          child: Text(
                            'thinking…',
                            style: AppTextStyles.caption.copyWith(
                                color: palette.inkMute,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Icon Actions bar (Mobile)
// ---------------------------------------------------------------------------

class _IconActionsBar extends StatefulWidget {
  const _IconActionsBar({
    required this.game,
    required this.onSettings,
    required this.onNewGame,
  });

  final GameController game;
  final VoidCallback onSettings;
  final VoidCallback onNewGame;

  @override
  State<_IconActionsBar> createState() => _IconActionsBarState();
}

class _IconActionsBarState extends State<_IconActionsBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta != null) {
          if (details.primaryDelta! < -2) {
            setState(() => _expanded = true);
          } else if (details.primaryDelta! > 2) {
            setState(() => _expanded = false);
          }
        }
      },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.easeOut,
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            _expanded ? AppSpacing.md : AppSpacing.sm),
        decoration: BoxDecoration(
          color: palette.bgSoft,
          border: Border(top: BorderSide(color: palette.hairline, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: palette.inkFaint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
              ListenableBuilder(
                listenable: widget.game,
                builder: (_, __) {
                  final live = widget.game.live;
                  final canUndo = (live?.history.length ?? 0) > 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ActionIconButton(
                        label: 'New',
                        icon: const IconPlus(),
                        onPressed: widget.onNewGame,
                        expanded: _expanded,
                      ),
                      _ActionIconButton(
                        label: 'Undo',
                        icon: const IconUndo(),
                        onPressed: canUndo ? widget.game.undo : null,
                        expanded: _expanded,
                      ),
                      _ActionIconButton(
                        label: 'Flip',
                        icon: const IconFlip(),
                        onPressed: widget.game.flip,
                        expanded: _expanded,
                      ),
                      _ActionIconButton(
                        label: 'Prev',
                        icon: const IconChevronLeft(),
                        onPressed: () => widget.game.scrubStep(-1),
                        expanded: _expanded,
                      ),
                      _ActionIconButton(
                        label: 'Next',
                        icon: const IconChevronRight(),
                        onPressed: () => widget.game.scrubStep(1),
                        expanded: _expanded,
                      ),
                      _ActionIconButton(
                        label: 'Export',
                        icon: const IconUpload(),
                        onPressed: live == null
                            ? null
                            : () async {
                                final pgn = await widget.game.exportPgn();
                                if (!context.mounted) return;
                                await _showPgnDialog(context, pgn);
                              },
                        expanded: _expanded,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatefulWidget {
  const _ActionIconButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.expanded,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final palette = theme.palette;
    final accent = theme.accent;

    final bg = _hovered
        ? Color.alphaBlend(accent.mid.withValues(alpha: 0.12), palette.bgCard)
        : const Color(0x00000000);
    final fg = palette.ink;
    final borderColor = _hovered
        ? Color.alphaBlend(accent.mid.withValues(alpha: 0.40), palette.hairlineStrong)
        : palette.hairlineStrong;

    final translateY = (_enabled && _hovered && !_pressed) ? -1.0 : 0.0;

    final body = AnimatedScale(
      scale: (_pressed && _enabled) ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.easeOut,
        transform: Matrix4.translationValues(0, translateY, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(color: fg, size: 16),
              child: widget.icon,
            ),
            AnimatedSize(
              duration: AppDurations.fast,
              curve: AppCurves.easeOut,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: AppDurations.fast,
                switchInCurve: AppCurves.easeOut,
                switchOutCurve: AppCurves.easeOut,
                child: widget.expanded
                    ? Padding(
                        key: const ValueKey('expanded-label'),
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.label,
                          style: AppTextStyles.caption.copyWith(color: fg, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('collapsed-label')),
              ),
            ),
          ],
        ),
      ),
    );

    return Opacity(
      opacity: _enabled ? 1.0 : 0.5,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        onEnter: (_) {
          if (_enabled) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (_enabled) {
            setState(() {
              _hovered = false;
              _pressed = false;
            });
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: _enabled
              ? (_) {
                  setState(() => _pressed = false);
                  widget.onPressed?.call();
                }
              : null,
          child: body,
        ),
      ),
    );
  }
}

Future<void> _showPgnDialog(BuildContext context, String pgn) async {
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

// ---------------------------------------------------------------------------
// Keyboard intents
// ---------------------------------------------------------------------------

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
