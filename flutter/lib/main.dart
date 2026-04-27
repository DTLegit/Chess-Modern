import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'src/app.dart';
import 'src/bridge/stockfish_setup.dart';
import 'src/rust/api.dart' as rust;
import 'src/rust/frb_generated.dart';
import 'src/state/game_controller.dart';
import 'src/state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  final dir = await getApplicationSupportDirectory();
  rust.bridgeInit(dataDir: dir.path);

  // Android: extract the bundled Stockfish binary so AI levels 4-10
  // use the real engine. iOS: no-op (sandbox forbids spawning child
  // processes; the AI module falls back to the strongest custom-engine
  // tier per `fallback_custom_level`).
  await setupAndroidStockfish();

  final settings = SettingsController();
  await settings.init();

  final game = GameController();
  await game.init();

  runApp(ChessApp(game: game, settings: settings));
}
