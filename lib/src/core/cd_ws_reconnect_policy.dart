class CdWsReconnectPolicy {
  const CdWsReconnectPolicy({
    this.enabled = true,
    this.maxAttempts = 999,
    this.minDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 10),
  });

  final bool enabled;
  final int maxAttempts;
  final Duration minDelay;
  final Duration maxDelay;

  Duration getDelay(int attempt) {
    if (attempt <= 1) {
      return minDelay;
    }

    final seconds = minDelay.inSeconds * (1 << (attempt - 1));

    if (seconds >= maxDelay.inSeconds) {
      return maxDelay;
    }

    return Duration(seconds: seconds);
  }

  bool canReconnect(int attempt) {
    if (!enabled) {
      return false;
    }

    return attempt < maxAttempts;
  }
}