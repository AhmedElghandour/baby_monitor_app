import 'dart:async';
import 'package:flutter/material.dart';
import '../streaming/stream_manager.dart';

class NightModeScreen extends StatefulWidget {
  final StreamManager streamManager;
  final VoidCallback onExit;

  const NightModeScreen({
    super.key,
    required this.streamManager,
    required this.onExit,
  });

  @override
  State<NightModeScreen> createState() => _NightModeScreenState();
}

class _NightModeScreenState extends State<NightModeScreen> {
  DateTime _currentTime = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: InkWell(
        onTap: widget.onExit,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SizedBox.expand(
          child: SafeArea(
            child: Stack(
              children: [
                // Very dim clock and status to prevent disturbing baby
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(_currentTime),
                        style: const TextStyle(
                          color: Color(0x22FFFFFF),
                          fontSize: 64,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0x3300FF00),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          ValueListenableBuilder<int>(
                            valueListenable: widget.streamManager.activeViewersCount,
                            builder: (context, count, _) {
                              return Text(
                                count > 0 ? '$count Viewer(s) Watching' : 'Live Streaming Active',
                                style: const TextStyle(
                                  color: Color(0x22FFFFFF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tap to wake hint
                const Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Tap screen to wake',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0x1AFFFFFF),
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
