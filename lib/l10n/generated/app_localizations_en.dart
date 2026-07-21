// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MapAnytime Market';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get loginHint => 'Hint: any email + password of 6+ chars';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get worldMap => 'World Map';

  @override
  String get errorNoOrderId => 'Error: No order ID provided';

  @override
  String get errorNoOrder => 'Error: No order provided';

  @override
  String get errorNoStore => 'Error: No store provided';

  @override
  String get errorNoProduct => 'Error: No product provided';

  @override
  String get description => 'Description';

  @override
  String get clearCartPrompt => 'Clear cart?';

  @override
  String get cancel => 'Cancel';

  @override
  String productAddedToCart(String productName) {
    return '$productName added to cart';
  }

  @override
  String get clearAndAdd => 'Clear & Add';

  @override
  String get shareComingSoon => 'Share coming soon';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get notifications => 'Notifications';

  @override
  String get retry => 'Retry';

  @override
  String get cart => 'Cart';

  @override
  String get orderPlacedSuccess => 'Order placed successfully!';

  @override
  String orderPlacedFailed(String error) {
    return 'Failed to place order: $error';
  }
}
