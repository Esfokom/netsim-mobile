import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart'
    as canvas_model;
import 'package:netsim_mobile/features/canvas/data/models/device_link.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/network_device.dart';

/// State class for managing canvas devices and links
class CanvasState {
  final List<canvas_model.CanvasDevice> devices;
  final List<DeviceLink> links;
  final double scale;
  final bool isLinkingMode;
  final String? linkingFromDeviceId;
  final Map<String, NetworkDevice>
  networkDevices; // Cache of NetworkDevice instances

  CanvasState({
    this.devices = const [],
    this.links = const [],
    this.scale = 1.0,
    this.isLinkingMode = false,
    this.linkingFromDeviceId,
    this.networkDevices = const {},
  });

  CanvasState copyWith({
    List<canvas_model.CanvasDevice>? devices,
    List<DeviceLink>? links,
    double? scale,
    bool? isLinkingMode,
    String? linkingFromDeviceId,
    bool clearLinkingFromDeviceId = false,
    Map<String, NetworkDevice>? networkDevices,
  }) {
    return CanvasState(
      devices: devices ?? this.devices,
      links: links ?? this.links,
      scale: scale ?? this.scale,
      isLinkingMode: isLinkingMode ?? this.isLinkingMode,
      linkingFromDeviceId: clearLinkingFromDeviceId
          ? null
          : (linkingFromDeviceId ?? this.linkingFromDeviceId),
      networkDevices: networkDevices ?? this.networkDevices,
    );
  }

  // Statistics
  int get totalDevices => devices.length;
  int get devicesOnline =>
      devices.where((d) => d.status == canvas_model.DeviceStatus.online).length;
  int get devicesOffline => devices
      .where((d) => d.status == canvas_model.DeviceStatus.offline)
      .length;
  int get devicesWithWarning => devices
      .where((d) => d.status == canvas_model.DeviceStatus.warning)
      .length;
  int get devicesWithError =>
      devices.where((d) => d.status == canvas_model.DeviceStatus.error).length;
}

/// Notifier for managing canvas state
class CanvasNotifier extends Notifier<CanvasState> {
  @override
  CanvasState build() {
    return CanvasState();
  }

  /// Add a device to the canvas
  void addDevice(canvas_model.CanvasDevice device) {
    state = state.copyWith(devices: [...state.devices, device]);
  }

  /// Set or update a NetworkDevice instance in the cache
  void setNetworkDevice(String deviceId, NetworkDevice networkDevice) {
    final updatedNetworkDevices = Map<String, NetworkDevice>.from(
      state.networkDevices,
    );
    updatedNetworkDevices[deviceId] = networkDevice;
    state = state.copyWith(networkDevices: updatedNetworkDevices);
  }

  /// Get a NetworkDevice from the cache
  NetworkDevice? getNetworkDevice(String deviceId) {
    return state.networkDevices[deviceId];
  }

  /// Remove a device from the canvas
  void removeDevice(String deviceId) {
    final updatedNetworkDevices = Map<String, NetworkDevice>.from(
      state.networkDevices,
    );
    updatedNetworkDevices.remove(deviceId);

    state = state.copyWith(
      devices: state.devices.where((d) => d.id != deviceId).toList(),
      links: state.links
          .where((l) => l.fromDeviceId != deviceId && l.toDeviceId != deviceId)
          .toList(),
      networkDevices: updatedNetworkDevices,
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
  void updateDeviceStatus(String deviceId, canvas_model.DeviceStatus status) {
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

  /// Refresh a device to trigger UI update (when properties change)
  void refreshDevice(String deviceId) {
    // Force a state update by creating a new list
    state = state.copyWith(devices: [...state.devices]);
  }
}

/// Provider for canvas state
final canvasProvider = NotifierProvider<CanvasNotifier, CanvasState>(() {
  return CanvasNotifier();
});
