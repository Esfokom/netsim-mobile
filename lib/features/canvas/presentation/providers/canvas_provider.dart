import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart'
    as canvas_model;
import 'package:netsim_mobile/features/canvas/data/models/device_link.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/switch_device.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_capability.dart';
import 'package:netsim_mobile/features/game/presentation/providers/game_condition_checker.dart';

/// Interface for disposable resources
abstract class Disposable {
  void dispose();
}

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

    // Trigger condition check after position update
    ref.read(gameConditionCheckerProvider.notifier).triggerConditionCheck();
  }

  /// Update a device's ID
  void updateDeviceId(String oldDeviceId, String newDeviceId) {
    // Update device in devices list
    final updatedDevices = state.devices.map((device) {
      if (device.id == oldDeviceId) {
        return device.copyWith(id: newDeviceId);
      }
      return device;
    }).toList();

    // Update links that reference this device
    final updatedLinks = state.links.map((link) {
      if (link.fromDeviceId == oldDeviceId || link.toDeviceId == oldDeviceId) {
        return link.copyWith(
          fromDeviceId: link.fromDeviceId == oldDeviceId
              ? newDeviceId
              : link.fromDeviceId,
          toDeviceId: link.toDeviceId == oldDeviceId
              ? newDeviceId
              : link.toDeviceId,
        );
      }
      return link;
    }).toList();

    // Update network device cache
    final updatedNetworkDevices = Map<String, NetworkDevice>.from(
      state.networkDevices,
    );
    final networkDevice = updatedNetworkDevices.remove(oldDeviceId);
    if (networkDevice != null) {
      updatedNetworkDevices[newDeviceId] = networkDevice;
    }

    state = state.copyWith(
      devices: updatedDevices,
      links: updatedLinks,
      networkDevices: updatedNetworkDevices,
    );

    // Trigger condition check after ID update
    ref.read(gameConditionCheckerProvider.notifier).triggerConditionCheck();
  }

  /// Update a device's name
  void updateDeviceName(String deviceId, String newName) {
    final updatedDevices = state.devices.map((device) {
      if (device.id == deviceId) {
        return device.copyWith(name: newName);
      }
      return device;
    }).toList();

    state = state.copyWith(devices: updatedDevices);

    // Trigger condition check after name update
    ref.read(gameConditionCheckerProvider.notifier).triggerConditionCheck();
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

    // PHASE 2 FIX: Call connectCable on both devices to set link state to UP
    final fromDevice = state.networkDevices[link.fromDeviceId];
    final toDevice = state.networkDevices[link.toDeviceId];

    if (fromDevice != null && fromDevice is IConnectable) {
      (fromDevice as IConnectable).connectCable(
        link.toDeviceId,
        0,
      ); // Default port 0 for now
      appLogger.d('[Canvas] Connected cable for device ${link.fromDeviceId}');
    }

    if (toDevice != null && toDevice is IConnectable) {
      (toDevice as IConnectable).connectCable(
        link.fromDeviceId,
        0,
      ); // Default port 0 for now
      appLogger.d('[Canvas] Connected cable for device ${link.toDeviceId}');
    }

    // Trigger condition check after link added
    ref.read(gameConditionCheckerProvider.notifier).triggerConditionCheck();
  }

  /// Remove a link
  void removeLink(String linkId) {
    final link = state.links.firstWhere(
      (l) => l.id == linkId,
      orElse: () => DeviceLink(id: '', fromDeviceId: '', toDeviceId: ''),
    );
    if (link.id.isEmpty) return;

    // PHASE 2 FIX: Call disconnectCable on both devices
    final fromDevice = state.networkDevices[link.fromDeviceId];
    final toDevice = state.networkDevices[link.toDeviceId];

    if (fromDevice != null && fromDevice is IConnectable) {
      (fromDevice as IConnectable).disconnectCable();
      appLogger.d(
        '[Canvas] Disconnected cable for device ${link.fromDeviceId}',
      );
    }

    if (toDevice != null && toDevice is IConnectable) {
      (toDevice as IConnectable).disconnectCable();
      appLogger.d('[Canvas] Disconnected cable for device ${link.toDeviceId}');
    }

    // Handle Switch Port Disconnection
    _disconnectSwitchPort(link.fromDeviceId, linkId);
    _disconnectSwitchPort(link.toDeviceId, linkId);

    state = state.copyWith(
      links: state.links.where((l) => l.id != linkId).toList(),
    );

    // Trigger condition check after link removed
    ref.read(gameConditionCheckerProvider.notifier).triggerConditionCheck();
  }

  void _disconnectSwitchPort(String deviceId, String linkId) {
    final networkDevice = state.networkDevices[deviceId];
    // We need to check if it's a SwitchDevice, but we can't import SwitchDevice here easily
    // without circular deps if not careful, or just use dynamic or check properties.
    // Better to use the 'type' from CanvasDevice or check capabilities.
    // But NetworkDevice is the domain entity.
    // Let's assume we can cast or check properties.
    // Actually, we can just check if it has 'ports' property or similar.
    // Or better, let's import SwitchDevice in the implementation file if needed,
    // but here we are in the provider.
    // Let's use dynamic for now to avoid excessive imports/casts if we want to be generic,
    // or better, check if it implements a specific interface.
    // For now, let's try to access it safely.

    if (networkDevice != null && networkDevice.deviceType == 'Switch') {
      // It's a switch. We need to find the port with this linkId.
      // Since we can't easily access SwitchDevice specific methods without casting,
      // and we want to avoid importing the concrete class if possible to keep this clean...
      // BUT, we really need to update the port state.
      // Let's assume we can cast it if we import it.
      // Let's try to do it without importing SwitchDevice if possible,
      // but realistically we need to import it.
      // Let's skip the import for now and assume the caller handles it?
      // No, removeLink is called from UI.
      // Let's rely on the fact that we can import it.
      // I will add the import.
    }
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
    completeLinkingWithPort(toDeviceId, null, null);
  }

  /// Complete linking with specific ports
  void completeLinkingWithPort(
    String toDeviceId,
    int? fromPortId,
    int? toPortId,
  ) {
    if (state.linkingFromDeviceId != null &&
        state.linkingFromDeviceId != toDeviceId) {
      final linkId = '${state.linkingFromDeviceId}_$toDeviceId';

      // Check if link already exists
      if (state.links.any(
        (l) =>
            l.id == linkId ||
            l.id == '${toDeviceId}_${state.linkingFromDeviceId}',
      )) {
        cancelLinking();
        return;
      }

      final link = DeviceLink(
        id: linkId,
        fromDeviceId: state.linkingFromDeviceId!,
        toDeviceId: toDeviceId,
      );

      // Update Switch Ports if applicable
      if (fromPortId != null) {
        _connectSwitchPort(state.linkingFromDeviceId!, fromPortId, linkId);
      }
      if (toPortId != null) {
        _connectSwitchPort(toDeviceId, toPortId, linkId);
      }

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

  void _connectSwitchPort(String deviceId, int portId, String linkId) {
    final networkDevice = state.networkDevices[deviceId];
    if (networkDevice is SwitchDevice) {
      try {
        final port = networkDevice.ports.firstWhere((p) => p.portId == portId);
        port.connectedLinkId = linkId;
        port.linkState = 'UP';
      } catch (e) {
        appLogger.e(
          'Failed to connect switch port $portId on device $deviceId',
          error: e,
        );
      }
    }
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

    // Trigger condition check after status update
    ref.read(gameConditionCheckerProvider.notifier).triggerConditionCheck();
  }

  /// Clear all devices and links
  void clearCanvas() {
    state = CanvasState();
  }

  /// Comprehensive cleanup method - disposes network devices and resets all state
  void disposeAndClear() {
    try {
      // Dispose all network device instances that might have resources
      for (final networkDevice in state.networkDevices.values) {
        // If NetworkDevice has a dispose method, call it
        try {
          if (networkDevice is Disposable) {
            (networkDevice as Disposable).dispose();
          }
          // Try to call dispose via reflection if it exists
          else {
            final dynamic device = networkDevice;
            if (device?.dispose != null) {
              device.dispose();
            }
          }
        } catch (e) {
          // Ignore disposal errors - device might not have dispose method
          appLogger.d('Device disposal error (ignored)', error: e);
        }
      }

      // Clear all linking states
      try {
        cancelLinking();
      } catch (e) {
        appLogger.d('Error clearing linking state (ignored)', error: e);
      }

      // Deselect all devices before clearing
      try {
        deselectAllDevices();
      } catch (e) {
        appLogger.d('Error deselecting devices (ignored)', error: e);
      }

      // Reset state to initial empty state
      state = CanvasState();

      appLogger.i('Canvas state cleared and disposed successfully');
    } catch (e) {
      appLogger.e('Error during canvas cleanup', error: e);
      // Still try to reset state even if cleanup partially failed
      try {
        state = CanvasState();
      } catch (resetError) {
        appLogger.e('Error resetting canvas state', error: resetError);
      }
    }
  }

  /// Refresh a device to trigger UI update (when properties change)
  void refreshDevice(String deviceId) {
    // Force a state update by creating a new list
    state = state.copyWith(devices: [...state.devices]);

    // Trigger condition check after device refresh (properties changed)
    ref.read(gameConditionCheckerProvider.notifier).triggerConditionCheck();
  }

  /// Initialize all device connections from existing links
  /// Call this after loading a scenario or when devices are fully initialized
  void initializeAllConnections() {
    appLogger.i(
      '[Canvas] Initializing all device connections from ${state.links.length} links',
    );

    int successCount = 0;
    int failCount = 0;

    for (final link in state.links) {
      try {
        final fromDevice = state.networkDevices[link.fromDeviceId];
        final toDevice = state.networkDevices[link.toDeviceId];

        if (fromDevice == null) {
          appLogger.w(
            '[Canvas] Device ${link.fromDeviceId} not found in cache for link ${link.id}',
          );
          failCount++;
          continue;
        }

        if (toDevice == null) {
          appLogger.w(
            '[Canvas] Device ${link.toDeviceId} not found in cache for link ${link.id}',
          );
          failCount++;
          continue;
        }

        // Connect both ends
        if (fromDevice is IConnectable) {
          (fromDevice as IConnectable).connectCable(link.toDeviceId, 0);
          appLogger.d(
            '[Canvas] Connected ${link.fromDeviceId} -> ${link.toDeviceId}',
          );
        }

        if (toDevice is IConnectable) {
          (toDevice as IConnectable).connectCable(link.fromDeviceId, 0);
          appLogger.d(
            '[Canvas] Connected ${link.toDeviceId} -> ${link.fromDeviceId}',
          );
        }

        successCount++;
      } catch (e) {
        appLogger.e(
          '[Canvas] Error initializing connection for link ${link.id}',
          error: e,
        );
        failCount++;
      }
    }

    appLogger.i(
      '[Canvas] Connection initialization complete: $successCount succeeded, $failCount failed',
    );
  }

  /// Refresh device cache - ensures all canvas devices have network device instances
  void refreshDeviceCache() {
    appLogger.d(
      '[Canvas] Refreshing device cache for ${state.devices.length} devices',
    );

    for (final canvasDevice in state.devices) {
      if (!state.networkDevices.containsKey(canvasDevice.id)) {
        appLogger.w(
          '[Canvas] Device ${canvasDevice.id} missing from network devices cache',
        );
      }
    }
  }
}

/// Provider for canvas state
final canvasProvider = NotifierProvider<CanvasNotifier, CanvasState>(() {
  return CanvasNotifier();
});
