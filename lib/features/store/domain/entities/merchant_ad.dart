/// The kind of content a [MerchantAd] carries. New kinds can be added here
/// as the backend grows what merchants can advertise.
enum MerchantAdKind { promo, job, event }

/// A single card in a merchant's ad section — a promo/deal, a job posting,
/// or a limited-time/limited-stock event.
///
/// Backed by the real API: `GET /stores/:id` returns a buyer-safe
/// `merchantAds` array (active, unexpired, and — for stock-linked events —
/// still in stock; see `store.service.ts` `filterLiveAds` in mapanytime-api).
/// [extra] holds kind-specific data (validity window, salary label…) that
/// the compact card doesn't render today, so adding real rendering for it
/// later is additive rather than a widget rewrite.
class MerchantAd {
  const MerchantAd({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    this.imageUrl,
    this.badgeLabel,
    this.ctaLabel,
    this.discountType,
    this.discountValue,
    this.buyQuantity,
    this.freeQuantity,
    this.productIds = const [],
    this.extra = const {},
  });

  factory MerchantAd.fromJson(Map<String, dynamic> json) {
    final kind = switch ((json['kind'] as String?)?.toUpperCase()) {
      'JOB' => MerchantAdKind.job,
      'EVENT' => MerchantAdKind.event,
      _ => MerchantAdKind.promo,
    };
    final expiresAt = json['expiresAt'] as String?;
    final salaryLabel = json['salaryLabel'] as String?;
    final rawProducts = json['products'];

    return MerchantAd(
      id: json['id'] as String,
      kind: kind,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      badgeLabel: json['badgeLabel'] as String?,
      ctaLabel: json['ctaLabel'] as String?,
      discountType: json['discountType'] as String?,
      discountValue: parseNum(json['discountValue']),
      buyQuantity: (json['buyQuantity'] as num?)?.toInt(),
      freeQuantity: (json['freeQuantity'] as num?)?.toInt(),
      productIds: rawProducts is List
          ? rawProducts
                .map((p) => (p as Map)['productId'] as String?)
                .whereType<String>()
                .toList()
          : const [],
      extra: {
        if (expiresAt != null && expiresAt.isNotEmpty) 'validUntil': expiresAt,
        if (salaryLabel != null && salaryLabel.isNotEmpty)
          'salaryLabel': salaryLabel,
      },
    );
  }

  static num? parseNum(Object? raw) {
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw);
    return null;
  }

  final String id;
  final MerchantAdKind kind;
  final String title;
  final String description;
  final String? imageUrl;
  final String? badgeLabel;
  final String? ctaLabel;

  /// Raw backend value: `'BOGO' | 'PERCENTAGE' | 'FIXED_AMOUNT'`, or null for
  /// a JOB posting / an EVENT with no discount attached.
  final String? discountType;
  final num? discountValue;
  final int? buyQuantity;
  final int? freeQuantity;

  /// IDs of the products this ad is linked to (empty for a JOB posting, or a
  /// PROMO/EVENT with no linked products).
  final List<String> productIds;
  final Map<String, String> extra;

  /// The badge text to show on a card — the merchant's own [badgeLabel] when
  /// set, else a label synthesized from the actual discount data so an ad
  /// with no custom badge still reads clearly.
  String? get displayBadge {
    if (badgeLabel != null && badgeLabel!.isNotEmpty) return badgeLabel;
    return switch (discountType) {
      'BOGO' when buyQuantity != null && freeQuantity != null =>
        'Buy $buyQuantity Get $freeQuantity Free',
      'PERCENTAGE' when discountValue != null =>
        '${discountValue!.toStringAsFixed(0)}% OFF',
      'FIXED_AMOUNT' when discountValue != null =>
        '₱${discountValue!.toStringAsFixed(0)} OFF',
      _ => kind == MerchantAdKind.event ? 'Limited time' : null,
    };
  }
}

/// Looks up the (first) ad linked to each product, so a product grid or
/// detail page can highlight items that are on promo.
extension MerchantAdsLookup on List<MerchantAd> {
  Map<String, MerchantAd> get byProductId {
    final map = <String, MerchantAd>{};
    for (final ad in this) {
      for (final id in ad.productIds) {
        map.putIfAbsent(id, () => ad);
      }
    }
    return map;
  }
}
