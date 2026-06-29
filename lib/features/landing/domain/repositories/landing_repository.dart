import 'package:mapanytime_market_app/features/landing/domain/entities/landing_content.dart';

/// Source of Landing screen content. Swap the implementation (mock → API)
/// without touching the presentation layer.
// ignore: one_member_abstracts
abstract class LandingRepository {
  Future<LandingContent> getLandingContent();
}
