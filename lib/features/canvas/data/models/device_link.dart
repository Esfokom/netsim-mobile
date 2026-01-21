/// Represents a connection between two devices on the canvas
class DeviceLink {
  final String id;
  final String fromDeviceId;
  final String toDeviceId;
  final LinkType type;
  bool isSelected;

  DeviceLink({
    required this.id,
    required this.fromDeviceId,
    required this.toDeviceId,
    this.type = LinkType.ethernet,
    this.isSelected = false,
  });

  DeviceLink copyWith({
    String? id,
    String? fromDeviceId,
    String? toDeviceId,
    LinkType? type,
    bool? isSelected,
  }) {
    return DeviceLink(
      id: id ?? this.id,
      fromDeviceId: fromDeviceId ?? this.fromDeviceId,
      toDeviceId: toDeviceId ?? this.toDeviceId,
      type: type ?? this.type,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Types of connections between devices
enum LinkType { ethernet, wireless, fiber }

extension LinkTypeExtension on LinkType {
  String get displayName {
    switch (this) {
      case LinkType.ethernet:
        return 'Ethernet';
      case LinkType.wireless:
        return 'Wireless';
      case LinkType.fiber:
        return 'Fiber';
    }
  }
}
