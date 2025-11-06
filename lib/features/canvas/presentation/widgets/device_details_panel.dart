import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/canvas/domain/interfaces/device_capability.dart';
import 'package:netsim_mobile/features/canvas/domain/interfaces/device_property.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';

/// Device Details Panel - Shows device properties and available actions
class DeviceDetailsPanel extends ConsumerWidget {
  final NetworkDevice device;
  final VoidCallback onClose;

  const DeviceDetailsPanel({
    super.key,
    required this.device,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasNotifier = ref.read(canvasProvider.notifier);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: device.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(device.icon, size: 32, color: device.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        device.deviceType,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: device.status.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: device.status.color),
                  ),
                  child: Text(
                    device.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: device.status.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.link),
                  tooltip: 'Create Link',
                  onPressed: () {
                    canvasNotifier.startLinking(device.deviceId);
                    onClose();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Device',
                  onPressed: () {
                    canvasNotifier.removeDevice(device.deviceId);
                    onClose();
                  },
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Properties Section
                  if (device.properties.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Properties',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    ...device.properties.map(
                      (property) =>
                          _PropertyWidget(property: property, device: device),
                    ),
                  ],

                  // Actions Section
                  if (device.getAvailableActions().isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: device.getAvailableActions().map((action) {
                          return _ActionChip(action: action, device: device);
                        }).toList(),
                      ),
                    ),
                  ],

                  // Capabilities Section
                  if (device.capabilities.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'Capabilities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: device.capabilities.map((capability) {
                          return Chip(
                            label: Text(
                              capability.capabilityName,
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: device.color.withValues(
                              alpha: 0.1,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying and editing device properties
class _PropertyWidget extends ConsumerStatefulWidget {
  final DeviceProperty property;
  final NetworkDevice device;

  const _PropertyWidget({required this.property, required this.device});

  @override
  ConsumerState<_PropertyWidget> createState() => _PropertyWidgetState();
}

class _PropertyWidgetState extends ConsumerState<_PropertyWidget> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.property.value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If read-only or not editable, just display
    if (widget.property.isReadOnly ||
        widget.property.buildEditWidget((v) {}) == null) {
      return widget.property.buildDisplayWidget();
    }

    // Check if this is an IP address property for end devices
    final isEditableIpProperty =
        widget.property is IpAddressProperty &&
        widget.device is EndDevice &&
        (widget.device as EndDevice).canEditIpAddress;

    if (!isEditableIpProperty) {
      return widget.property.buildDisplayWidget();
    }

    // Show editable IP address field
    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: widget.property.label,
                  hintText: '192.168.1.1',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.settings_ethernet),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {
                final newValue = _controller.text;
                if (widget.device is EndDevice) {
                  final endDevice = widget.device as EndDevice;

                  // Update based on which property this is
                  if (widget.property.id == 'currentIp') {
                    endDevice.setStaticIp(
                      newValue,
                      endDevice.currentSubnetMask ?? '255.255.255.0',
                      endDevice.currentDefaultGateway ?? '192.168.1.1',
                    );
                  } else if (widget.property.id == 'currentSubnet') {
                    endDevice.setStaticIp(
                      endDevice.currentIpAddress ?? '192.168.1.1',
                      newValue,
                      endDevice.currentDefaultGateway ?? '192.168.1.1',
                    );
                  } else if (widget.property.id == 'currentGateway') {
                    endDevice.setStaticIp(
                      endDevice.currentIpAddress ?? '192.168.1.1',
                      endDevice.currentSubnetMask ?? '255.255.255.0',
                      newValue,
                    );
                  }

                  // Trigger rebuild by deselecting and reselecting
                  ref.read(canvasProvider.notifier).deselectAllDevices();
                  ref
                      .read(canvasProvider.notifier)
                      .selectDevice(widget.device.deviceId);
                }
                setState(() => _isEditing = false);
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                _controller.text = widget.property.value.toString();
                setState(() => _isEditing = false);
              },
            ),
          ],
        ),
      );
    }

    // Show display with edit button
    return InkWell(
      onTap: () => setState(() => _isEditing = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(child: widget.property.buildDisplayWidget()),
            Icon(Icons.edit, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends ConsumerWidget {
  final DeviceAction action;
  final NetworkDevice device;

  const _ActionChip({required this.action, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasNotifier = ref.read(canvasProvider.notifier);

    return ActionChip(
      avatar: Icon(action.icon, size: 18),
      label: Text(action.label),
      onPressed: action.isEnabled
          ? () {
              // Handle special canvas actions
              if (action.id == 'delete' || action.id.contains('delete')) {
                canvasNotifier.removeDevice(device.deviceId);
                Navigator.pop(context);
              } else if (action.id == 'connect_cable' ||
                  action.id.contains('link')) {
                canvasNotifier.startLinking(device.deviceId);
                Navigator.pop(context);
              } else {
                // Execute the device's own action
                action.onExecute();
              }
            }
          : null,
      backgroundColor: action.isEnabled
          ? Theme.of(context).colorScheme.secondaryContainer
          : Colors.grey[300],
      labelStyle: TextStyle(
        color: action.isEnabled
            ? Theme.of(context).colorScheme.onSecondaryContainer
            : Colors.grey[600],
      ),
    );
  }
}
