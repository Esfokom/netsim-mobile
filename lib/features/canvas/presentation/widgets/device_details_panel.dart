import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/core/utils/ip_validator.dart';
import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/firewall_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/router_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/switch_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/wireless_access_point.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_capability.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_property.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/ip_configuration_dialog.dart';

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
  String? _errorText;

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

  void _handleBooleanChange(bool newValue) {
    // Handle boolean property changes
    // Note: showIpOnCanvas has been replaced by displayMode (enum)
    // If any boolean properties are added in the future, handle them here

    // Trigger rebuild by refreshing the device
    ref.read(canvasProvider.notifier).refreshDevice(widget.device.deviceId);
  }

  void _handleSelectionChange(String propertyId, String newValue) {
    // Handle selection property changes (like displayMode)
    if (propertyId == 'displayMode') {
      if (widget.device is EndDevice) {
        final endDevice = widget.device as EndDevice;
        switch (newValue) {
          case 'hostname':
            endDevice.displayMode = DeviceDisplayMode.hostname;
            break;
          case 'ipAddress':
            endDevice.displayMode = DeviceDisplayMode.ipAddress;
            break;
          case 'macAddress':
            endDevice.displayMode = DeviceDisplayMode.macAddress;
            break;
        }
      } else if (widget.device is RouterDevice) {
        (widget.device as RouterDevice).showIpOnCanvas =
            (newValue == 'ipAddress');
      } else if (widget.device is FirewallDevice) {
        (widget.device as FirewallDevice).showIpOnCanvas =
            (newValue == 'ipAddress');
      } else if (widget.device is WirelessAccessPoint) {
        (widget.device as WirelessAccessPoint).showIpOnCanvas =
            (newValue == 'ipAddress');
      }

      ref.read(canvasProvider.notifier).refreshDevice(widget.device.deviceId);
    } else if (propertyId == 'displayInterface') {
      if (widget.device is EndDevice) {
        (widget.device as EndDevice).displayInterfaceName = newValue;
        ref.read(canvasProvider.notifier).refreshDevice(widget.device.deviceId);
      }
    }
  }

  String _formatDisplayName(String value) {
    // Format camelCase to Title Case
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

  void _handleNameChange(String newName) {
    // Handle device name changes
    if (widget.property.id == 'name') {
      if (widget.device is RouterDevice) {
        (widget.device as RouterDevice).name = newName;
      } else if (widget.device is FirewallDevice) {
        (widget.device as FirewallDevice).name = newName;
      } else if (widget.device is SwitchDevice) {
        (widget.device as SwitchDevice).name = newName;
      } else if (widget.device is WirelessAccessPoint) {
        (widget.device as WirelessAccessPoint).name = newName;
      }

      // Trigger rebuild by refreshing the device
      ref.read(canvasProvider.notifier).refreshDevice(widget.device.deviceId);
    } else if (widget.property.id == 'hostname' && widget.device is EndDevice) {
      // Handle hostname changes for EndDevice (Computer/Server)
      (widget.device as EndDevice).hostname = newName;
      ref.read(canvasProvider.notifier).refreshDevice(widget.device.deviceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle boolean properties specially
    if (widget.property is BooleanProperty) {
      final boolProp = widget.property as BooleanProperty;
      return SwitchListTile(
        title: Text(boolProp.label),
        value: boolProp.value,
        onChanged: boolProp.isReadOnly
            ? null
            : (val) {
                setState(() {
                  boolProp.value = val;
                });
                _handleBooleanChange(val);
              },
        dense: true,
      );
    }

    // Handle selection properties (like displayMode, displayInterface)
    if (widget.property is SelectionProperty) {
      final selectionProp = widget.property as SelectionProperty;
      return ListTile(
        leading: const Icon(Icons.settings),
        title: Text(selectionProp.label),
        subtitle: DropdownButton<String>(
          value: selectionProp.value,
          isExpanded: true,
          items: selectionProp.options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(_formatDisplayName(option)),
            );
          }).toList(),
          onChanged: selectionProp.isReadOnly
              ? null
              : (newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectionProp.value = newValue;
                    });
                    _handleSelectionChange(selectionProp.id, newValue);
                  }
                },
        ),
        dense: true,
      );
    }

    // Handle string properties (like device name)
    if (widget.property is StringProperty &&
        (widget.property.id == 'name' || widget.property.id == 'hostname')) {
      final stringProp = widget.property as StringProperty;

      if (_isEditing) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: stringProp.label,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.label),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  final newName = _controller.text.trim();
                  if (newName.isNotEmpty) {
                    _handleNameChange(newName);
                    (widget.property as StringProperty).value = newName;
                  }
                  setState(() {
                    _isEditing = false;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  _controller.text = widget.property.value.toString();
                  setState(() {
                    _isEditing = false;
                  });
                },
              ),
            ],
          ),
        );
      }

      // Display mode with edit button
      return ListTile(
        leading: const Icon(Icons.label),
        title: Text(stringProp.label),
        subtitle: Text(stringProp.value),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () {
            setState(() {
              _isEditing = true;
            });
          },
        ),
        dense: true,
      );
    }

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
                  errorText: _errorText,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: (value) {
                  // Format and validate input in real-time
                  final formatted = IpValidator.formatIpInput(value);
                  if (formatted != value) {
                    _controller.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }

                  // Update error text
                  setState(() {
                    _errorText = IpValidator.getValidationError(formatted);
                  });
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: _errorText != null
                  ? null
                  : () {
                      final newValue = _controller.text;

                      // Final validation before saving
                      if (!IpValidator.isValidIpv4(newValue)) {
                        setState(() {
                          _errorText = IpValidator.getValidationError(newValue);
                        });
                        return;
                      }

                      if (widget.device is EndDevice) {
                        final endDevice = widget.device as EndDevice;

                        // Update based on which property this is
                        if (widget.property.id == 'currentIp') {
                          endDevice.setStaticIp(
                            newValue,
                            endDevice.currentSubnetMask ?? '255.255.255.0',
                            endDevice.currentDefaultGateway ?? '192.168.1.1',
                          );
                          // Update the property value to reflect change
                          (widget.property as IpAddressProperty).value =
                              newValue;
                        } else if (widget.property.id == 'currentSubnet') {
                          endDevice.setStaticIp(
                            endDevice.currentIpAddress ?? '192.168.1.1',
                            newValue,
                            endDevice.currentDefaultGateway ?? '192.168.1.1',
                          );
                          (widget.property as IpAddressProperty).value =
                              newValue;
                        } else if (widget.property.id == 'currentGateway') {
                          endDevice.setStaticIp(
                            endDevice.currentIpAddress ?? '192.168.1.1',
                            endDevice.currentSubnetMask ?? '255.255.255.0',
                            newValue,
                          );
                          (widget.property as IpAddressProperty).value =
                              newValue;
                        }

                        // Trigger canvas refresh
                        ref
                            .read(canvasProvider.notifier)
                            .refreshDevice(widget.device.deviceId);
                      }
                      setState(() {
                        _isEditing = false;
                        _errorText = null;
                      });
                    },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                _controller.text = widget.property.value.toString();
                setState(() {
                  _isEditing = false;
                  _errorText = null;
                });
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
    final canvasState = ref.watch(canvasProvider);

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
              } else if (action.id == 'configure_ip' && device is EndDevice) {
                // Show IP Configuration Dialog
                final endDevice = device as EndDevice;
                final allDevices = canvasState.networkDevices.values.toList();

                showDialog(
                  context: context,
                  builder: (ctx) => IpConfigurationDialog(
                    device: endDevice,
                    allDevices: allDevices,
                    onSave: (ip, subnet, gateway) {
                      // Update device configuration
                      endDevice.setStaticIp(ip, subnet, gateway);

                      // Refresh canvas
                      canvasNotifier.refreshDevice(device.deviceId);
                    },
                  ),
                );
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
