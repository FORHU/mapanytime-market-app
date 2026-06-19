import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mapanytime_market_web/features/auth/domain/entities/user_entity.dart';
import 'package:mapanytime_market_web/features/auth/presentation/controllers/auth_controller.dart';

/// Derives the current user from auth state for the profile screen.
final profileProvider = Provider<UserEntity?>(
  (ref) => ref.watch(authControllerProvider).user,
);
