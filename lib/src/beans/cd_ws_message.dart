class CdWsMessage {
  const CdWsMessage({
    required this.type,
    this.data,
    this.raw,
  });

  final String type;
  final dynamic data;
  final dynamic raw;
}