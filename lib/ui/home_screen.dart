import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../server/local_web_server.dart';
import '../streaming/stream_manager.dart';
import '../streaming/soothing_sound_player.dart';
import 'night_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StreamManager _streamManager = StreamManager();
  LocalWebServer? _server;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (cameraStatus.isDenied || micStatus.isDenied) {
        setState(() {
          _errorMessage = 'Camera and Microphone permissions are required.';
          _isLoading = false;
        });
        return;
      }

      await _streamManager.initialize();
      _server = LocalWebServer(
        streamManager: _streamManager,
        httpPort: 8080,
        httpsPort: 8443,
      );
      await _server!.start();

      _streamManager.onNightModeToggled = () {
        if (mounted) setState(() {});
      };

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize monitor: $e';
        _isLoading = false;
      });
    }
  }

  void _enterNightMode() {
    _streamManager.setNightMode(true);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NightModeScreen(
          streamManager: _streamManager,
          onExit: () {
            _streamManager.setNightMode(false);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _copyUrl() {
    if (_server != null) {
      Clipboard.setData(ClipboardData(text: _server!.streamUrl));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stream URL copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showPinDialog() {
    final controller = TextEditingController(text: _streamManager.pinCode);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Row(
                children: [
                  Text('🔒', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 8),
                  Text('4-Digit Security PIN', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Require PIN to view', style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: _streamManager.isPinEnabled,
                    activeThumbColor: const Color(0xFF38BDF8),
                    onChanged: (val) {
                      setModalState(() {
                        _streamManager.isPinEnabled = val;
                      });
                      setState(() {});
                    },
                  ),
                  if (_streamManager.isPinEnabled) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 8),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '1234',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_streamManager.isPinEnabled && controller.text.length == 4) {
                      _streamManager.pinCode = controller.text;
                    }
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('Save', style: TextStyle(color: Color(0xFF38BDF8))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showHotspotHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Text('✈️', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Travel / Hotspot Mode', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When in a hotel or traveling without a home router:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text('1. Turn on "Personal Hotspot" on this Android phone.', style: TextStyle(color: Colors.white, fontSize: 13)),
            SizedBox(height: 6),
            Text('2. Connect your viewer phone (iPhone/Android) to this hotspot.', style: TextStyle(color: Colors.white, fontSize: 13)),
            SizedBox(height: 6),
            Text('3. Scan the QR code. It will stream directly with ZERO internet needed!', style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _server?.stop();
    _streamManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0F19),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF38BDF8)),
              SizedBox(height: 16),
              Text(
                'Starting Baby Monitor & Local Web Server...',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _initApp,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final streamUrl = _server?.streamUrl ?? 'http://127.0.0.1:8080';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            const Text('👶', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            const Text(
              'Baby Monitor Host',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Active Viewers Badge
          ValueListenableBuilder<int>(
            valueListenable: _streamManager.activeViewersCount,
            builder: (context, count, _) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: count > 0 ? const Color(0x3322C55E) : const Color(0x3364748B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: count > 0 ? const Color(0xFF22C55E) : const Color(0xFF64748B),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.remove_red_eye_outlined,
                      size: 14,
                      color: count > 0 ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count live',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: count > 0 ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Two-Way Intercom Incoming Alert Banner
            ValueListenableBuilder<bool>(
              valueListenable: _streamManager.isIntercomTalking,
              builder: (context, isTalking, _) {
                if (!isTalking) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF38BDF8)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.volume_up, color: Color(0xFF38BDF8), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🎙️ Parent is speaking through intercom speaker...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Travel / Hotspot helper banner
            InkWell(
              onTap: _showHotspotHelp,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Text('✈️', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Travel / Hotel Mode: Use with Phone Hotspot',
                        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),

            // QR Code & Local Connect Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text(
                    'Scan with iPhone, iPad, or Android',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Zero-Install Web Viewer • Add to Home Screen PWA',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: streamUrl,
                      version: QrVersions.auto,
                      size: 160.0,
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _copyUrl,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link, size: 16, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 8),
                          Text(
                            streamUrl,
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy, size: 14, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Live Camera Preview Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Live Camera Preview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Quality Selector Dropdown
                        DropdownButton<StreamQuality>(
                          value: _streamManager.currentQuality,
                          dropdownColor: const Color(0xFF0F172A),
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF38BDF8)),
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                          items: const [
                            DropdownMenuItem(value: StreamQuality.fullHd, child: Text('1080p FHD')),
                            DropdownMenuItem(value: StreamQuality.hd, child: Text('720p HD')),
                            DropdownMenuItem(value: StreamQuality.saver, child: Text('480p Saver')),
                          ],
                          onChanged: (quality) {
                            if (quality != null) {
                              _streamManager.setQuality(quality);
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.black,
                      child: RTCVideoView(
                        _streamManager.localRenderer,
                        mirror: _streamManager.currentFacing == 'front',
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Night / Sleep Mode Button
            ElevatedButton.icon(
              onPressed: _enterNightMode,
              icon: const Icon(Icons.nightlight_round, color: Colors.amberAccent),
              label: const Text(
                'Enter Night / Sleep Mode (Black Screen)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.amberAccent, width: 0.6),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Quick Control Cards Grid
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _streamManager.toggleTorch();
                      setState(() {});
                    },
                    icon: Icon(
                      _streamManager.isTorchOn ? Icons.flashlight_on : Icons.flashlight_off,
                      color: _streamManager.isTorchOn ? Colors.yellow : const Color(0xFF94A3B8),
                    ),
                    label: Text(
                      _streamManager.isTorchOn ? 'Torch On' : 'Torch Off',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _streamManager.switchCamera();
                      setState(() {});
                    },
                    icon: const Icon(Icons.flip_camera_android, color: Color(0xFF38BDF8)),
                    label: const Text(
                      'Flip Camera',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Soothing Sound & Security PIN Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (_streamManager.soundPlayer.isPlaying) {
                        _streamManager.soundPlayer.stop();
                      } else {
                        _streamManager.soundPlayer.play(SoothingSoundType.lullaby);
                      }
                      setState(() {});
                    },
                    icon: Icon(
                      _streamManager.soundPlayer.isPlaying ? Icons.music_note : Icons.music_off,
                      color: _streamManager.soundPlayer.isPlaying ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                    ),
                    label: Text(
                      _streamManager.soundPlayer.isPlaying ? 'Lullaby 🎵' : 'Play Sound',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showPinDialog,
                    icon: Icon(
                      _streamManager.isPinEnabled ? Icons.lock : Icons.lock_open,
                      color: _streamManager.isPinEnabled ? Colors.greenAccent : const Color(0xFF94A3B8),
                    ),
                    label: Text(
                      _streamManager.isPinEnabled ? 'PIN Active' : 'Set PIN',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
