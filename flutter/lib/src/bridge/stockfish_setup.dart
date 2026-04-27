import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../rust/api.dart' as rust;

/// Android-specific bring-up: extract the per-ABI Stockfish binary out
/// of the APK assets, chmod 0755 it, and register the path with the
/// Rust bridge. Returns the path on success, or `null` if no Stockfish
/// asset is bundled (in which case the AI module falls back to the
/// custom Rust engine).
Future<String?> setupAndroidStockfish() async {
  if (!Platform.isAndroid) return null;

  final abi = _detectAbi();
  if (abi == null) {
    debugPrint('stockfish: unrecognised abi, skipping setup');
    return null;
  }
  final assetPath = 'assets/stockfish/$abi/stockfish';

  ByteData asset;
  try {
    asset = await rootBundle.load(assetPath);
  } catch (_) {
    debugPrint('stockfish: no asset at $assetPath, falling back to custom engine');
    return null;
  }

  final dir = await getApplicationSupportDirectory();
  final outFile = File('${dir.path}/stockfish');
  await outFile.writeAsBytes(
    asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
    flush: true,
  );
  // chmod +x
  try {
    await Process.run('chmod', ['0755', outFile.path]);
  } catch (e) {
    debugPrint('stockfish: chmod failed: $e');
  }

  try {
    rust.bridgeProvideExternalStockfish(binaryPath: outFile.path);
    return outFile.path;
  } catch (e) {
    debugPrint('stockfish: bridge install failed: $e');
    return null;
  }
}

String? _detectAbi() {
  // Flutter doesn't expose the running ABI directly. We use the standard
  // Android `Build.SUPPORTED_ABIS[0]` via a small platform channel; until
  // we add that channel, we infer from the operating-system version
  // bytes shipped with the Dart VM. This list mirrors the ABIs we
  // produce in scripts/build-stockfish-android.sh.
  if (!Platform.isAndroid) return null;
  // dart:io exposes `Abi.current()` since Dart 2.16 which matches the
  // ABI Flutter is built for.
  switch (Abi.current()) {
    case Abi.androidArm64:
      return 'arm64-v8a';
    case Abi.androidArm:
      return 'armeabi-v7a';
    case Abi.androidX64:
      return 'x86_64';
    default:
      return null;
  }
}
