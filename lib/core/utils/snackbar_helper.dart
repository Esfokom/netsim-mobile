import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

class SnackBarHelper {
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final colors = _getColors(context, type);
    final icon = _getIcon(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: colors.iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: colors.textColor)),
            ),
          ],
        ),
        backgroundColor: colors.backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: action,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context,
      message,
      type: SnackBarType.success,
      duration: duration,
      action: action,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    show(
      context,
      message,
      type: SnackBarType.error,
      duration: duration,
      action: action,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context,
      message,
      type: SnackBarType.warning,
      duration: duration,
      action: action,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context,
      message,
      type: SnackBarType.info,
      duration: duration,
      action: action,
    );
  }

  static void showLoading(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static void dismiss(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  static void showWithRetry(
    BuildContext context,
    String message,
    VoidCallback onRetry, {
    SnackBarType type = SnackBarType.error,
    Duration duration = const Duration(seconds: 5),
  }) {
    show(
      context,
      message,
      type: type,
      duration: duration,
      action: SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: onRetry,
      ),
    );
  }

  static void showWithUndo(
    BuildContext context,
    String message,
    VoidCallback onUndo, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message,
      type: SnackBarType.info,
      duration: duration,
      action: SnackBarAction(
        label: 'Undo',
        textColor: Colors.white,
        onPressed: onUndo,
      ),
    );
  }

  static _SnackBarColors _getColors(BuildContext context, SnackBarType type) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    switch (type) {
      case SnackBarType.success:
        return _SnackBarColors(
          backgroundColor: isDark
              ? const Color(0xFF2D5F2E)
              : const Color(0xFF4CAF50),
          iconColor: Colors.white,
          textColor: Colors.white,
        );
      case SnackBarType.error:
        return _SnackBarColors(
          backgroundColor: isDark
              ? const Color(0xFF7F1D1D)
              : const Color(0xFFD32F2F),
          iconColor: Colors.white,
          textColor: Colors.white,
        );
      case SnackBarType.warning:
        return _SnackBarColors(
          backgroundColor: isDark
              ? const Color(0xFF7C5B00)
              : const Color(0xFFFFA726),
          iconColor: Colors.white,
          textColor: Colors.white,
        );
      case SnackBarType.info:
        return _SnackBarColors(
          backgroundColor: isDark
              ? const Color(0xFF1E3A5F)
              : const Color(0xFF2196F3),
          iconColor: Colors.white,
          textColor: Colors.white,
        );
    }
  }

  static IconData _getIcon(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle;
      case SnackBarType.error:
        return Icons.error;
      case SnackBarType.warning:
        return Icons.warning;
      case SnackBarType.info:
        return Icons.info;
    }
  }
}

class _SnackBarColors {
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;

  _SnackBarColors({
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
  });
}
