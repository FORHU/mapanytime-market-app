class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.rating,
    required this.buyerId,
    required this.buyerName,
    required this.createdAt,
    this.comment,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    final buyer = json['buyer'];
    final buyerMap = buyer is Map
        ? buyer.cast<String, dynamic>()
        : const <String, dynamic>{};
    final rawName = (buyerMap['displayName'] as String?)?.trim();
    final rawComment = (json['comment'] as String?)?.trim();
    final createdRaw = json['createdAt'] as String?;

    return ReviewItem(
      id: (json['id'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toInt().clamp(1, 5) ?? 5,
      buyerId:
          (buyerMap['id'] as String?) ?? (json['buyerId'] as String?) ?? '',
      buyerName: (rawName != null && rawName.isNotEmpty)
          ? rawName
          : 'Verified Buyer',
      comment: (rawComment != null && rawComment.isNotEmpty)
          ? rawComment
          : null,
      createdAt: createdRaw != null ? DateTime.tryParse(createdRaw) : null,
    );
  }

  final String id;
  final int rating;
  final String buyerId;
  final String buyerName;
  final String? comment;
  final DateTime? createdAt;
}

class ReviewListResult {
  const ReviewListResult({
    required this.items,
    required this.total,
    required this.averageRating,
  });

  factory ReviewListResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] is List
        ? json['items'] as List
        : const <dynamic>[];
    final items = rawItems
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => ReviewItem.fromJson(e.cast<String, dynamic>()))
        .toList();

    return ReviewListResult(
      items: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
    );
  }

  static const empty = ReviewListResult(items: [], total: 0, averageRating: 0);

  final List<ReviewItem> items;
  final int total;
  final double averageRating;
}
