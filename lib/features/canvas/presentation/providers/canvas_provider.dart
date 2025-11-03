import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/data/models/device_link.dart';

/// State class for managing canvas devices and links
class CanvasState {
  final List<CanvasDevice> devices;
  final List<DeviceLink> links;
  final double scale;
  final bool isLinkingMode;
  final String? linkingFromDeviceId;

  CanvasState({
    this.devices = const [],
    this.links = const [],
    this.scale = 1.0,
    this.isLinkingMode = false,
    this.linkingFromDeviceId,
  });

  CanvasState copyWith({
    List<CanvasDevice>? devices,
    List<DeviceLink>? links,
    double? scale,
    bool? isLinkingMode,
    String? linkingFromDeviceId,
    bool clearLinkingFromDeviceId = false,
  }) {
    return CanvasState(
      devices: devices ?? this.devices,
      links: links ?? this.links,
      scale: scale ?? this.scale,
      isLinkingMode: isLinkingMode ?? this.isLinkingMode,
      linkingFromDeviceId: clearLinkingFromDeviceId
          ? null
          : (linkingFromDeviceId ?? this.linkingFromDeviceId),
    );
  }

  // Statistics
  int get totalDevices => devices.length;
  int get devicesOnline =>
      devices.where((d) => d.status == DeviceStatus.online).length;
  int get devicesOffline =>
      devices.where((d) => d.status == DeviceStatus.offline).length;
  int get devicesWithWarning =>
      devices.where((d) => d.status == DeviceStatus.warning).length;
  int get devicesWithError =>
      devices.where((d) => d.status == DeviceStatus.error).length;
}

/// Notifier for managing canvas state
class CanvasNotifier extends Notifier<CanvasState> {
  @override
  CanvasState build() {
    return CanvasState();
  }

  /// Add a device to the canvas
  void addDevice(CanvasDevice device) {
    state = state.copyWith(devices: [...state.devices, device]);
  }

  /// Remove a device from the canvas
  void removeDevice(String deviceId) {
    state = state.copyWith(
      devices: state.devices.where((d) => d.id != deviceId).toList(),
      links: state.links
          .where((l) => l.fromDeviceId != deviceId && l.toDeviceId != deviceId)
          .toList(),
    );
  }

  /// Update a device's position
  void updateDevicePosition(String deviceId, Offset newPosition) {
    final updatedDevices = state.devices.map((device) {
      if (device.id == deviceId) {
        return device.copyWith(position: newPosition);
      }
      return device;
    }).toList();

    state = state.copyWith(devices: updatedDevices);
  }

  /// Select a device
  void selectDevice(String deviceId) {
    final updatedDevices = state.devices.map((device) {
      return device.copyWith(isSelected: device.id == deviceId);
    }).toList();

    state = state.copyWith(devices: updatedDevices);
  }

  /// Deselect all devices
  void deselectAllDevices() {
    final updatedDevices = state.devices.map((device) {
      return device.copyWith(isSelected: false);
    }).toList();

    state = state.copyWith(devices: updatedDevices);
  }

  /// Add a link between two devices
  void addLink(DeviceLink link) {
    state = state.copyWith(links: [...state.links, link]);
  }

  /// Remove a link
  void removeLink(String linkId) {
    state = state.copyWith(
      links: state.links.where((l) => l.id != linkId).toList(),
    );
  }

  /// Start linking mode
  void startLinking(String fromDeviceId) {
    state = state.copyWith(
      isLinkingMode: true,
      linkingFromDeviceId: fromDeviceId,
    );
  }

  /// Complete linking
  void completeLinking(String toDeviceId) {
    if (state.linkingFromDeviceId != null &&
        state.linkingFromDeviceId != toDeviceId) {
      final link = DeviceLink(
        id: '${state.linkingFromDeviceId}_$toDeviceId',
        fromDeviceId: state.linkingFromDeviceId!,
        toDeviceId: toDeviceId,
      );
      addLink(link);
    }
    cancelLinking();
  }

  /// Cancel linking mode
  void cancelLinking() {
    state = state.copyWith(
      isLinkingMode: false,
      clearLinkingFromDeviceId: true,
    );
  }

  /// Update device status
  void updateDeviceStatus(String deviceId, DeviceStatus status) {
    final updatedDevices = state.devices.map((device) {
      if (device.id == deviceId) {
        return device.copyWith(status: status);
      }
      return device;
    }).toList();

    state = state.copyWith(devices: updatedDevices);
  }

  /// Clear all devices and links
  void clearCanvas() {
    state = CanvasState();
  }
}

/// Provider for canvas state
final canvasProvider = NotifierProvider<CanvasNotifier, CanvasState>(() {
  return CanvasNotifier();
});
