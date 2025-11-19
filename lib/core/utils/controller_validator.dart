import 'package:flutter/material.dart';

/// Utility class for validating transformation controllers
class ControllerValidator {
  /// Check if transformation controller is valid and not disposed
  static bool isValid(TransformationController? controller) {
    if (controller == null) return false;
    try {
      // Try to access the value to check if it's disposed
      controller.value;
      return true;
    } catch (e) {
      return false;
    }
  }
}
