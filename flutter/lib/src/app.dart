import 'package:flutter/cupertino.dart' show DefaultCupertinoLocalizations;
import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';

import 'state/game_controller.dart';
import 'state/settings_controller.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'theme/typography.dart';
import 'ui/home_screen.dart';

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
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final themeData = AppThemeData.fromSettings(settings.value);
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
              child: DefaultTextStyle(
                style: AppTextStyles.body.copyWith(color: themeData.palette.ink),
                child: ColoredBox(
                  color: themeData.palette.bg,
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
}
