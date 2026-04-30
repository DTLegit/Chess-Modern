import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../state/settings_controller.dart';
import 'sound_kind.dart';

/// Procedural sound module — port of `legacy/svelte/lib/audio/synth.ts`.
/// Each sound is rendered to a small PCM WAV in memory and played via
/// `audioplayers`. Re-uses the same per-kind voicings as the WebAudio
/// version (woody clicks for moves/captures/castle, chord for check/end,
/// shimmer for promote).
class SoundSynth {
  SoundSynth(this._settings);

  final SettingsController _settings;
  final _player = AudioPlayer();

  // WAV bytes cache (full volume; volume applied at play time via setVolume).
  final _wavCache = <SoundKind, Uint8List>{};

  // Temp-file paths written once per session for macOS-sandbox compatibility.
  // BytesSource can fail in the macOS sandbox; DeviceFileSource works reliably.
  final _fileCache = <SoundKind, String>{};
  String? _tempDir;

  static const _sampleRate = 22_050;

  Future<void> _ensureTempDir() async {
    if (_tempDir != null) return;
    final dir = await getTemporaryDirectory();
    _tempDir = dir.path;
    // On macOS in the App Sandbox the caches directory may not exist yet.
    await Directory(_tempDir!).create(recursive: true);
  }

  Future<void> play(SoundKind kind) async {
    final s = _settings.value;
    if (!s.soundEnabled) return;
    final v = s.soundVolume.clamp(0.0, 1.0);
    if (v <= 0) return;

    try {
      final wav = _wavCache.putIfAbsent(kind, () => _renderWav(kind));

      await _ensureTempDir();
      String? filePath = _fileCache[kind];
      if (filePath == null) {
        filePath = '$_tempDir/chess_sfx_${kind.name}.wav';
        await File(filePath).writeAsBytes(wav);
        _fileCache[kind] = filePath;
      }

      if (Platform.isMacOS) {
        // afplay is a built-in macOS utility that reliably plays audio files
        // without App Sandbox restrictions that affect audioplayers on macOS.
        final proc = await Process.start(
          '/usr/bin/afplay',
          ['-v', v.toStringAsFixed(2), filePath],
        );
        // Fire-and-forget: don't block the UI thread waiting for playback.
        unawaited(proc.exitCode);
      } else {
        await _player.stop();
        await _player.setVolume(v);
        await _player.play(DeviceFileSource(filePath));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SoundSynth.play failed: $e');
    }
  }

  // Renders at mix-appropriate relative levels; master volume applied via
  // AudioPlayer.setVolume() at play time so the cache stays volume-agnostic.
  Uint8List _renderWav(SoundKind kind) {
    final samples = switch (kind) {
      SoundKind.move => _woodClick(0.85, 220, 0.16),
      SoundKind.capture => _stack([
          _woodClick(1.0, 150, 0.22),
          _delayed(_woodClick(0.45, 320, 0.08), 0.018),
        ], 0.32),
      SoundKind.castle => _stack([
          _woodClick(0.9, 200, 0.18),
          _delayed(_woodClick(0.7, 260, 0.14), 0.07),
        ], 0.32),
      SoundKind.check => _chord(0.55, const [660, 880, 1100], 0.32),
      SoundKind.promote => _shimmer(0.6),
      SoundKind.end => _chord(0.6, const [392, 523, 659, 784], 0.9),
    };
    return _pcmToWav(samples);
  }

  // ---------------- voicings -----------------------------------------

  Float32List _woodClick(double volume, double pitch, double duration) {
    final n = (_sampleRate * (duration + 0.05)).toInt();
    final out = Float32List(n);
    final rng = math.Random(0xCAFE);
    for (var i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final env = math.exp(-t / (duration * 0.4));
      final freq = pitch * (0.5 + 0.5 * math.exp(-t / duration));
      var s = math.sin(2 * math.pi * freq * t) * 0.6 * env;
      if (t < 0.03) {
        final nEnv = 1 - (t / 0.03);
        final noise = (rng.nextDouble() * 2 - 1) * 0.55 * nEnv;
        s += noise;
      }
      out[i] = (s * volume).clamp(-1.0, 1.0);
    }
    return out;
  }

  Float32List _chord(double volume, List<num> freqs, double duration) {
    final n = (_sampleRate * (duration + 0.05)).toInt();
    final out = Float32List(n);
    for (var i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final env = math.exp(-t / (duration * 0.5));
      var s = 0.0;
      for (final f in freqs) {
        s += math.sin(2 * math.pi * f.toDouble() * t);
      }
      s *= 0.4 / freqs.length * env;
      out[i] = (s * volume).clamp(-1.0, 1.0);
    }
    return out;
  }

  Float32List _shimmer(double volume) {
    const duration = 0.4;
    final n = (_sampleRate * (duration + 0.05)).toInt();
    final out = Float32List(n);
    for (var i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final env = math.exp(-t / (duration * 0.4));
      final freq = 880 + (1320 - 880) * math.min(1.0, t / 0.18);
      out[i] = (math.sin(2 * math.pi * freq * t) * 0.45 * env * volume)
          .clamp(-1.0, 1.0);
    }
    return out;
  }

  Float32List _stack(List<Float32List> tracks, double duration) {
    final n = (_sampleRate * duration).toInt();
    final out = Float32List(n);
    for (final t in tracks) {
      final m = math.min(n, t.length);
      for (var i = 0; i < m; i++) {
        out[i] = (out[i] + t[i]).clamp(-1.0, 1.0);
      }
    }
    return out;
  }

  Float32List _delayed(Float32List src, double seconds) {
    final shift = (_sampleRate * seconds).toInt();
    final out = Float32List(src.length + shift);
    for (var i = 0; i < src.length; i++) {
      out[i + shift] = src[i];
    }
    return out;
  }

  Uint8List _pcmToWav(Float32List samples) {
    final byteRate = _sampleRate * 2;
    final dataSize = samples.length * 2;
    final fileSize = 44 + dataSize;
    final bytes = BytesBuilder();

    void writeInt32(int v) =>
        bytes.add(Uint8List(4)..buffer.asByteData().setInt32(0, v, Endian.little));
    void writeInt16(int v) =>
        bytes.add(Uint8List(2)..buffer.asByteData().setInt16(0, v, Endian.little));

    bytes.add('RIFF'.codeUnits);
    writeInt32(fileSize - 8);
    bytes.add('WAVE'.codeUnits);
    bytes.add('fmt '.codeUnits);
    writeInt32(16);
    writeInt16(1); // PCM
    writeInt16(1); // mono
    writeInt32(_sampleRate);
    writeInt32(byteRate);
    writeInt16(2); // block align
    writeInt16(16); // bits per sample
    bytes.add('data'.codeUnits);
    writeInt32(dataSize);

    final pcm = ByteData(dataSize);
    for (var i = 0; i < samples.length; i++) {
      final s = (samples[i] * 32767).round().clamp(-32768, 32767);
      pcm.setInt16(i * 2, s, Endian.little);
    }
    bytes.add(pcm.buffer.asUint8List());
    return bytes.toBytes();
  }
}
