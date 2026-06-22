import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../cd_ws_client.dart';



class CdWsClient {
  CdWsClient(this.config);

  final CdWsConfig config;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  bool _manualClose = false;
  int _reconnectCount = 0;

  final StreamController<CdWsMessage> _messageController =
  StreamController<CdWsMessage>.broadcast();

  final StreamController<CdWsStatus> _statusController =
  StreamController<CdWsStatus>.broadcast();

  Stream<CdWsMessage> get messages => _messageController.stream;

  Stream<CdWsStatus> get status => _statusController.stream;

  CdWsStatus _currentStatus = CdWsStatus.disconnected;

  CdWsStatus get currentStatus => _currentStatus;

  Future<void> connect() async {
    if (_currentStatus == CdWsStatus.connecting ||
        _currentStatus == CdWsStatus.connected) {
      return;
    }

    _manualClose = false;
    _setStatus(CdWsStatus.connecting);

    try {
      final uri = Uri.parse(config.url);
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onDone: _handleDisconnected,
        onError: _handleError,
        cancelOnError: true,
      );

      _reconnectCount = 0;
      _setStatus(CdWsStatus.connected);

      _sendAuthIfNeeded();
      _startHeartbeat();
    } catch (_) {
      _setStatus(CdWsStatus.error);
      _handleDisconnected();
    }
  }

  void send(Map<String, dynamic> data) {
    if (_channel == null) return;

    _channel!.sink.add(jsonEncode(data));
  }

  void subscribe(String topic, {Map<String, dynamic>? params}) {
    send({
      'type': 'subscribe',
      'topic': topic,
      if (params != null) 'params': params,
    });
  }

  void unsubscribe(String topic) {
    send({
      'type': 'unsubscribe',
      'topic': topic,
    });
  }

  Future<void> disconnect() async {
    _manualClose = true;

    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    _setStatus(CdWsStatus.closed);
  }

  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
    await _statusController.close();
  }

  void _handleMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message.toString());

      if (decoded is Map<String, dynamic>) {
        final type = decoded['type']?.toString() ?? 'message';

        _messageController.add(
          CdWsMessage(
            type: type,
            data: decoded['data'],
            raw: decoded,
          ),
        );
      } else {
        _messageController.add(
          CdWsMessage(
            type: 'message',
            data: decoded,
            raw: decoded,
          ),
        );
      }
    } catch (_) {
      _messageController.add(
        CdWsMessage(
          type: 'raw',
          data: message,
          raw: message,
        ),
      );
    }
  }

  void _handleError(Object error) {
    _setStatus(CdWsStatus.error);
    _handleDisconnected();
  }

  void _handleDisconnected() {
    _stopHeartbeat();

    _subscription?.cancel();
    _subscription = null;
    _channel = null;

    if (_manualClose) {
      _setStatus(CdWsStatus.closed);
      return;
    }

    if (!config.reconnect) {
      _setStatus(CdWsStatus.disconnected);
      return;
    }

    if (_reconnectCount >= config.maxReconnectAttempts) {
      _setStatus(CdWsStatus.disconnected);
      return;
    }

    _reconnectCount++;
    _setStatus(CdWsStatus.reconnecting);

    final delay = _getReconnectDelay(_reconnectCount);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  Duration _getReconnectDelay(int count) {
    if (count <= 1) return const Duration(seconds: 1);
    if (count == 2) return const Duration(seconds: 2);
    if (count == 3) return const Duration(seconds: 4);
    if (count == 4) return const Duration(seconds: 6);
    return const Duration(seconds: 10);
  }

  void _startHeartbeat() {
    _stopHeartbeat();

    _heartbeatTimer = Timer.periodic(config.heartbeatInterval, (_) {
      send({
        'type': 'ping',
        'time': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendAuthIfNeeded() {
    final token = config.token;

    if (token == null || token.isEmpty) return;

    send({
      'type': 'auth',
      'token': token,
    });
  }

  void _setStatus(CdWsStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }
}