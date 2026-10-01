import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'offline_audio_generator.dart';

enum SoothingSoundType {
  none,
  lullaby,
  whiteNoise,
  rain,
  ocean,
}

class SoothingSoundPlayer {
  final AudioPlayer _player = AudioPlayer();
  SoothingSoundType _currentSound = SoothingSoundType.none;
  Timer? _sleepTimer;
  int _remainingSeconds = 0;

  bool get isPlaying => _currentSound != SoothingSoundType.none;
  SoothingSoundType get currentSound => _currentSound;
  int get remainingMinutes => (_remainingSeconds / 60).ceil();

  final ValueNotifier<bool> playStateNotifier = ValueNotifier<bool>(false);

  SoothingSoundPlayer() {
    _player.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> play(SoothingSoundType soundType) async {
    if (soundType == SoothingSoundType.none) {
      await stop();
      return;
    }

    _currentSound = soundType;
    playStateNotifier.value = true;

    try {
      String? filePath;
      switch (soundType) {
        case SoothingSoundType.lullaby:
          filePath = await OfflineAudioGenerator.getLullabyFile();
          break;
        case SoothingSoundType.whiteNoise:
          filePath = await OfflineAudioGenerator.getWhiteNoiseFile();
          break;
        case SoothingSoundType.rain:
          filePath = await OfflineAudioGenerator.getRainFile();
          break;
        case SoothingSoundType.ocean:
          filePath = await OfflineAudioGenerator.getOceanFile();
          break;
        case SoothingSoundType.none:
          break;
      }

      if (filePath != null) {
        await _player.stop();
        await _player.play(DeviceFileSource(filePath));
        debugPrint('Playing offline soothing sound: $soundType ($filePath)');
      }
    } catch (e) {
      debugPrint('Error playing offline sound $soundType: $e');
    }
  }

  void setTimer(int minutes) {
    _sleepTimer?.cancel();
    _remainingSeconds = minutes * 60;

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
      } else {
        stop();
        timer.cancel();
      }
    });
  }

  Future<void> stop() async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _remainingSeconds = 0;
    _currentSound = SoothingSoundType.none;
    playStateNotifier.value = false;
    try {
      await _player.stop();
    } catch (_) {}
  }

  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
  }
}
