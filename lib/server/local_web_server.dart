import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'embedded_web_app.dart';
import 'local_ssl_cert.dart';
import '../streaming/stream_manager.dart';

class LocalWebServer {
  final StreamManager streamManager;
  final int httpPort;
  final int httpsPort;

  HttpServer? _httpServer;
  HttpServer? _httpsServer;
  String? _localIp;
  bool _isRunning = false;
  bool _isHotspot = false;

  final Map<String, WebSocketChannel> _connectedSockets = {};
  int _clientCounter = 0;

  bool get isRunning => _isRunning;
  bool get isHotspot => _isHotspot;
  String? get localIp => _localIp;
  String get streamUrl => 'http://${_localIp ?? "127.0.0.1"}:$httpPort';
  String get httpsStreamUrl => 'https://${_localIp ?? "127.0.0.1"}:$httpsPort';

  LocalWebServer({
    required this.streamManager,
    this.httpPort = 8080,
    this.httpsPort = 8443,
  }) {
    streamManager.onSendMessage = _sendMessageToClient;
  }

  Future<void> start() async {
    if (_isRunning) return;

    await _resolveLocalIp();

    final router = Router();

    // 1. Serve embedded web viewer
    router.get('/', (Request request) {
      final html = EmbeddedWebApp.getHtml(
        hostName: _localIp ?? 'localhost',
        port: request.requestedUri.port,
        isPinRequired: streamManager.isPinEnabled,
      );
      return Response.ok(
        html,
        headers: {
          'content-type': 'text/html; charset=utf-8',
          'cache-control': 'no-cache, no-store, must-revalidate',
        },
      );
    });

    // 2. PWA Manifest
    router.get('/manifest.json', (Request request) {
      return Response.ok(
        EmbeddedWebApp.getManifestJson(),
        headers: {'content-type': 'application/manifest+json; charset=utf-8'},
      );
    });

    // 3. Health & Status REST API
    router.get('/api/status', (Request request) {
      final status = streamManager.getCurrentStatus();
      status['ip'] = _localIp;
      status['httpPort'] = httpPort;
      status['httpsPort'] = httpsPort;
      status['httpUrl'] = streamUrl;
      status['httpsUrl'] = httpsStreamUrl;
      status['isHotspot'] = _isHotspot;
      return Response.ok(
        jsonEncode(status),
        headers: {'content-type': 'application/json'},
      );
    });

    // 4. WebSocket endpoint for WebRTC signaling, PIN auth, and remote controls
    final wsHandler = webSocketHandler((WebSocketChannel webSocket, String? protocol) {
      final clientId = 'client_${++_clientCounter}';
      _connectedSockets[clientId] = webSocket;
      debugPrint('WebSocket client connected: $clientId');

      webSocket.stream.listen(
        (dynamic message) {
          _handleClientMessage(clientId, message);
        },
        onDone: () {
          debugPrint('WebSocket client disconnected: $clientId');
          _connectedSockets.remove(clientId);
          streamManager.removeClient(clientId);
        },
        onError: (error) {
          debugPrint('WebSocket client error [$clientId]: $error');
          _connectedSockets.remove(clientId);
          streamManager.removeClient(clientId);
        },
      );
    });

    router.get('/ws', wsHandler);

    final pipeline = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.call);

    try {
      // Bind HTTP Server (zero-warning view)
      _httpServer = await shelf_io.serve(
        pipeline,
        InternetAddress.anyIPv4,
        httpPort,
      );
      debugPrint('Baby Monitor HTTP running at $streamUrl');

      // Bind HTTPS Server (for browser microphone permissions in Secure Context)
      try {
        final securityContext = LocalSslCert.getSecurityContext();
        _httpsServer = await shelf_io.serve(
          pipeline,
          InternetAddress.anyIPv4,
          httpsPort,
          securityContext: securityContext,
        );
        debugPrint('Baby Monitor HTTPS running at $httpsStreamUrl');
      } catch (sslErr) {
        debugPrint('HTTPS server start note: $sslErr');
      }

      _isRunning = true;
    } catch (e) {
      debugPrint('Failed to start server: $e');
      rethrow;
    }
  }

  Future<void> _resolveLocalIp() async {
    _isHotspot = false;
    try {
      final info = NetworkInfo();
      _localIp = await info.getWifiIP();
    } catch (_) {}

    if (_localIp == null || _localIp!.isEmpty || _localIp == '127.0.0.1') {
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLinkLocal: false,
        );
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (!addr.isLoopback) {
              if (addr.address.startsWith('192.168.43.')) {
                _isHotspot = true;
              }
              if (addr.address.startsWith('192.168.') ||
                  addr.address.startsWith('10.') ||
                  addr.address.startsWith('172.')) {
                _localIp = addr.address;
                break;
              }
            }
          }
          if (_localIp != null) break;
        }
      } catch (e) {
        debugPrint('Error listing network interfaces: $e');
      }
    }

    _localIp ??= '127.0.0.1';
  }

  void _handleClientMessage(String clientId, dynamic rawMessage) {
    try {
      final Map<String, dynamic> data = jsonDecode(rawMessage.toString());
      final type = data['type'];

      switch (type) {
        case 'verify_pin':
          final pin = data['pin']?.toString() ?? '';
          final success = streamManager.verifyPin(pin);
          _sendMessageToClient(
            clientId,
            jsonEncode({'type': 'pin_result', 'success': success}),
          );
          break;
        case 'intercom_voice':
          final base64Audio = data['audio']?.toString() ?? '';
          if (base64Audio.isNotEmpty) {
            try {
              final bytes = base64Decode(base64Audio);
              streamManager.playIntercomVoice(bytes);
            } catch (e) {
              debugPrint('Error decoding intercom voice: $e');
            }
          }
          break;
        case 'client_ready':
          streamManager.handleClientReady(clientId);
          break;
        case 'answer':
          if (data['answer'] != null) {
            streamManager.handleAnswer(
              clientId,
              Map<String, dynamic>.from(data['answer']),
            );
          }
          break;
        case 'candidate':
          if (data['candidate'] != null) {
            streamManager.handleCandidate(
              clientId,
              Map<String, dynamic>.from(data['candidate']),
            );
          }
          break;
        case 'command':
          _handleRemoteCommand(data);
          break;
      }
    } catch (e) {
      debugPrint('Error parsing client message: $e');
    }
  }

  void _handleRemoteCommand(Map<String, dynamic> data) {
    final action = data['action'];
    switch (action) {
      case 'toggle_torch':
        streamManager.toggleTorch();
        break;
      case 'switch_camera':
        streamManager.switchCamera();
        break;
      case 'toggle_night_mode':
        streamManager.toggleNightMode();
        break;
      case 'play_sound':
        final sound = data['sound']?.toString() ?? 'stop';
        streamManager.playSoothingSound(sound);
        break;
      case 'sound_timer':
        final minutes = int.tryParse(data['minutes']?.toString() ?? '15') ?? 15;
        streamManager.setSoundTimer(minutes);
        break;
    }
  }

  void _sendMessageToClient(String clientId, String message) {
    final socket = _connectedSockets[clientId];
    if (socket != null) {
      try {
        socket.sink.add(message);
      } catch (e) {
        debugPrint('Error sending message to $clientId: $e');
      }
    }
  }

  Future<void> stop() async {
    for (var socket in _connectedSockets.values) {
      try {
        await socket.sink.close();
      } catch (_) {}
    }
    _connectedSockets.clear();

    await _httpServer?.close(force: true);
    await _httpsServer?.close(force: true);
    _httpServer = null;
    _httpsServer = null;
    _isRunning = false;
  }
}
