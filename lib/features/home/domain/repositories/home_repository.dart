import 'package:mapanytime_market_app/features/home/domain/entities/home_content.dart';

/// Source of Home screen content. Swap the implementation (mock → API) without
/// touching the presentation layer.
// ignore: one_member_abstracts
abstract class HomeRepository {
  Future<HomeContent> getHomeContent();
}
