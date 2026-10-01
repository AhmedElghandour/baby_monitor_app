import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:torch_light/torch_light.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audioplayers/audioplayers.dart';

import 'soothing_sound_player.dart';

typedef SendMessageCallback = void Function(String clientId, String message);

enum StreamQuality {
  fullHd,  // 1080p
  hd,      // 720p
  saver,   // 480p
}

class StreamManager {
  MediaStream? _localStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  
  final Map<String, RTCPeerConnection> _peerConnections = {};
  SendMessageCallback? onSendMessage;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isTorchOn = false;
  bool get isTorchOn => _isTorchOn;

  String _currentFacing = 'back';
  String get currentFacing => _currentFacing;

  StreamQuality currentQuality = StreamQuality.hd;

  bool _isNightMode = false;
  bool get isNightMode => _isNightMode;
  VoidCallback? onNightModeToggled;

  // Security PIN
  bool isPinEnabled = false;
  String pinCode = '1234';

  // Two-way Audio & Sound Player
  final SoothingSoundPlayer soundPlayer = SoothingSoundPlayer();
  final AudioPlayer _intercomPlayer = AudioPlayer();
  final ValueNotifier<bool> isIntercomTalking = ValueNotifier<bool>(false);

  final Battery _battery = Battery();
  int _batteryLevel = 100;
  bool _isCharging = false;
  StreamSubscription<BatteryState>? _batteryStateSub;
  Timer? _batteryPollTimer;

  final ValueNotifier<int> activeViewersCount = ValueNotifier<int>(0);

  Future<void> initialize() async {
    if (_isInitialized) return;

    await localRenderer.initialize();
    await WakelockPlus.enable();
    await Helper.setSpeakerphoneOn(true);

    await _startCameraStream();
    await _initBatteryMonitor();

    _isInitialized = true;
  }

