import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/scenarios/data/models/network_scenario.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';

/// Contextual editor that shows scenario metadata or device properties
class ContextualEditor extends ConsumerStatefulWidget {
  const ContextualEditor({super.key});

  @override
  ConsumerState<ContextualEditor> createState() => _ContextualEditorState();
}

class _ContextualEditorState extends ConsumerState<ContextualEditor> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

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
    // Initialize controllers with current values
    if (_titleController.text.isEmpty) {
      _titleController.text = scenario.title;
    }
    if (_descriptionController.text.isEmpty) {
      _descriptionController.text = scenario.description;
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

          // Title
          ShadInputFormField(
            id: 'title',
            controller: _titleController,
            label: const Text('Title'),
            onChanged: (value) {
              ref.read(scenarioProvider.notifier).updateMetadata(title: value);
            },
          ),
          const SizedBox(height: 12),

          // Description
          ShadInputFormField(
            id: 'description',
            controller: _descriptionController,
            label: const Text('Description'),
            maxLines: 3,
            onChanged: (value) {
              ref
                  .read(scenarioProvider.notifier)
                  .updateMetadata(description: value);
            },
          ),
          const SizedBox(height: 12),

          // Difficulty
          ShadSelectFormField<ScenarioDifficulty>(
            id: 'difficulty',
            initialValue: scenario.difficulty,
            label: const Text('Difficulty'),
            options: ScenarioDifficulty.values.map((difficulty) {
              return ShadOption(
                value: difficulty,
                child: Text(difficulty.displayName),
              );
            }).toList(),
            selectedOptionBuilder: (context, value) => Text(value.displayName),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(scenarioProvider.notifier)
                    .updateMetadata(difficulty: value);
              }
            },
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
                          // Immediately update the state
                          setState(() {
                            // Force rebuild to reflect changes
                          });
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

          DropdownButtonFormField<String>(
            initialValue: device.status.name,
            decoration: const InputDecoration(
              labelText: 'Initial Status',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: ['online', 'offline', 'warning', 'error'].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                canvasNotifier.updateDeviceStatus(
                  device.id,
                  DeviceStatus.values.firstWhere((s) => s.name == value),
                );
              }
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
                      property.value = newValue;
                      canvasNotifier.refreshDevice(device.id);
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
}
