import 'package:logger/logger.dart';

/// Centralized logger instance for the application
///
/// Usage:
/// ```dart
/// import 'package:netsim_mobile/core/utils/app_logger.dart';
///
/// appLogger.d('Debug message');
/// appLogger.i('Info message');
/// appLogger.w('Warning message');
/// appLogger.e('Error message', error: error, stackTrace: stackTrace);
/// ```
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2, // Number of method calls to be displayed
    errorMethodCount: 8, // Number of method calls if stacktrace is provided
    lineLength: 120, // Width of the output
    colors: true, // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
    dateTimeFormat: DateTimeFormat.none, // Don't print timestamps
  ),
);

/// Simple logger for production (no emojis, minimal formatting)
final simpleLogger = Logger(
  printer: SimplePrinter(colors: false, printTime: true),
);
