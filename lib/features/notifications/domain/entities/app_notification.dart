/// A realtime notification pushed from the server over Socket.IO
/// (`notification:new`). Mirrors the backend `NotificationEventPayload`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.metadata,
    this.sentAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> m) {
    final rawMeta = m['metadata'];
    final rawSentAt = m['sentAt'];
    return AppNotification(
      id: m['id'] as String? ?? '',
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
      metadata: rawMeta is Map ? rawMeta.cast<String, dynamic>() : null,
      sentAt: rawSentAt is String ? DateTime.tryParse(rawSentAt) : null,
    );
  }

  final String id;
  final String title;
  final String body;

  /// Arbitrary extra data (e.g. `{ orderId, type }`) for deep-linking later.
  final Map<String, dynamic>? metadata;
  final DateTime? sentAt;
}
