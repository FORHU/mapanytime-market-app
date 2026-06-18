import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trivial counter state to show a feature-local controller.
class HomeController extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
  void reset() => state = 0;
}

final homeControllerProvider =
    NotifierProvider<HomeController, int>(HomeController.new);
