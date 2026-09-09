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
  String get wordmark => 'MapAnytime';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'Password';

  @override
  String get enterPasswordHint => 'Enter your password';

  @override
  String get createPasswordHint => '8+ characters';

  @override
  String get confirmPasswordHint => 'Re-enter password';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToContinue => 'Sign in to pick up where you left off.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get createAccount => 'Create your account';

  @override
  String get joinTagline => 'Join MapAnytime Market as a buyer';

  @override
  String get firstName => 'First name';

  @override
  String get firstNameHint => 'Juan';

  @override
  String get middleName => 'Middle name (optional)';

  @override
  String get middleNameHint => 'Santos';

  @override
  String get lastName => 'Last name';

  @override
  String get lastNameHint => 'Dela Cruz';

  @override
  String get createAccountCta => 'Create account';

  @override
  String get accountCreatedPleaseLogin => 'Account created. Please log in.';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get logIn => 'Log in';

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we\'ll send a 6-digit code.';

  @override
  String get sendCode => 'Send code';

  @override
  String get resetCodeSent => 'Verification code sent. Check your email.';

  @override
  String get resetPasswordTitle => 'Enter verification code';

  @override
  String resetPasswordSubtitle(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get verificationCode => 'Verification code';

  @override
  String get verificationCodeInvalid => 'Enter the 4-digit code';

  @override
  String get signInCta => 'Sign In';

  @override
  String get signUpCta => 'Sign Up';

  @override
  String get nextCta => 'Next';

  @override
  String get acceptTerms => 'I accept the Terms & Privacy';

  @override
  String get registerStepEmailTitle => 'What\'s your email?';

  @override
  String get registerStepEmailSubtitle =>
      'We\'ll send pickup updates and receipts here.';

  @override
  String get registerStepNameTitle => 'What\'s your name?';

  @override
  String get registerStepNameSubtitle =>
      'Stores use this to hand over your order.';

  @override
  String get registerStepPasswordTitle => 'Create a password';

  @override
  String get registerStepPasswordSubtitle =>
      'At least 8 characters. Longer is stronger.';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get resetPasswordCta => 'Reset password';

  @override
  String get passwordResetSuccess => 'Password reset. Please log in.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get errorNoEmail => 'Error: No email provided';

  @override
  String get orSignInWith => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get registerSuccessTitle => 'Success!';

  @override
  String get registerSuccessSubtitle =>
      'Your account is ready. Start discovering stores near you.';

  @override
  String get continueButton => 'Continue';

  @override
  String get authTaglineDiscover => 'Discover nearby stores on the live map';

  @override
  String get authTaglineTrack => 'Track your pickup in real time';

  @override
  String get authTaglineCheckout => 'Checkout securely in Philippine peso';

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
