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

  /// Check if IP already exists in device list
  static bool isDuplicateIp(
    String ip,
    String excludeDeviceId,
    List<dynamic> allDevices, // List of NetworkDevice
  ) {
    for (final device in allDevices) {
      if (device.deviceId == excludeDeviceId) continue;

      // Check EndDevice and ServerDevice
      if (device.runtimeType.toString().contains('EndDevice') ||
          device.runtimeType.toString().contains('ServerDevice')) {
        final currentIp = (device as dynamic).currentIpAddress;
        if (currentIp == ip) return true;
      }

      // Check RouterDevice interfaces
      if (device.runtimeType.toString().contains('RouterDevice')) {
        final interfaces = (device as dynamic).interfaces;
        if (interfaces is Map) {
          for (final interface in interfaces.values) {
            if ((interface as dynamic).ipAddress == ip) return true;
          }
        }
      }
    }

    return false;
  }

  /// Validate gateway is in same subnet as IP address
  static bool isGatewayInSubnet(
    String gateway,
    String ipAddress,
    String subnetMask,
  ) {
    if (gateway.isEmpty) return true; // Optional

    if (!isValidIpv4(gateway)) return false;
    if (!isValidIpv4(ipAddress)) return false;
    if (!isValidIpv4(subnetMask)) return false;

    // Calculate network addresses
    final ipParts = ipAddress.split('.').map(int.parse).toList();
    final gwParts = gateway.split('.').map(int.parse).toList();
    final maskParts = subnetMask.split('.').map(int.parse).toList();

    // Check if on same network
    for (int i = 0; i < 4; i++) {
      if ((ipParts[i] & maskParts[i]) != (gwParts[i] & maskParts[i])) {
        return false;
      }
    }

    return true;
  }

  /// Get suggestion for subnet mask based on IP class
  static String suggestSubnetMask(String ip) {
    if (!isValidIpv4(ip)) return '255.255.255.0';

    final firstOctet = int.parse(ip.split('.')[0]);

    if (firstOctet < 128) return '255.0.0.0'; // Class A
    if (firstOctet < 192) return '255.255.0.0'; // Class B
    return '255.255.255.0'; // Class C
  }

  /// Validate subnet mask (must be valid and contiguous)
  static String? validateSubnetMask(String mask) {
    if (mask.isEmpty) return 'Subnet mask cannot be empty';

    if (!isValidIpv4(mask)) return getValidationError(mask);

    // Check if mask is contiguous (all 1s must be before all 0s in binary)
    final parts = mask.split('.').map(int.parse).toList();
    int binaryMask =
        (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3];

    // Convert to binary string and check contiguity
    String binary = binaryMask.toRadixString(2).padLeft(32, '0');

    // Should be like: 11111111111111111111111100000000
    // Check: no 1 after 0
    bool seenZero = false;
    for (int i = 0; i < binary.length; i++) {
      if (binary[i] == '0') {
        seenZero = true;
      } else if (seenZero) {
        return 'Invalid subnet mask: must be contiguous';
      }
    }

    return null; // Valid
  }
}
