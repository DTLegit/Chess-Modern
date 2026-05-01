import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/cupertino.dart' show DefaultCupertinoLocalizations;
import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';

import 'state/game_controller.dart';
import 'state/settings_controller.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'theme/typography.dart';
import 'ui/home_screen.dart';

/// Ambient background with a subtle radial-gradient paper/noise texture.
/// Mirrors Svelte's `--c-bg` ambient grain layers from `app.css`.
class _AppBackground extends StatelessWidget {
  const _AppBackground({required this.palette, required this.child});
  final AppPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLight = palette.brightness == Brightness.light;
    return AnimatedContainer(
      duration: AppDurations.base,
      curve: AppCurves.easeOut,
      color: palette.bg,
      child: Stack(
        children: [
          // Subtle radial ambient: brightens center slightly.
          Positioned.fill(
            child: AnimatedContainer(
              duration: AppDurations.base,
              curve: AppCurves.easeOut,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.3),
                  radius: 1.2,
                  colors: [
                    isLight
                        ? const Color(0x0FFFFFFF)
                        : const Color(0x08FFFFFF),
                    const Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),
          // Vignette: darkens edges slightly.
          Positioned.fill(
            child: AnimatedContainer(
              duration: AppDurations.base,
              curve: AppCurves.easeOut,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.5,
                  colors: [
                    const Color(0x00000000),
                    isLight
                        ? const Color(0x08000000)
                        : const Color(0x14000000),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class ChessApp extends StatelessWidget {
  const ChessApp({
    super.key,
    required this.game,
    required this.settings,
  });

  final GameController game;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            final themeData = AppThemeData.fromSettings(
              settings.value,
              lightDynamic: lightDynamic,
              darkDynamic: darkDynamic,
              platformBrightness: MediaQuery.platformBrightnessOf(context),
            );
            return WidgetsApp(
              title: 'Chess',
              color: themeData.palette.bg,
              // Default page transition: 180ms fade matching Svelte modal/route motion.
              pageRouteBuilder: <T>(RouteSettings rsettings, WidgetBuilder builder) {
                return PageRouteBuilder<T>(
                  settings: rsettings,
                  transitionDuration: AppDurations.base,
                  reverseTransitionDuration: AppDurations.fast,
                  pageBuilder: (ctx, anim, secondary) => builder(ctx),
                  transitionsBuilder: (_, anim, __, child) {
                    return FadeTransition(
                      opacity: CurvedAnimation(parent: anim, curve: AppCurves.easeOut),
                      child: child,
                    );
                  },
                );
              },
              localizationsDelegates: const [
                DefaultMaterialLocalizations.delegate,
                DefaultWidgetsLocalizations.delegate,
                DefaultCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return AppTheme(
                  data: themeData,
                  child: AnimatedDefaultTextStyle(
                    duration: AppDurations.base,
                    curve: AppCurves.easeOut,
                    style: AppTextStyles.body.copyWith(color: themeData.palette.ink),
                    child: _AppBackground(
                      palette: themeData.palette,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              },
              home: HomeScreen(game: game, settings: settings),
            );
          },
        );
      }
    );
  }
}
