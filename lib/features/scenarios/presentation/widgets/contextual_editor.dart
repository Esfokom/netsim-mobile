import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/device_rule.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/device_rules_editor.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/device_dialogs.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/ip_configuration_dialog.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/data/models/device_link.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart'
    as network;
import 'package:netsim_mobile/features/devices/domain/entities/router_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/firewall_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/wireless_access_point.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_property.dart';
import 'package:netsim_mobile/features/devices/domain/entities/switch_device.dart';
import 'package:netsim_mobile/core/utils/ip_validator.dart';

/// Contextual editor that shows scenario metadata or device properties
class ContextualEditor extends ConsumerStatefulWidget {
  final bool simulationMode;

  const ContextualEditor({super.key, this.simulationMode = false});

  @override
  ConsumerState<ContextualEditor> createState() => _ContextualEditorState();
}

class _ContextualEditorState extends ConsumerState<ContextualEditor> {
  // Helper method to format display mode names
  String _formatDisplayModeName(String value) {
    switch (value) {
      case 'hostname':
        return 'Hostname';
      case 'ipAddress':
        return 'IP Address';
      case 'macAddress':
        return 'MAC Address';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenarioState = ref.watch(scenarioProvider);
    final canvasState = ref.watch(canvasProvider);

    // In simulation mode, only show device properties if device selected
    if (widget.simulationMode) {
      CanvasDevice? selectedDevice;
      if (scenarioState.selectedDeviceId != null) {
        try {
          selectedDevice = canvasState.devices.firstWhere(
            (d) => d.id == scenarioState.selectedDeviceId,
          );
        } catch (e) {
          // Device not found, clear selection
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(scenarioProvider.notifier).selectDevice(null);
          });
        }
      }

      Widget content;
      if (selectedDevice != null) {
        content = _buildDevicePropertiesEditor(
          selectedDevice,
          simulationMode: true,
        );
      } else {
        content = Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select a device to view its properties',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        );
      }

      return content;
    }

