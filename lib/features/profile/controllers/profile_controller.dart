import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/entities/user_entity.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

/// Derives the current user from auth state for the profile screen.
final profileProvider = Provider<UserEntity?>(
  (ref) => ref.watch(authControllerProvider).user,
);
