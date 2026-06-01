import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription? _subscription;
  final Function(String base64) onData;
  final Function(List<double> frequencies) onFrequencies;

  AudioRecorderService({required this.onData, required this.onFrequencies});

  Future<void> start() async {
    if (await _recorder.hasPermission()) {
      final config = const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      );

      final stream = await _recorder.startStream(config);
      
      _subscription = stream.listen((data) {
        // Enhance Mic: Apply software gain boost (x1.5)
        final enhancedData = _applyGain(data, 1.5);
        
        onData(base64Encode(enhancedData));
        onFrequencies(_calculateFrequencies(enhancedData));
      });
    }
  }

  Uint8List _applyGain(Uint8List data, double gain) {
    final Int16List samples = Int16List.view(data.buffer);
    final Int16List result = Int16List(samples.length);
    
    for (int i = 0; i < samples.length; i++) {
      int value = (samples[i] * gain).round();
      // Clamp to Int16 limits
      if (value > 32767) value = 32767;
      if (value < -32768) value = -32768;
      result[i] = value;
    }
    
    return Uint8List.view(result.buffer);
  }

  List<double> _calculateFrequencies(Uint8List data) {
    final List<double> bins = List.filled(11, 0.0);
    if (data.isEmpty) return bins;

    final int samplesPerBin = (data.length / 2 / 11).floor();
    if (samplesPerBin == 0) return bins;

    final view = ByteData.view(data.buffer);
    
    for (int i = 0; i < 11; i++) {
      double sum = 0;
      for (int j = 0; j < samplesPerBin; j++) {
        final index = (i * samplesPerBin + j) * 2;
        if (index + 1 < data.length) {
          final sample = view.getInt16(index, Endian.little).abs();
          sum += sample / 32768.0;
        }
      }
      bins[i] = (sum / samplesPerBin).clamp(0.0, 1.0);
    }
    return bins;
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    await _recorder.stop();
  }

  void dispose() {
    _recorder.dispose();
  }
}
