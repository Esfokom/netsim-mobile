/// Utility class for validating and formatting IP addresses
class IpValidator {
  /// Validates an IPv4 address
  /// Returns true if valid, false otherwise
  static bool isValidIpv4(String ip) {
    if (ip.isEmpty) return false;

    final parts = ip.split('.');

    // Must have exactly 4 parts
    if (parts.length != 4) return false;

    // Each part must be a valid number between 0-255
    for (final part in parts) {
      if (part.isEmpty) return false;

      final number = int.tryParse(part);
      if (number == null || number < 0 || number > 255) {
        return false;
      }
    }

    return true;
  }

  /// Formats IP address input by removing invalid characters
  /// and ensuring proper format
  static String formatIpInput(String input) {
    // Remove any non-digit and non-dot characters
    String cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');

    // Ensure no more than 4 segments
    final parts = cleaned.split('.');
    if (parts.length > 4) {
      cleaned = parts.take(4).join('.');
    }

    // Ensure each segment doesn't exceed 255
    final segments = cleaned.split('.');
    final validSegments = segments.map((segment) {
      if (segment.isEmpty) return segment;
      final num = int.tryParse(segment);
      if (num == null) return '';
      if (num > 255) return '255';
      return segment;
    }).toList();

    return validSegments.join('.');
  }

  /// Validates an IP address segment (0-255)
  static bool isValidSegment(String segment) {
    if (segment.isEmpty) return true; // Allow empty for typing
    final number = int.tryParse(segment);
    return number != null && number >= 0 && number <= 255;
  }

  /// Gets error message for invalid IP
  static String? getValidationError(String ip) {
    if (ip.isEmpty) return 'IP address cannot be empty';

    final parts = ip.split('.');

    if (parts.length < 4) {
      return 'IP address must have 4 segments (e.g., 192.168.1.1)';
    }

    if (parts.length > 4) {
      return 'IP address cannot have more than 4 segments';
    }

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) {
        return 'Segment ${i + 1} cannot be empty';
      }

      final number = int.tryParse(part);
      if (number == null) {
        return 'Segment ${i + 1} must be a number';
      }

      if (number < 0 || number > 255) {
        return 'Segment ${i + 1} must be between 0 and 255';
      }
    }

    return null; // No error
  }
}
