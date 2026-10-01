import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class OfflineAudioGenerator {
  static const int sampleRate = 22050; // 22.05 kHz is optimal for size and soothing audio

  static Uint8List _createWavHeader(int numSamples, int sampleRate) {
    final int byteRate = sampleRate * 2; // 16-bit mono
    final int dataSize = numSamples * 2;
    final int fileSize = 36 + dataSize;

    final header = ByteData(44);
    // "RIFF"
    header.setUint8(0, 0x52);
    header.setUint8(1, 0x49);
    header.setUint8(2, 0x46);
    header.setUint8(3, 0x46);
    header.setUint32(4, fileSize, Endian.little);
    // "WAVE"
    header.setUint8(8, 0x57);
    header.setUint8(9, 0x41);
    header.setUint8(10, 0x56);
    header.setUint8(11, 0x45);
    // "fmt "
    header.setUint8(12, 0x66);
    header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74);
    header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    header.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    header.setUint32(24, sampleRate, Endian.little); // SampleRate
    header.setUint32(28, byteRate, Endian.little);   // ByteRate
    header.setUint16(32, 2, Endian.little);  // BlockAlign (2 bytes for 16-bit mono)
    header.setUint16(34, 16, Endian.little); // BitsPerSample
    // "data"
    header.setUint8(36, 0x64);
    header.setUint8(37, 0x61);
    header.setUint8(38, 0x74);
    header.setUint8(39, 0x61);
    header.setUint32(40, dataSize, Endian.little);

    return header.buffer.asUint8List();
  }

  // 1. Synthesize Brahm's Lullaby (Music Box / Bell tone)
  static Future<String> getLullabyFile() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/lullaby_sound.wav');
    if (await file.exists() && (await file.length()) > 1000) {
      return file.path;
    }

    // Melody: Notes and durations in beats
    // Brahms Lullaby: F4, F4, A4, F4, F4, A4, F4, A4, C5, Bb4, Bb4, A4, G4...
    final notes = [
      // note freq in Hz, duration in seconds
      [349.23, 0.6], [349.23, 0.6], [440.00, 1.2], // F4, F4, A4
      [349.23, 0.6], [349.23, 0.6], [440.00, 1.4], // F4, F4, A4
      [349.23, 0.4], [440.00, 0.4], [523.25, 0.8], [466.16, 0.6], [440.00, 0.6], [392.00, 1.2], // F4, A4, C5, Bb4, A4, G4
      [329.63, 0.6], [349.23, 0.6], [392.00, 1.2], // E4, F4, G4
      [329.63, 0.6], [349.23, 0.6], [392.00, 1.4], // E4, F4, G4
      [392.00, 0.4], [440.00, 0.4], [466.16, 0.6], [523.25, 0.6], [440.00, 0.6], [349.23, 1.4], // G4, A4, Bb4, C5, A4, F4
    ];

    int totalSamples = 0;
    for (var note in notes) {
      totalSamples += (note[1] * sampleRate).toInt();
    }

    final pcmData = Int16List(totalSamples);
    int currentSample = 0;

    for (var note in notes) {
      final double freq = note[0];
      final int noteSamples = (note[1] * sampleRate).toInt();

      for (int i = 0; i < noteSamples; i++) {
        final double t = i / sampleRate;
        // Music box envelope: fast attack, exponential decay
        final double envelope = exp(-3.0 * t);
        // Fundamental + soft bell harmonic (2x and 3x frequency)
        final double sample = (sin(2 * pi * freq * t) * 0.7 +
                               sin(2 * pi * freq * 2 * t) * 0.2 +
                               sin(2 * pi * freq * 3 * t) * 0.1) * envelope;
        
        final int intVal = (sample * 24000).clamp(-32768, 32767).toInt();
        if (currentSample < totalSamples) {
          pcmData[currentSample++] = intVal;
        }
      }
    }

    final header = _createWavHeader(totalSamples, sampleRate);
    final bytes = BytesBuilder()
      ..add(header)
      ..add(pcmData.buffer.asUint8List());

    await file.writeAsBytes(bytes.toBytes());
    return file.path;
  }

  // 2. Synthesize Calming White / Pink Noise
  static Future<String> getWhiteNoiseFile() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/white_noise.wav');
    if (await file.exists() && (await file.length()) > 1000) {
      return file.path;
    }

    final int durationSeconds = 8; // 8s loop
    final int totalSamples = durationSeconds * sampleRate;
    final pcmData = Int16List(totalSamples);
    final random = Random();

    // Brownian/Pink noise filtering for warm soothing sound
    double b0 = 0, b1 = 0, b2 = 0;
    for (int i = 0; i < totalSamples; i++) {
      final double white = (random.nextDouble() * 2.0 - 1.0);
      b0 = 0.99 * b0 + white * 0.05;
      b1 = 0.96 * b1 + white * 0.11;
      b2 = 0.86 * b2 + white * 0.25;
      final double pink = (b0 + b1 + b2) * 0.35;
      pcmData[i] = (pink * 22000).clamp(-32768, 32767).toInt();
    }

    final header = _createWavHeader(totalSamples, sampleRate);
    final bytes = BytesBuilder()
      ..add(header)
      ..add(pcmData.buffer.asUint8List());

    await file.writeAsBytes(bytes.toBytes());
    return file.path;
  }

  // 3. Synthesize Gentle Rain Sounds
  static Future<String> getRainFile() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/rain_sound.wav');
    if (await file.exists() && (await file.length()) > 1000) {
      return file.path;
    }

    final int durationSeconds = 8;
    final int totalSamples = durationSeconds * sampleRate;
    final pcmData = Int16List(totalSamples);
    final random = Random();

    double lowPass = 0;
    for (int i = 0; i < totalSamples; i++) {
      final double white = (random.nextDouble() * 2.0 - 1.0);
      lowPass = 0.92 * lowPass + 0.08 * white;
      
      // Random raindrops
      double drop = 0;
      if (random.nextDouble() < 0.003) {
        drop = (random.nextDouble() - 0.5) * 0.4;
      }
      
      final double val = (lowPass * 0.8 + drop) * 0.7;
      pcmData[i] = (val * 24000).clamp(-32768, 32767).toInt();
    }

    final header = _createWavHeader(totalSamples, sampleRate);
    final bytes = BytesBuilder()
      ..add(header)
      ..add(pcmData.buffer.asUint8List());

    await file.writeAsBytes(bytes.toBytes());
    return file.path;
  }

  // 4. Synthesize Ocean Waves
  static Future<String> getOceanFile() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ocean_sound.wav');
    if (await file.exists() && (await file.length()) > 1000) {
      return file.path;
    }

    final int durationSeconds = 10;
    final int totalSamples = durationSeconds * sampleRate;
    final pcmData = Int16List(totalSamples);
    final random = Random();

    double lowPass = 0;
    for (int i = 0; i < totalSamples; i++) {
      final double t = i / sampleRate;
      // Ocean wave swell cycle every ~5 seconds
      final double swell = 0.35 + 0.65 * pow(sin(2 * pi * t / 5.0).abs(), 1.5);
      final double white = (random.nextDouble() * 2.0 - 1.0);
      lowPass = 0.94 * lowPass + 0.06 * white;

      final double val = lowPass * swell * 0.9;
      pcmData[i] = (val * 26000).clamp(-32768, 32767).toInt();
    }

    final header = _createWavHeader(totalSamples, sampleRate);
    final bytes = BytesBuilder()
      ..add(header)
      ..add(pcmData.buffer.asUint8List());

    await file.writeAsBytes(bytes.toBytes());
    return file.path;
  }
}
