/// The kind of content a [MerchantAd] carries. New kinds can be added here
/// as the backend grows what merchants can advertise.
enum MerchantAdKind { promo, job }

/// A single card in a merchant's ad section — a promo/deal or a job posting
/// today, general enough to cover other kinds later.
///
/// Not backed by a real API field yet; see `mock_merchant_ads.dart`. [extra]
/// holds kind-specific data (validity window, apply link, salary label…)
/// that the compact card doesn't render, so adding real backend fields later
/// is additive rather than a widget rewrite.
class MerchantAd {
  const MerchantAd({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    this.imageUrl,
    this.badgeLabel,
    this.ctaLabel,
    this.extra = const {},
  });

  final String id;
  final MerchantAdKind kind;
  final String title;
  final String description;
  final String? imageUrl;
  final String? badgeLabel;
  final String? ctaLabel;
  final Map<String, String> extra;
}