    // Edit mode: show full editor
    CanvasDevice? selectedDevice;
    if (scenarioState.selectedDeviceId != null) {
      try {
        selectedDevice = canvasState.devices.firstWhere(
          (d) => d.id == scenarioState.selectedDeviceId,
        );
      } catch (e) {
        // Device not found, clear selection
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(scenarioProvider.notifier).selectDevice(null);
        });
      }
    }

    Widget content;
    if (selectedDevice != null) {
      // Show device properties editor
      content = _buildDevicePropertiesEditor(selectedDevice);
    } else {
      // Show "no device selected" message
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No Device Selected',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap on a device on the canvas to view and edit its properties',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return content;
  }

  Widget _buildDevicePropertiesEditor(
    CanvasDevice device, {
    bool simulationMode = false,
  }) {
    final canvasNotifier = ref.read(canvasProvider.notifier);
    final canvasState = ref.watch(canvasProvider);
    final networkDevice = canvasNotifier.getNetworkDevice(device.id);
    final scenarioNotifier = ref.read(scenarioProvider.notifier);

    // Show linking mode message if in linking mode
    if (canvasState.isLinkingMode && canvasState.linkingFromDeviceId != null) {
      final linkingFromDevice = canvasState.devices
          .where((d) => d.id == canvasState.linkingFromDeviceId)
          .firstOrNull;

      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.cable, size: 64, color: Colors.blue.shade600),
                  const SizedBox(height: 16),
                  Text(
                    'Linking Mode',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (linkingFromDevice != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'From: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Icon(
                          linkingFromDevice.type.icon,
                          size: 18,
                          color: linkingFromDevice.type.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          linkingFromDevice.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Click on a device on the canvas to create a link',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      canvasNotifier.cancelLinking();
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel Linking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(device.type.icon, color: device.type.color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      device.type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: device.status.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: device.status.color),
                ),
                child: Text(
                  device.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: device.status.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  ref.read(scenarioProvider.notifier).selectDevice(null);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Link action
              ActionChip(
                avatar: const Icon(Icons.link, size: 18),
                label: const Text('Create Link'),
                onPressed: () {
                  canvasNotifier.startLinking(device.id);
                  ref.read(scenarioProvider.notifier).selectDevice(null);
                },
              ),
              // Remove Link action (only show if device has connections and user has permission)
              if (canvasState.links.any(
                    (link) =>
                        link.fromDeviceId == device.id ||
                        link.toDeviceId == device.id,
                  ) &&
                  (!simulationMode ||
                      ref
                          .read(scenarioProvider.notifier)
                          .isActionAllowed(
                            device.id,
                            DeviceActionType.removeLink,
                          )))
                ActionChip(
                  avatar: const Icon(Icons.link_off, size: 18),
                  label: const Text('Remove Link'),
                  onPressed: () {
                    _showRemoveLinkDialog(device, canvasState);
                  },
                ),
              // Delete action
              ActionChip(
                avatar: const Icon(Icons.delete, size: 18),
                label: const Text('Delete'),
                onPressed: () {
                  // Find links connected to this device
                  final canvasState = ref.read(canvasProvider);
                  final connectedLinks = canvasState.links
                      .where(
                        (link) =>
                            link.fromDeviceId == device.id ||
                            link.toDeviceId == device.id,
                      )
                      .toList();

                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Device'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Delete ${device.name}?'),
                          if (connectedLinks.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 20,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'This device has ${connectedLinks.length} active connection${connectedLinks.length > 1 ? 's' : ''}. All links will be removed.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Remove all connected links first
                            for (final link in connectedLinks) {
                              canvasNotifier.removeLink(link.id);
                            }
                            // Then remove the device
                            canvasNotifier.removeDevice(device.id);
                            ref
                                .read(scenarioProvider.notifier)
                                .selectDevice(null);
                            Navigator.pop(ctx);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Basic Properties Section (Compact with Dialog Editing)
          if (!simulationMode) ...[
            Text(
              'Basic Properties',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            _buildCompactPropertyCard(
              context,
              device,
              canvasState,
              canvasNotifier,
            ),
            const SizedBox(height: 24),
          ],

          // Device-Specific Actions (from NetworkDevice)
          if (networkDevice != null) ...[
            Text(
              'Device Actions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: networkDevice.getAvailableActions().map((action) {
                // Determine the action type for rule checking
                DeviceActionType? actionType;
                if (action.label.toLowerCase().contains('power on')) {
                  actionType = DeviceActionType.powerOn;
                } else if (action.label.toLowerCase().contains('power off')) {
                  actionType = DeviceActionType.powerOff;
                }

                // Check if action is allowed in simulation mode
                final isAllowed =
                    !simulationMode ||
                    actionType == null ||
                    scenarioNotifier.isActionAllowed(device.id, actionType);

                return ActionChip(
                  avatar: Icon(action.icon, size: 18),
                  label: Text(action.label),
                  onPressed: action.isEnabled && isAllowed
                      ? () {
                          // Handle special UI actions
                          if (action.id == 'configure_ports' &&
                              networkDevice is SwitchDevice) {
                            showDialog(
                              context: context,
                              builder: (ctx) => PortConfigurationDialog(
                                device: networkDevice,
                                onUpdate: (updatedDevice) {
                                  // Read-only for now - no update needed
                                },
                              ),
                            );
                            return;
                          } else if (action.id == 'view_arp_cache' &&
                              networkDevice is EndDevice) {
                            showDialog(
                              context: context,
                              builder: (ctx) =>
                                  ArpCacheDialog(device: networkDevice),
                            );
                            return;
                          } else if (action.id == 'view_cam_table' &&
                              networkDevice is SwitchDevice) {
                            showDialog(
                              context: context,
                              builder: (ctx) =>
                                  CamTableDialog(device: networkDevice),
                            );
                            return;
                          } else if (action.id == 'adjust_port_count' &&
                              networkDevice is SwitchDevice) {
                            showDialog(
                              context: context,
                              builder: (ctx) => PortCountDialog(
                                device: networkDevice,
                                onUpdate: (newCount) {
                                  // Port count adjustment is handled by the device itself
                                  // Just trigger a rebuild
                                  setState(() {});
                                },
                              ),
                            );
                            return;
                          }
                          // Router-specific actions
                          else if (action.id == 'view_routing_table' &&
                              networkDevice is RouterDevice) {
                            showDialog(
                              context: context,
                              builder: (ctx) =>
                                  RoutingTableDialog(router: networkDevice),
                            );
                            return;
                          } else if (action.id == 'view_interfaces' &&
                              networkDevice is RouterDevice) {
                            showDialog(
                              context: context,
                              builder: (ctx) =>
                                  RouterInterfacesDialog(router: networkDevice),
                            );
                            return;
                          } else if (action.id == 'view_arp_eth0' &&
                              networkDevice is RouterDevice) {
                            showDialog(
                              context: context,
                              builder: (ctx) => RouterArpCacheDialog(
                                router: networkDevice,
                                interfaceName: 'eth0',
                              ),
                            );
                            return;
                          } else if (action.id == 'view_arp_eth1' &&
                              networkDevice is RouterDevice) {
                            showDialog(
                              context: context,
                              builder: (ctx) => RouterArpCacheDialog(
                                router: networkDevice,
                                interfaceName: 'eth1',
                              ),
                            );
                            return;
                          }
                          // Router configuration actions
                          else if (action.id == 'add_static_route' &&
                              networkDevice is RouterDevice) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AddStaticRouteDialog(
                                router: networkDevice,
                                onRouteAdded: () {
                                  setState(() {});
                                  canvasNotifier.refreshDevice(device.id);
                                },
                              ),
                            );
                            return;
                          } else if (action.id == 'configure_interface' &&
                              networkDevice is RouterDevice) {
                            // Show dialog to select which interface
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Select Interface'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: networkDevice.interfaces.keys.map((
                                    ifaceName,
                                  ) {
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.settings_ethernet,
                                      ),
                                      title: Text(ifaceName.toUpperCase()),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        showDialog(
                                          context: context,
                                          builder: (ctx2) =>
                                              ConfigureInterfaceDialog(
                                                router: networkDevice,
                                                interfaceName: ifaceName,
                                                onConfigured: () {
                                                  setState(() {});
                                                  canvasNotifier.refreshDevice(
                                                    device.id,
                                                  );
                                                },
                                              ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                            return;
                          }
                          // EndDevice IP configuration action
                          else if (action.id == 'configure_ip' &&
                              networkDevice is EndDevice) {
                            final endDevice = networkDevice;
                            final allDevices = canvasState.networkDevices.values
                                .toList();

                            showDialog(
                              context: context,
                              builder: (ctx) => IpConfigurationDialog(
                                device: endDevice,
                                allDevices: allDevices,
                                onSave: (ip, subnet, gateway) {
                                  // Update device configuration
                                  endDevice.setStaticIp(ip, subnet, gateway);

                                  // Refresh canvas
                                  canvasNotifier.refreshDevice(device.id);

                                  // Force rebuild
                                  setState(() {});
                                },
                              ),
                            );
                            return;
                          }
                          // EndDevice routing table action
                          else if (action.id == 'view_routing_table' &&
                              networkDevice is EndDevice) {
                            showDialog(
                              context: context,
                              builder: (ctx) => EndDeviceNetworkInfoDialog(
                                device: networkDevice,
                              ),
                            );
                            return;
                          }

                          // Execute the action
                          action.onExecute();

                          // Map NetworkDevice status to CanvasDevice status
                          final canvasStatus = _mapToCanvasStatus(
                            networkDevice.status,
                          );

                          // Update the device status based on current network device status
                          canvasNotifier.updateDeviceStatus(
                            device.id,
                            canvasStatus,
                          );

                          // Force rebuild to reflect changes
                          setState(() {});

                          // Refresh the canvas to update visuals
                          canvasNotifier.refreshDevice(device.id);
                        }
                      : null,
                  backgroundColor: action.isEnabled && isAllowed
                      ? null
                      : Colors.grey.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
          ],

          // Simulation mode info banner
          if (simulationMode) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Simulation Mode: Some actions may be restricted based on scenario rules',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Network Properties Section
          if (networkDevice != null) ...[
            Text(
              'Network Properties',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),

            _buildCompactNetworkProperties(
              device,
              networkDevice,
              canvasNotifier,
              simulationMode: simulationMode,
            ),

            const SizedBox(height: 16),

            // Capabilities
            Text(
              'Capabilities',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: networkDevice.capabilities.map((capability) {
                return Chip(
                  label: Text(
                    capability.toString(),
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Connected Devices Section
            _buildConnectedDevicesSection(
              device,
              canvasState,
              simulationMode: simulationMode,
            ),

            const SizedBox(height: 24),

            // Simulation Rules (only in edit mode)
            if (!simulationMode) DeviceRulesEditor(deviceId: device.id),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Click device on canvas to load network properties',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactNetworkProperties(
    CanvasDevice device,
    network.NetworkDevice networkDevice,
    CanvasNotifier canvasNotifier, {
    bool simulationMode = false,
  }) {
    final scenarioNotifier = ref.read(scenarioProvider.notifier);

    // Filter out properties we don't want to show or show separately
    final filteredProperties = networkDevice.properties.where((prop) {
      // Skip device name (already in basic properties)
      if (prop.id == 'name') return false;

      // Skip displayMode and displayInterface (we'll show them separately)
      if (prop.id == 'displayMode' || prop.id == 'displayInterface')
        return false;

      // Check permission in simulation mode
      if (simulationMode) {
        final permission = scenarioNotifier.getPropertyPermission(
          device.id,
          DeviceActionType.editProperty,
          propertyId: prop.id,
        );
        if (permission == PropertyPermission.denied) return false;
      }

      return true;
    }).toList();

    // Get displayMode property separately
    final displayModeProperty = networkDevice.properties
        .where((p) => p.id == 'displayMode')
        .firstOrNull;

    // Get displayInterface property separately
    final displayInterfaceProperty = networkDevice.properties
        .where((p) => p.id == 'displayInterface')
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display Mode Dropdown (if property exists and not denied)
          if (displayModeProperty != null &&
              displayModeProperty is SelectionProperty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.label, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Canvas Display',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  DropdownButton<String>(
                    value: displayModeProperty.value,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: displayModeProperty.options.map((option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(
                          _formatDisplayModeName(option),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        final permission = simulationMode
                            ? scenarioNotifier.getPropertyPermission(
                                device.id,
                                DeviceActionType.editProperty,
                                propertyId: displayModeProperty.id,
                              )
                            : PropertyPermission.editable;

                        if (permission == PropertyPermission.editable) {
                          displayModeProperty.value = newValue;

                          // Update the actual device field
                          if (networkDevice is EndDevice) {
                            switch (newValue) {
                              case 'hostname':
                                networkDevice.displayMode =
                                    DeviceDisplayMode.hostname;
                                break;
                              case 'ipAddress':
                                networkDevice.displayMode =
                                    DeviceDisplayMode.ipAddress;
                                break;
                              case 'macAddress':
                                networkDevice.displayMode =
                                    DeviceDisplayMode.macAddress;
                                break;
                            }
                          } else if (networkDevice is RouterDevice) {
                            networkDevice.showIpOnCanvas =
                                (newValue == 'ipAddress');
                          } else if (networkDevice is FirewallDevice) {
                            networkDevice.showIpOnCanvas =
                                (newValue == 'ipAddress');
                          } else if (networkDevice is WirelessAccessPoint) {
                            networkDevice.showIpOnCanvas =
                                (newValue == 'ipAddress');
                          }

                          canvasNotifier.refreshDevice(device.id);
                          setState(() {});
                        }
                      }
                    },
                  ),
                ],
              ),
            ),

            // Display Interface Dropdown (conditional - only for EndDevice with multiple interfaces)
            if (displayInterfaceProperty != null &&
                displayInterfaceProperty is SelectionProperty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.cable, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Interface',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: displayInterfaceProperty.value,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      items: displayInterfaceProperty.options.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(
                            option,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          final permission = simulationMode
                              ? scenarioNotifier.getPropertyPermission(
                                  device.id,
                                  DeviceActionType.editProperty,
                                  propertyId: displayInterfaceProperty.id,
                                )
                              : PropertyPermission.editable;

                          if (permission == PropertyPermission.editable) {
                            displayInterfaceProperty.value = newValue;

                            // Update the actual device field
                            if (networkDevice is EndDevice) {
                              networkDevice.displayInterfaceName = newValue;
                            }

                            canvasNotifier.refreshDevice(device.id);
                            setState(() {});
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],

            if (filteredProperties.isNotEmpty)
              Divider(height: 16, color: Colors.grey.withValues(alpha: 0.2)),
          ],

          // Compact property rows - tap to expand in dialog
          ...filteredProperties.asMap().entries.map((entry) {
            final index = entry.key;
            final property = entry.value;

            final permission = simulationMode
                ? scenarioNotifier.getPropertyPermission(
                    device.id,
                    DeviceActionType.editProperty,
                    propertyId: property.id,
                  )
                : PropertyPermission.editable;

            final canEdit = permission == PropertyPermission.editable;

            return Column(
              children: [
                InkWell(
                  onTap: canEdit
                      ? () => _showPropertyEditDialog(
                          device,
                          networkDevice,
                          property,
                          canvasNotifier,
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _getPropertyIcon(property),
                          size: 14,
                          color: permission == PropertyPermission.readonly
                              ? Colors.orange.shade600
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                property.value.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      permission == PropertyPermission.readonly
                                      ? Colors.orange.shade700
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (canEdit)
                          Icon(
                            Icons.edit,
                            size: 14,
                            color: Colors.grey.shade500,
                          )
                        else if (permission == PropertyPermission.readonly)
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: Colors.orange.shade600,
                          ),
                      ],
                    ),
                  ),
                ),
                if (index < filteredProperties.length - 1)
                  Divider(height: 8, color: Colors.grey.withValues(alpha: 0.2)),
              ],
            );
          }),
        ],
      ),
    );
  }

  IconData _getPropertyIcon(DeviceProperty property) {
    if (property.id.contains('ip') || property.id.contains('Ip')) {
      return Icons.lan;
    } else if (property.id.contains('mac') || property.id.contains('Mac')) {
      return Icons.fingerprint;
    } else if (property.id == 'powerState') {
      return Icons.power_settings_new;
    } else if (property.id == 'linkState') {
      return Icons.link;
    } else if (property.id.contains('hostname')) {
      return Icons.dns;
    } else if (property.id.contains('enabled') ||
        property.id.contains('Enabled')) {
      return Icons.toggle_on;
    } else if (property.id.contains('count') || property.id.contains('Count')) {
      return Icons.numbers;
    }
    return Icons.settings;
  }

  void _showPropertyEditDialog(
    CanvasDevice device,
    network.NetworkDevice networkDevice,
    DeviceProperty property,
    CanvasNotifier canvasNotifier,
  ) {
    // Handle specific property types
    if (property.id == 'powerState' || property.label == 'Power') {
      _showPowerDialog(device, networkDevice, canvasNotifier);
    } else if (property.id.toLowerCase().contains('mac')) {
      _showMacAddressDialog(device, networkDevice, property, canvasNotifier);
    } else if (property.id == 'linkState' ||
        property.label.toLowerCase().contains('link')) {
      _showLinkStateDialog(device, networkDevice, ref.read(canvasProvider));
    } else if (property.id.toLowerCase().contains('ip') &&
        (property.label.contains('Address') || property.label.contains('IP'))) {
      _showIpConfigurationDialog(device, networkDevice, canvasNotifier);
    } else {
      // Generic property editor
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Edit ${property.label}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current value:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              property.buildEditWidget((newValue) {
                    property.value = newValue;
                    canvasNotifier.refreshDevice(device.id);
                  }) ??
                  property.buildDisplayWidget(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${property.label} updated'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildConnectedDevicesSection(
    CanvasDevice device,
    CanvasState canvasState, {
    bool simulationMode = false,
  }) {
    // Find all links connected to this device
    final connectedLinks = canvasState.links
        .where(
          (link) =>
              link.fromDeviceId == device.id || link.toDeviceId == device.id,
        )
        .toList();

    // Check if user has permission to remove links in simulation mode
    final canRemoveLinks =
        !simulationMode ||
        ref
            .read(scenarioProvider.notifier)
            .isActionAllowed(device.id, DeviceActionType.removeLink);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connected Devices',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        if (connectedLinks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.link_off, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No connections. Click "Create Link" to connect this device.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          )
        else
          ...connectedLinks.map((link) {
            // Determine the other device in the link
            final otherDeviceId = link.fromDeviceId == device.id
                ? link.toDeviceId
                : link.fromDeviceId;

            final otherDevice = canvasState.devices
                .where((d) => d.id == otherDeviceId)
                .firstOrNull;

            if (otherDevice == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    otherDevice.type.icon,
                    size: 24,
                    color: otherDevice.type.color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherDevice.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              _getLinkTypeIcon(link.type),
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${link.type.displayName} • ${otherDevice.type.displayName}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'ID: ${otherDevice.id}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Only show disconnect button if user has permission
                  if (canRemoveLinks)
                    IconButton(
                      icon: const Icon(Icons.link_off, size: 18),
                      color: Colors.red.shade600,
                      tooltip: 'Disconnect',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Disconnect Devices'),
                            content: Text(
                              'Remove the connection between ${device.name} and ${otherDevice.name}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(canvasProvider.notifier)
                                      .removeLink(link.id);
                                  Navigator.pop(ctx);
                                  setState(() {});
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Disconnect'),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else if (simulationMode)
                    // Show locked icon in simulation mode when permission denied
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showRemoveLinkDialog(CanvasDevice device, CanvasState canvasState) {
    // Find all links connected to this device
    final connectedLinks = canvasState.links
        .where(
          (link) =>
              link.fromDeviceId == device.id || link.toDeviceId == device.id,
        )
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Link'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a connection to remove:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              if (connectedLinks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No connections found',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                )
              else
                ...connectedLinks.map((link) {
                  // Determine the other device in the link
                  final otherDeviceId = link.fromDeviceId == device.id
                      ? link.toDeviceId
                      : link.fromDeviceId;

                  final otherDevice = canvasState.devices
                      .where((d) => d.id == otherDeviceId)
                      .firstOrNull;

                  if (otherDevice == null) return const SizedBox.shrink();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        otherDevice.type.icon,
                        color: otherDevice.type.color,
                      ),
                      title: Text(
                        otherDevice.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${link.type.displayName} • ${otherDevice.type.displayName}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade600,
                        ),
                        tooltip: 'Remove this link',
                        onPressed: () {
                          ref.read(canvasProvider.notifier).removeLink(link.id);
                          Navigator.pop(ctx);
                          setState(() {});

                          // Show confirmation snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Disconnected ${device.name} from ${otherDevice.name}',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getLinkTypeIcon(LinkType type) {
    switch (type) {
      case LinkType.ethernet:
        return Icons.settings_ethernet;
      case LinkType.wireless:
        return Icons.wifi;
      case LinkType.fiber:
        return Icons.fiber_manual_record;
    }
  }

  Widget _buildCompactPropertyCard(
    BuildContext context,
    CanvasDevice device,
    CanvasState canvasState,
    CanvasNotifier canvasNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Device ID Row
          InkWell(
            onTap: () =>
                _showEditDeviceIdDialog(device, canvasState, canvasNotifier),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.tag, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device ID',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          device.id,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit, size: 16, color: Colors.grey.shade500),
                ],
              ),
            ),
          ),
          Divider(height: 16, color: Colors.grey.withValues(alpha: 0.2)),

          // Device Name Row
          InkWell(
            onTap: () =>
                _showEditNameDialog(device, canvasState, canvasNotifier),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.label, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit, size: 16, color: Colors.grey.shade500),
                ],
              ),
            ),
          ),
          Divider(height: 16, color: Colors.grey.withValues(alpha: 0.2)),

          // Position Row
          InkWell(
            onTap: () => _showEditPositionDialog(device, canvasNotifier),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Position',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          'X: ${device.position.dx.toStringAsFixed(0)}, Y: ${device.position.dy.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit, size: 16, color: Colors.grey.shade500),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDeviceIdDialog(
    CanvasDevice device,
    CanvasState canvasState,
    CanvasNotifier canvasNotifier,
  ) {
    // Check if device has links
    final hasLinks = canvasState.links.any(
      (link) => link.fromDeviceId == device.id || link.toDeviceId == device.id,
    );

    // If device has links, show warning and don't allow editing
    if (hasLinks) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot Edit Device ID'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This device has active connections',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Device ID cannot be changed while the device has links. Remove all connections first.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final controller = TextEditingController(text: device.id);
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Device ID'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device ID must be exactly 13 digits',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Device ID',
                    border: const OutlineInputBorder(),
                    errorText: errorText,
                    counterText: '${controller.text.length}/13',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 13,
                  onChanged: (value) {
                    setDialogState(() {
                      // Validate format
                      if (value.isEmpty) {
                        errorText = 'Device ID cannot be empty';
                      } else if (value.length != 13) {
                        errorText = 'Must be exactly 13 digits';
                      } else if (!RegExp(r'^\d+$').hasMatch(value)) {
                        errorText = 'Must contain only digits';
                      } else if (value != device.id &&
                          canvasState.devices.any((d) => d.id == value)) {
                        errorText = 'Device ID already exists';
                      } else {
                        errorText = null;
                      }
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: errorText == null && controller.text.length == 13
                    ? () {
                        final newId = controller.text;
                        canvasNotifier.updateDeviceId(device.id, newId);
                        setState(() {});
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Device ID updated to $newId'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditNameDialog(
    CanvasDevice device,
    CanvasState canvasState,
    CanvasNotifier canvasNotifier,
  ) {
    final controller = TextEditingController(text: device.name);
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Device Name'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a unique name for this device',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Device Name',
                    border: const OutlineInputBorder(),
                    errorText: errorText,
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      // Validate
                      if (value.trim().isEmpty) {
                        errorText = 'Device name cannot be empty';
                      } else if (value.trim() != device.name &&
                          canvasState.devices.any(
                            (d) => d.name.trim() == value.trim(),
                          )) {
                        errorText = 'Device name already exists';
                      } else {
                        errorText = null;
                      }
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    errorText == null && controller.text.trim().isNotEmpty
                    ? () {
                        final newName = controller.text.trim();
                        canvasNotifier.updateDeviceName(device.id, newName);
                        setState(() {});
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Device name updated to $newName'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditPositionDialog(
    CanvasDevice device,
    CanvasNotifier canvasNotifier,
  ) {
    final xController = TextEditingController(
      text: device.position.dx.toStringAsFixed(0),
    );
    final yController = TextEditingController(
      text: device.position.dy.toStringAsFixed(0),
    );
    String? xError;
    String? yError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Position'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Position must be between 0 and 2000 for both X and Y',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: xController,
                  decoration: InputDecoration(
                    labelText: 'X Position',
                    border: const OutlineInputBorder(),
                    errorText: xError,
                    suffixText: 'px',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setDialogState(() {
                      final x = double.tryParse(value);
                      if (value.isEmpty) {
                        xError = 'X position cannot be empty';
                      } else if (x == null) {
                        xError = 'Must be a valid number';
                      } else if (x < 0 || x > 2000) {
                        xError = 'Must be between 0 and 2000';
                      } else {
                        xError = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: yController,
                  decoration: InputDecoration(
                    labelText: 'Y Position',
                    border: const OutlineInputBorder(),
                    errorText: yError,
                    suffixText: 'px',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setDialogState(() {
                      final y = double.tryParse(value);
                      if (value.isEmpty) {
                        yError = 'Y position cannot be empty';
                      } else if (y == null) {
                        yError = 'Must be a valid number';
                      } else if (y < 0 || y > 2000) {
                        yError = 'Must be between 0 and 2000';
                      } else {
                        yError = null;
                      }
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: xError == null && yError == null
                    ? () {
                        final x = double.parse(xController.text);
                        final y = double.parse(yController.text);
                        canvasNotifier.updateDevicePosition(
                          device.id,
                          Offset(x, y),
                        );
                        setState(() {});
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Position updated to X: ${x.toStringAsFixed(0)}, Y: ${y.toStringAsFixed(0)}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPowerDialog(
    CanvasDevice device,
    network.NetworkDevice networkDevice,
    CanvasNotifier canvasNotifier,
  ) {
    // Check if device supports power control
    if (networkDevice is! EndDevice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This device type does not support power control'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final endDevice = networkDevice as EndDevice;
    final isPoweredOn = endDevice.isPoweredOn;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Power Control'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isPoweredOn ? Icons.power : Icons.power_off,
                  color: isPoweredOn ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isPoweredOn
                        ? 'Device is powered ON'
                        : 'Device is powered OFF',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isPoweredOn
                        ? null
                        : () {
                            endDevice.powerOn();
                            canvasNotifier.refreshDevice(device.id);
                            Navigator.pop(ctx);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${device.name} powered ON'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                    icon: const Icon(Icons.power),
                    label: const Text('Power ON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !isPoweredOn
                        ? null
                        : () {
                            endDevice.powerOff();
                            canvasNotifier.refreshDevice(device.id);
                            Navigator.pop(ctx);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${device.name} powered OFF'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                    icon: const Icon(Icons.power_off),
                    label: const Text('Power OFF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMacAddressDialog(
    CanvasDevice device,
    network.NetworkDevice networkDevice,
    DeviceProperty property,
    CanvasNotifier canvasNotifier,
  ) {
    final controller = TextEditingController(text: property.value.toString());
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit MAC Address'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Format: XX:XX:XX:XX:XX:XX (12 hex characters)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'MAC Address',
                    border: const OutlineInputBorder(),
                    errorText: errorText,
                    hintText: '00:1A:2B:3C:4D:5E',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 17,
                  onChanged: (value) {
                    setDialogState(() {
                      // Validate MAC address format
                      final macRegex = RegExp(
                        r'^([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})$',
                      );
                      if (value.isEmpty) {
                        errorText = 'MAC address cannot be empty';
                      } else if (!macRegex.hasMatch(value)) {
                        errorText = 'Invalid MAC address format';
                      } else {
                        errorText = null;
                      }
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: errorText == null && controller.text.isNotEmpty
                    ? () {
                        final newMac = controller.text.toUpperCase();
                        property.value = newMac;

                        // Note: MAC address is typically read-only in network devices
                        // The property value update is sufficient for display purposes

                        canvasNotifier.refreshDevice(device.id);
                        Navigator.pop(ctx);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('MAC Address updated to $newMac'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLinkStateDialog(
    CanvasDevice device,
    network.NetworkDevice networkDevice,
    CanvasState canvasState,
  ) {
    // Check if device is powered on and has links
    final isPoweredOn = networkDevice is EndDevice
        ? (networkDevice as EndDevice).isPoweredOn
        : true; // Other devices are always considered powered on
    final connectedLinks = canvasState.links
        .where(
          (link) =>
              link.fromDeviceId == device.id || link.toDeviceId == device.id,
        )
        .toList();

    final hasLinks = connectedLinks.isNotEmpty;
    final linkState = isPoweredOn && hasLinks ? 'UP' : 'DOWN';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link State'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  linkState == 'UP' ? Icons.link : Icons.link_off,
                  color: linkState == 'UP' ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Link State: $linkState',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: linkState == 'UP' ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        linkState == 'UP'
                            ? 'Device has active connections'
                            : 'No active connections or powered off',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Connected Devices:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (connectedLinks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    'No connections',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...connectedLinks.map((link) {
                final otherDeviceId = link.fromDeviceId == device.id
                    ? link.toDeviceId
                    : link.fromDeviceId;
                final otherDevice = canvasState.devices
                    .where((d) => d.id == otherDeviceId)
                    .firstOrNull;

                if (otherDevice == null) return const SizedBox.shrink();

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: Icon(otherDevice.type.icon, size: 20),
                    title: Text(
                      otherDevice.name,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      link.type.displayName,
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.link_off, size: 18),
                      color: Colors.red.shade600,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (deleteCtx) => AlertDialog(
                            title: const Text('Disconnect'),
                            content: Text(
                              'Remove connection to ${otherDevice.name}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(deleteCtx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(canvasProvider.notifier)
                                      .removeLink(link.id);
                                  Navigator.pop(deleteCtx);
                                  Navigator.pop(ctx);
                                  setState(() {});
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Disconnect'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showIpConfigurationDialog(
    CanvasDevice device,
    network.NetworkDevice networkDevice,
    CanvasNotifier canvasNotifier,
  ) {
    // Only show for devices that support IP configuration
    if (networkDevice is! EndDevice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This device type does not support IP configuration'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Get all network devices for duplicate IP checking
    final allNetworkDevices = ref
        .read(canvasProvider)
        .networkDevices
        .values
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => IpConfigurationDialog(
        device: networkDevice,
        allDevices: allNetworkDevices,
        onSave: (ipAddress, subnetMask, defaultGateway) {
          // Update the device's IP configuration
          networkDevice.setStaticIp(ipAddress, subnetMask, defaultGateway);

          // Refresh the device in canvas
          canvasNotifier.refreshDevice(device.id);

          // Update the UI
          setState(() {});

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('IP configuration updated for ${device.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  network.DeviceStatus _mapToCanvasStatus(network.DeviceStatus networkStatus) {
    // NetworkDevice and CanvasDevice both use the same DeviceStatus enum
    return networkStatus;
  }
}
