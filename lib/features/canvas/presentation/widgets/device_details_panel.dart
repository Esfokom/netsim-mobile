import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/canvas/domain/interfaces/device_capability.dart';
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
                      (property) => property.buildDisplayWidget(),
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
