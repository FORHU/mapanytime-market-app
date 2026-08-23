/// A notification, either pushed live over Socket.IO (`notification:new`,
/// field `sentAt`) or read from the persisted feed (`GET /notifications`,
/// field `createdAt`) — `fromJson` accepts either shape.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.metadata,
    this.sentAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> m) {
    final rawMeta = m['metadata'];
    final rawSentAt = m['sentAt'] ?? m['createdAt'];
    final rawReadAt = m['readAt'];
    return AppNotification(
      id: m['id'] as String? ?? '',
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
      metadata: rawMeta is Map ? rawMeta.cast<String, dynamic>() : null,
      sentAt: rawSentAt is String ? DateTime.tryParse(rawSentAt) : null,
      readAt: rawReadAt is String ? DateTime.tryParse(rawReadAt) : null,
    );
  }

  final String id;
  final String title;
  final String body;

  /// Arbitrary extra data (e.g. `{ orderId, type }`) for deep-linking later.
  final Map<String, dynamic>? metadata;
  final DateTime? sentAt;

  /// Null until read. Only ever populated by the persisted feed — a live
  /// socket push is by definition unread.
  final DateTime? readAt;

  bool get isUnread => readAt == null;
}
