import 'package:flutter/material.dart';

class RootScaffold extends StatelessWidget {
  final Widget child;

  const RootScaffold({super.key, required this.child});

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(key: scaffoldMessengerKey, child: child);
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
    } else {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
    }
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.green);
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show a device alert snackbar with custom styling
  static void showDeviceAlert({
    BuildContext? context,
    required String deviceType,
    required String deviceId,
    required String message,
    required bool isPositive,
    double? percentageChange,
    Duration duration = const Duration(seconds: 5),
  }) {
    debugPrint(
      '🎯 [RootScaffold.showDeviceAlert] Called with device: $deviceType ($deviceId)',
    );
    debugPrint('🎯 [RootScaffold.showDeviceAlert] Message: $message');
    debugPrint('🎯 [RootScaffold.showDeviceAlert] IsPositive: $isPositive');
    debugPrint(
      '🎯 [RootScaffold.showDeviceAlert] Context provided: ${context != null}',
    );

    final snackBar = SnackBar(
      duration: duration,
      backgroundColor: isPositive ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isPositive ? Icons.check_circle : Icons.warning,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$deviceType (ID: $deviceId)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message +
                (percentageChange != null
                    ? ' (${percentageChange.toStringAsFixed(1)}%)'
                    : ''),
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );

    debugPrint('🎯 [RootScaffold.showDeviceAlert] SnackBar created');

    // Try to use context's ScaffoldMessenger first, then fall back to global key
    if (context != null) {
      debugPrint(
        '🎯 [RootScaffold.showDeviceAlert] Trying ScaffoldMessenger.maybeOf(context)',
      );
      final messenger = ScaffoldMessenger.maybeOf(context);
      debugPrint(
        '🎯 [RootScaffold.showDeviceAlert] Messenger from context: ${messenger != null ? "FOUND" : "NULL"}',
      );

      if (messenger != null) {
        debugPrint(
          '🎯 [RootScaffold.showDeviceAlert] Showing snackbar via context messenger',
        );
        messenger.showSnackBar(snackBar);
        debugPrint(
          '✅ [RootScaffold.showDeviceAlert] SnackBar shown via context messenger',
        );
        return;
      }
    }

    // Fall back to global key
    debugPrint('🎯 [RootScaffold.showDeviceAlert] Falling back to global key');
    debugPrint(
      '🎯 [RootScaffold.showDeviceAlert] Global key currentState: ${scaffoldMessengerKey.currentState != null ? "AVAILABLE" : "NULL"}',
    );

    scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
    debugPrint(
      '✅ [RootScaffold.showDeviceAlert] SnackBar shown via global key',
    );
  }
}
