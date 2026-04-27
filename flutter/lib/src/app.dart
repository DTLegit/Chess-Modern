import 'package:flutter/material.dart';

import 'state/game_controller.dart';
import 'state/settings_controller.dart';
import 'theme/app_theme.dart';
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
        final theme = ChessThemeBuilder.of(settings.value);
        return MaterialApp(
          title: 'Chess',
          theme: theme.material,
          darkTheme: theme.material,
          themeMode: theme.brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: HomeScreen(game: game, settings: settings),
        );
      },
    );
  }
}
