// Smoke test: the app boots and shows the login page when unauthenticated.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/app.dart';
import 'package:mapanytime_market_app/core/config/app_config.dart';
import 'package:mapanytime_market_app/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the login page when unauthenticated', (tester) async {
    // Tests don't run bootstrap(), so set the active config manually.
    AppConfig.instance = AppConfig.fromEnvironment();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });
}
