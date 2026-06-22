class CdWsConfig {
  const CdWsConfig({
    required this.url,
    this.token,
    this.heartbeatInterval = const Duration(seconds: 20),
    this.reconnect = true,
    this.maxReconnectAttempts = 999,
  });

  final String url;
  final String? token;
  final Duration heartbeatInterval;
  final bool reconnect;
  final int maxReconnectAttempts;
}