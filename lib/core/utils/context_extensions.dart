import 'package:flutter/widgets.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';

extension L10nExtension on BuildContext {
  /// Provides clean, non-nullable access to AppLocalizations.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
