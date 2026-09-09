import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ko'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MapAnytime Market'**
  String get appName;

  /// No description provided for @wordmark.
  ///
  /// In en, this message translates to:
  /// **'MapAnytime'**
  String get wordmark;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPasswordHint;

  /// No description provided for @createPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'8+ characters'**
  String get createPasswordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get confirmPasswordHint;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to pick up where you left off.'**
  String get signInToContinue;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccount;

  /// No description provided for @joinTagline.
  ///
  /// In en, this message translates to:
  /// **'Join MapAnytime Market as a buyer'**
  String get joinTagline;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @firstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Juan'**
  String get firstNameHint;

  /// No description provided for @middleName.
  ///
  /// In en, this message translates to:
  /// **'Middle name (optional)'**
  String get middleName;

  /// No description provided for @middleNameHint.
  ///
  /// In en, this message translates to:
  /// **'Santos'**
  String get middleNameHint;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @lastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Dela Cruz'**
  String get lastNameHint;

  /// No description provided for @createAccountCta.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountCta;

  /// No description provided for @accountCreatedPleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Account created. Please log in.'**
  String get accountCreatedPleaseLogin;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send a 6-digit code.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @resetCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent. Check your email.'**
  String get resetCodeSent;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}'**
  String resetPasswordSubtitle(String email);

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCode;

  /// No description provided for @verificationCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the 4-digit code'**
  String get verificationCodeInvalid;

  /// No description provided for @signInCta.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInCta;

  /// No description provided for @signUpCta.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpCta;

  /// No description provided for @nextCta.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextCta;

  /// No description provided for @acceptTerms.
  ///
  /// In en, this message translates to:
  /// **'I accept the Terms & Privacy'**
  String get acceptTerms;

  /// No description provided for @registerStepEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your email?'**
  String get registerStepEmailTitle;

  /// No description provided for @registerStepEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send pickup updates and receipts here.'**
  String get registerStepEmailSubtitle;

  /// No description provided for @registerStepNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get registerStepNameTitle;

  /// No description provided for @registerStepNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stores use this to hand over your order.'**
  String get registerStepNameSubtitle;

  /// No description provided for @registerStepPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get registerStepPasswordTitle;

  /// No description provided for @registerStepPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters. Longer is stronger.'**
  String get registerStepPasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @resetPasswordCta.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordCta;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset. Please log in.'**
  String get passwordResetSuccess;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @errorNoEmail.
  ///
  /// In en, this message translates to:
  /// **'Error: No email provided'**
  String get errorNoEmail;

  /// No description provided for @orSignInWith.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orSignInWith;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @registerSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get registerSuccessTitle;

  /// No description provided for @registerSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready. Start discovering stores near you.'**
  String get registerSuccessSubtitle;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @authTaglineDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover nearby stores on the live map'**
  String get authTaglineDiscover;

  /// No description provided for @authTaglineTrack.
  ///
  /// In en, this message translates to:
  /// **'Track your pickup in real time'**
  String get authTaglineTrack;

  /// No description provided for @authTaglineCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout securely in Philippine peso'**
  String get authTaglineCheckout;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @worldMap.
  ///
  /// In en, this message translates to:
  /// **'World Map'**
  String get worldMap;

  /// No description provided for @errorNoOrderId.
  ///
  /// In en, this message translates to:
  /// **'Error: No order ID provided'**
  String get errorNoOrderId;

  /// No description provided for @errorNoOrder.
  ///
  /// In en, this message translates to:
  /// **'Error: No order provided'**
  String get errorNoOrder;

  /// No description provided for @errorNoStore.
  ///
  /// In en, this message translates to:
  /// **'Error: No store provided'**
  String get errorNoStore;

  /// No description provided for @errorNoProduct.
  ///
  /// In en, this message translates to:
  /// **'Error: No product provided'**
  String get errorNoProduct;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @clearCartPrompt.
  ///
  /// In en, this message translates to:
  /// **'Clear cart?'**
  String get clearCartPrompt;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @productAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'{productName} added to cart'**
  String productAddedToCart(String productName);

  /// No description provided for @clearAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Clear & Add'**
  String get clearAndAdd;

  /// No description provided for @shareComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Share coming soon'**
  String get shareComingSoon;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @orderPlacedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get orderPlacedSuccess;

  /// No description provided for @orderPlacedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order: {error}'**
  String orderPlacedFailed(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
