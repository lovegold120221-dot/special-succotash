import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

class AudioStreamerService {
  FlutterSoundPlayer? _player;
  final int sampleRate;
  double _currentVolume = 1.0;

  AudioStreamerService({this.sampleRate = 24000});

  Future<void> init() async {
    _player = FlutterSoundPlayer();
    await _player!.openPlayer();
    await _player!.setSubscriptionDuration(const Duration(milliseconds: 10));
  }

  Future<void> start() async {
    if (_player == null) await init();
    _currentVolume = 1.0;
    await _player!.setVolume(_currentVolume);
    
    await _player!.startPlayerFromStream(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: sampleRate,
      bufferSize: 2048,
      interleaved: true,
    );
  }

  void addPCM16(String base64) async {
    if (_player == null || !_player!.isPlaying) return;
    
    final bytes = base64Decode(base64);
    await _player!.feedUint8FromStream(Uint8List.fromList(bytes));
  }

  Future<void> stop() async {
    if (_player != null) {
      await _player!.stopPlayer();
    }
  }

  /// Implements a robust "soft stop" to handle interruptions gracefully.
  /// Ramps volume down over 150ms before stopping to avoid harsh clicks.
  Future<void> stopWithFade() async {
    if (_player == null || !_player!.isPlaying) return;

    final int steps = 8;
    final int stepDurationMs = 20;
    final double volumeStep = _currentVolume / steps;

    for (int i = 0; i < steps; i++) {
      _currentVolume = (_currentVolume - volumeStep).clamp(0.0, 1.0);
      await _player!.setVolume(_currentVolume);
      await Future.delayed(Duration(milliseconds: stepDurationMs));
    }

    await stop();
  }

  Future<void> dispose() async {
    await stop();
    if (_player != null) {
      await _player!.closePlayer();
      _player = null;
    }
  }
}
