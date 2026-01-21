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
                size: 20,
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

          Wrap(
            children: [
              Text(
                message +
                    (percentageChange != null
                        ? ' (${percentageChange.toStringAsFixed(1)}%) '
                        : ''),
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              if (percentageChange != null)
                isPositive
                    ? Icon(Icons.trending_up)
                    : Icon(Icons.trending_down),
            ],
          ),
        ],
      ),
    );

    // Try to use context's ScaffoldMessenger first, then fall back to global key
    if (context != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.showSnackBar(snackBar);
        return;
      }
    }

    scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }
}
