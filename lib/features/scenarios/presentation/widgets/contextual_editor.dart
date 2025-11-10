import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/scenarios/data/models/network_scenario.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/router_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/firewall_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/wireless_access_point.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/device_rules_editor.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/network_device.dart'
    as network;

/// Contextual editor that shows scenario metadata or device properties
class ContextualEditor extends ConsumerStatefulWidget {
  const ContextualEditor({super.key});

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

    // Find selected device if any
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

  Widget _buildDevicePropertiesEditor(CanvasDevice device) {
    final canvasNotifier = ref.read(canvasProvider.notifier);
    final networkDevice = canvasNotifier.getNetworkDevice(device.id);

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
              // Delete action
              ActionChip(
                avatar: const Icon(Icons.delete, size: 18),
                label: const Text('Delete'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Device'),
                      content: Text('Delete ${device.name}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
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
                return ActionChip(
                  avatar: Icon(action.icon, size: 18),
                  label: Text(action.label),
                  onPressed: action.isEnabled
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
                  backgroundColor: action.isEnabled
                      ? null
                      : Colors.grey.withValues(alpha: 0.2),
                );
              }).toList(),
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child:
                    property.buildEditWidget((newValue) {
                      // Update property value
                      property.value = newValue;

                      // Handle special case for showIpOnCanvas toggle
                      if (property.id == 'showIpOnCanvas' && newValue is bool) {
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
                    property.buildDisplayWidget(),
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

            // Simulation Rules
            DeviceRulesEditor(deviceId: device.id),
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
  DeviceStatus _mapToCanvasStatus(network.DeviceStatus networkStatus) {
    switch (networkStatus) {
      case network.DeviceStatus.online:
      case network.DeviceStatus.configured:
        return DeviceStatus.online;
      case network.DeviceStatus.offline:
      case network.DeviceStatus.notConfigured:
        return DeviceStatus.offline;
      case network.DeviceStatus.warning:
      case network.DeviceStatus.error:
        // Map warning/error to online (shouldn't occur with new two-state logic)
        return DeviceStatus.online;
    }
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
