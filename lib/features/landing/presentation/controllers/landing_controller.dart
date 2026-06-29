import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/landing/data/mock_landing_repository.dart';
import 'package:mapanytime_market_app/features/landing/domain/entities/landing_content.dart';
import 'package:mapanytime_market_app/features/landing/domain/repositories/landing_repository.dart';

/// The active Landing data source. Swap to an API-backed repository here later.
final landingRepositoryProvider = Provider<LandingRepository>(
  (ref) => const MockLandingRepository(),
);

/// Loads the Landing screen content (mock for now).
final landingContentProvider = FutureProvider<LandingContent>(
  (ref) => ref.watch(landingRepositoryProvider).getLandingContent(),
);