  Future<void> _startCameraStream() async {
    int width = 1280;
    int height = 720;
    int maxBitrate = 1500;
    if (currentQuality == StreamQuality.fullHd) {
      width = 1920;
      height = 1080;
      maxBitrate = 2500;
    } else if (currentQuality == StreamQuality.saver) {
      width = 854;
      height = 480;
      maxBitrate = 700;
    }

    final Map<String, dynamic> mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': {
        'mandatory': {
          'minWidth': '$width',
          'maxWidth': '$width',
          'minHeight': '$height',
          'maxHeight': '$height',
          'minFrameRate': '24',
          'maxFrameRate': '30',
        },
        'facingMode': _currentFacing == 'front' ? 'user' : 'environment',
        'optional': [
          {'maxBitrate': '$maxBitrate'},
        ],
      }
    };

    try {
      if (_localStream != null) {
        await _localStream!.dispose();
      }
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;
    } catch (e) {
      debugPrint('Camera access fallback: $e');
      final Map<String, dynamic> fallbackConstraints = {
        'audio': true,
        'video': true,
      };
      _localStream = await navigator.mediaDevices.getUserMedia(fallbackConstraints);
      localRenderer.srcObject = _localStream;
    }
  }

  Future<void> setQuality(StreamQuality quality) async {
    if (currentQuality == quality) return;
    currentQuality = quality;
    await _startCameraStream();
    if (_localStream != null) {
      for (final pc in _peerConnections.values) {
        final senders = await pc.getSenders();
        final videoTrack = _localStream!.getVideoTracks().firstOrNull;
        if (videoTrack != null) {
          final videoSender = senders.firstWhere(
            (s) => s.track?.kind == 'video',
            orElse: () => senders.first,
          );
          await videoSender.replaceTrack(videoTrack);
        }
      }
    }
    broadcastStateUpdate();
  }

  Future<void> _initBatteryMonitor() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      _isCharging = (state == BatteryState.charging || state == BatteryState.full);

      _batteryStateSub = _battery.onBatteryStateChanged.listen((state) async {
        _isCharging = (state == BatteryState.charging || state == BatteryState.full);
        _batteryLevel = await _battery.batteryLevel;
        broadcastStateUpdate();
      });

      _batteryPollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        try {
          _batteryLevel = await _battery.batteryLevel;
          broadcastStateUpdate();
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Battery monitor error: $e');
    }
  }

  bool verifyPin(String pin) {
    if (!isPinEnabled) return true;
    return pin == pinCode;
  }

  // Play incoming push-to-talk voice from parent with automatic mic-ducking to prevent echo
  Future<void> playIntercomVoice(Uint8List audioBytes) async {
    try {
      isIntercomTalking.value = true;

      // Temporarily duck/mute host microphone so phone's speaker doesn't feed back into stream
      final audioTracks = _localStream?.getAudioTracks();
      if (audioTracks != null) {
        for (var track in audioTracks) {
          track.enabled = false;
        }
      }

      await Helper.setSpeakerphoneOn(true);
      await _intercomPlayer.stop();
      await _intercomPlayer.play(BytesSource(audioBytes));

      _intercomPlayer.onPlayerComplete.first.then((_) {
        Timer(const Duration(milliseconds: 500), () {
          if (audioTracks != null) {
            for (var track in audioTracks) {
              track.enabled = true;
            }
          }
          isIntercomTalking.value = false;
        });
      });
    } catch (e) {
      debugPrint('Error playing intercom voice: $e');
      final audioTracks = _localStream?.getAudioTracks();
      if (audioTracks != null) {
        for (var track in audioTracks) {
          track.enabled = true;
        }
      }
      isIntercomTalking.value = false;
    }
  }

  // Handle a new web client connection requesting an offer
  Future<void> handleClientReady(String clientId) async {
    if (_localStream == null) {
      await _startCameraStream();
    }

    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ],
      'sdpSemantics': 'unified-plan'
    };

    final pc = await createPeerConnection(configuration);
    _peerConnections[clientId] = pc;
    _updateViewersCount();

    // Add local media tracks to peer connection
    for (var track in _localStream!.getTracks()) {
      await pc.addTrack(track, _localStream!);
    }

    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (onSendMessage != null) {
        onSendMessage!(
          clientId,
          jsonEncode({
            'type': 'candidate',
            'candidate': {
              'sdpMLineIndex': candidate.sdpMLineIndex,
              'sdpMid': candidate.sdpMid,
              'candidate': candidate.candidate,
            }
          }),
        );
      }
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('Peer [$clientId] connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        removeClient(clientId);
      }
    };

    pc.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'audio') {
        debugPrint('Real-time audio track received from parent');
        Helper.setSpeakerphoneOn(true);
        isIntercomTalking.value = true;
      }
    };

    final offer = await pc.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    
    // Low-latency SDP tuning: optimize start and max bitrates to prevent buffer bloat
    String sdp = offer.sdp ?? '';
    sdp = sdp.replaceAll(
      'a=mid:video\r\n',
      'a=mid:video\r\nb=AS:2000\r\n',
    );
    final tunedOffer = RTCSessionDescription(sdp, offer.type);
    await pc.setLocalDescription(tunedOffer);

    if (onSendMessage != null) {
      onSendMessage!(
        clientId,
        jsonEncode({
          'type': 'offer',
          'offer': {
            'sdp': tunedOffer.sdp,
            'type': tunedOffer.type,
          }
        }),
      );
    }

    sendStateUpdateToClient(clientId);
  }

  Future<void> handleAnswer(String clientId, Map<String, dynamic> answerData) async {
    final pc = _peerConnections[clientId];
    if (pc != null) {
      final description = RTCSessionDescription(
        answerData['sdp'],
        answerData['type'],
      );
      await pc.setRemoteDescription(description);
    }
  }

  Future<void> handleCandidate(String clientId, Map<String, dynamic> candidateData) async {
    final pc = _peerConnections[clientId];
    if (pc != null && candidateData['candidate'] != null) {
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'] ?? 0,
      );
      await pc.addCandidate(candidate);
    }
  }

  void removeClient(String clientId) {
    final pc = _peerConnections.remove(clientId);
    if (pc != null) {
      pc.close();
      pc.dispose();
      _updateViewersCount();
    }
  }

  void _updateViewersCount() {
    activeViewersCount.value = _peerConnections.length;
  }

  // Remote Hardware Controls
  Future<void> toggleTorch() async {
    try {
      if (_isTorchOn) {
        await TorchLight.disableTorch();
        _isTorchOn = false;
      } else {
        await TorchLight.enableTorch();
        _isTorchOn = true;
      }
    } catch (e) {
      try {
        final videoTracks = _localStream?.getVideoTracks();
        if (videoTracks != null && videoTracks.isNotEmpty) {
          _isTorchOn = !_isTorchOn;
          await videoTracks.first.setTorch(_isTorchOn);
        }
      } catch (_) {}
    }
    broadcastStateUpdate();
  }

  Future<void> switchCamera() async {
    try {
      final videoTracks = _localStream?.getVideoTracks();
      if (videoTracks != null && videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks.first);
        _currentFacing = (_currentFacing == 'back') ? 'front' : 'back';
      }
    } catch (e) {
      debugPrint('Switch camera error: $e');
    }
    broadcastStateUpdate();
  }

  void playSoothingSound(String soundName) {
    SoothingSoundType type = SoothingSoundType.none;
    switch (soundName) {
      case 'lullaby':
        type = SoothingSoundType.lullaby;
        break;
      case 'white_noise':
        type = SoothingSoundType.whiteNoise;
        break;
      case 'rain':
        type = SoothingSoundType.rain;
        break;
      case 'ocean':
        type = SoothingSoundType.ocean;
        break;
      case 'stop':
        type = SoothingSoundType.none;
        break;
    }
    soundPlayer.play(type);
    broadcastStateUpdate();
  }

  void setSoundTimer(int minutes) {
    soundPlayer.setTimer(minutes);
  }

  void toggleNightMode() {
    _isNightMode = !_isNightMode;
    if (onNightModeToggled != null) onNightModeToggled!();
    broadcastStateUpdate();
  }

  void setNightMode(bool value) {
    _isNightMode = value;
    if (onNightModeToggled != null) onNightModeToggled!();
    broadcastStateUpdate();
  }

  void broadcastStateUpdate() {
    final stateJson = jsonEncode({
      'type': 'state_update',
      'battery': _batteryLevel,
      'charging': _isCharging,
      'torch': _isTorchOn,
      'facing': _currentFacing,
      'nightMode': _isNightMode,
      'lullabyActive': soundPlayer.isPlaying,
      'viewers': _peerConnections.length,
    });

    if (onSendMessage != null) {
      for (final clientId in _peerConnections.keys) {
        onSendMessage!(clientId, stateJson);
      }
    }
  }

  void sendStateUpdateToClient(String clientId) {
    if (onSendMessage != null) {
      onSendMessage!(
        clientId,
        jsonEncode({
          'type': 'state_update',
          'battery': _batteryLevel,
          'charging': _isCharging,
          'torch': _isTorchOn,
          'facing': _currentFacing,
          'nightMode': _isNightMode,
          'lullabyActive': soundPlayer.isPlaying,
          'viewers': _peerConnections.length,
        }),
      );
    }
  }

  Map<String, dynamic> getCurrentStatus() {
    return {
      'battery': _batteryLevel,
      'charging': _isCharging,
      'torch': _isTorchOn,
      'facing': _currentFacing,
      'nightMode': _isNightMode,
      'pinRequired': isPinEnabled,
      'lullabyActive': soundPlayer.isPlaying,
      'viewers': _peerConnections.length,
      'streamActive': _localStream != null,
    };
  }

  Future<void> dispose() async {
    _batteryStateSub?.cancel();
    _batteryPollTimer?.cancel();
    soundPlayer.dispose();
    _intercomPlayer.dispose();
    
    for (final pc in _peerConnections.values) {
      await pc.close();
      await pc.dispose();
    }
    _peerConnections.clear();

    if (_isTorchOn) {
      try { await TorchLight.disableTorch(); } catch (_) {}
    }

    await _localStream?.dispose();
    _localStream = null;
    await localRenderer.dispose();
    await WakelockPlus.disable();
    _isInitialized = false;
  }
}
