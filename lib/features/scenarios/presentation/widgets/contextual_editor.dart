import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/network_scenario.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/device_rule.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/device_rules_editor.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/data/models/device_link.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart'
    as network;
import 'package:netsim_mobile/features/devices/domain/entities/router_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/firewall_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/wireless_access_point.dart';

/// Contextual editor that shows scenario metadata or device properties
class ContextualEditor extends ConsumerStatefulWidget {
  final bool simulationMode;

  const ContextualEditor({super.key, this.simulationMode = false});

  @override
  ConsumerState<ContextualEditor> createState() => _ContextualEditorState();
}

class _ContextualEditorState extends ConsumerState<ContextualEditor> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _pendingTitle = '';
  String _pendingDescription = '';
  bool _isTitleEditing = false;
  bool _isDescriptionEditing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

      if (selectedDevice != null) {
        return _buildDevicePropertiesEditor(
          selectedDevice,
          simulationMode: true,
        );
      } else {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select a device to view its properties',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        );
      }
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

    if (selectedDevice != null) {
      // Show device properties editor
      return _buildDevicePropertiesEditor(selectedDevice);
    } else {
      // Show scenario metadata editor
      return _buildScenarioMetadataEditor(scenarioState.scenario);
    }
  }

  Widget _buildScenarioMetadataEditor(NetworkScenario scenario) {
    // Initialize controllers with current values if not editing
    if (!_isTitleEditing && _titleController.text != scenario.title) {
      _titleController.text = scenario.title;
      _pendingTitle = scenario.title;
    }
    if (!_isDescriptionEditing &&
        _descriptionController.text != scenario.description) {
      _descriptionController.text = scenario.description;
      _pendingDescription = scenario.description;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scenario Settings',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Title with validation
          Text(
            'Title',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter scenario title',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    errorText: _isTitleEditing && _pendingTitle.trim().isEmpty
                        ? 'Title cannot be empty'
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _pendingTitle = value;
                      _isTitleEditing = true;
                    });
                  },
                ),
              ),
              if (_isTitleEditing) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _pendingTitle.trim().isEmpty
                      ? null
                      : () {
                          ref
                              .read(scenarioProvider.notifier)
                              .updateMetadata(title: _pendingTitle.trim());
                          setState(() => _isTitleEditing = false);
                        },
                  tooltip: 'Accept',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _titleController.text = scenario.title;
                      _pendingTitle = scenario.title;
                      _isTitleEditing = false;
                    });
                  },
                  tooltip: 'Cancel',
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Description with validation
          Text(
            'Description',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Enter scenario description',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText:
                      _isDescriptionEditing &&
                          _pendingDescription.trim().isEmpty
                      ? 'Description cannot be empty'
                      : null,
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _pendingDescription = value;
                    _isDescriptionEditing = true;
                  });
                },
              ),
              if (_isDescriptionEditing) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Cancel'),
                      onPressed: () {
                        setState(() {
                          _descriptionController.text = scenario.description;
                          _pendingDescription = scenario.description;
                          _isDescriptionEditing = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      onPressed: _pendingDescription.trim().isEmpty
                          ? null
                          : () {
                              ref
                                  .read(scenarioProvider.notifier)
                                  .updateMetadata(
                                    description: _pendingDescription.trim(),
                                  );
                              setState(() => _isDescriptionEditing = false);
                            },
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Difficulty with icon buttons
          Text(
            'Difficulty',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: ScenarioDifficulty.values.map((difficulty) {
              final isSelected = scenario.difficulty == difficulty;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _DifficultyButton(
                    difficulty: difficulty,
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(scenarioProvider.notifier)
                          .updateMetadata(difficulty: difficulty);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Info card
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
                    'Click on a device on the canvas to edit its properties',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          const SizedBox(height: 16),

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
          ],
          const SizedBox(height: 24),

          // Basic Properties Section
          Text(
            'Basic Properties',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),

          _buildPropertyField('Device ID', device.id, readOnly: true),
          const SizedBox(height: 12),

          _buildPropertyField(
            'Name',
            device.name,
            onChanged: (value) {
              canvasNotifier.refreshDevice(device.id);
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildPropertyField(
                  'X Position',
                  device.position.dx.toStringAsFixed(0),
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPropertyField(
                  'Y Position',
                  device.position.dy.toStringAsFixed(0),
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

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

            // Display all properties
            ...networkDevice.properties.map((property) {
              // Check if property editing is allowed in simulation mode
              final canEdit =
                  !simulationMode ||
                  scenarioNotifier.isActionAllowed(
                    device.id,
                    DeviceActionType.editProperty,
                    propertyId: property.id,
                  );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: canEdit
                    ? (property.buildEditWidget((newValue) {
                            // Update property value
                            property.value = newValue;

                            // Handle special case for showIpOnCanvas toggle
                            if (property.id == 'showIpOnCanvas' &&
                                newValue is bool) {
                              // Update the actual device field based on device type
                              if (networkDevice is RouterDevice) {
                                networkDevice.showIpOnCanvas = newValue;
                              } else if (networkDevice is EndDevice) {
                                networkDevice.showIpOnCanvas = newValue;
                              } else if (networkDevice is FirewallDevice) {
                                networkDevice.showIpOnCanvas = newValue;
                              } else if (networkDevice is WirelessAccessPoint) {
                                networkDevice.showIpOnCanvas = newValue;
                              }
                            }

                            // Refresh canvas to update display
                            canvasNotifier.refreshDevice(device.id);
                            setState(() {});
                          }) ??
                          property.buildDisplayWidget())
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    property.label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    property.value.toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Locked in simulation',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              );
            }),

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
          }).toList(),
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
                }).toList(),
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

  Widget _buildPropertyField(
    String label,
    String value, {
    bool readOnly = false,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      readOnly: readOnly,
      onChanged: onChanged,
    );
  }

  /// Maps NetworkDevice DeviceStatus to CanvasDevice DeviceStatus
  /// Since both now use the same DeviceStatus enum from devices domain, just return as-is
  network.DeviceStatus _mapToCanvasStatus(network.DeviceStatus networkStatus) {
    return networkStatus;
  }
}

/// Difficulty button widget
class _DifficultyButton extends StatelessWidget {
  final ScenarioDifficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (difficulty) {
      case ScenarioDifficulty.easy:
        return Icons.sentiment_satisfied;
      case ScenarioDifficulty.medium:
        return Icons.sentiment_neutral;
      case ScenarioDifficulty.hard:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  Color _getColor() {
    switch (difficulty) {
      case ScenarioDifficulty.easy:
        return Colors.green;
      case ScenarioDifficulty.medium:
        return Colors.orange;
      case ScenarioDifficulty.hard:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(),
              size: 32,
              color: isSelected ? color : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              difficulty.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
