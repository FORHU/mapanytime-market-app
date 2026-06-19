import 'package:flutter/widgets.dart';
import 'package:mapanytime_market_web/l10n/generated/app_localizations.dart';

extension L10nExtension on BuildContext {
  /// Provides clean, non-nullable access to AppLocalizations.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
