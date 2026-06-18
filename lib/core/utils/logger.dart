import 'package:logger/logger.dart';

/// A global instance of Logger.
/// Replace all generic `print()` and `debugPrint()` statements with this structured logger.
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 100,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.none,
  ),
);
