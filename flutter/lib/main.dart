import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'src/app.dart';
import 'src/rust/api.dart' as rust;
import 'src/rust/frb_generated.dart';
import 'src/state/game_controller.dart';
import 'src/state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  final dir = await getApplicationSupportDirectory();
  rust.bridgeInit(dataDir: dir.path);

  final settings = SettingsController();
  await settings.init();

  final game = GameController();
  await game.init();

  runApp(ChessApp(game: game, settings: settings));
}
