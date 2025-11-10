import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/scenarios/data/models/scenario_condition.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';

/// Editor for success conditions
class ConditionsEditor extends ConsumerWidget {
  const ConditionsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarioState = ref.watch(scenarioProvider);
    final conditions = scenarioState.scenario.successConditions;

    return Column(
      children: [
        // Header with Add button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Success Conditions (${conditions.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddConditionDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Conditions list
        Expanded(
          child: conditions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No conditions yet',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add conditions to define success criteria',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: conditions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final condition = conditions[index];
                    return _ConditionCard(condition: condition);
                  },
                ),
        ),
      ],
    );
  }

  void _showAddConditionDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => _AddConditionDialog());
  }
}

/// Card displaying a single condition
class _ConditionCard extends ConsumerWidget {
  final ScenarioCondition condition;

  const _ConditionCard({required this.condition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getConditionColor(
                      condition.type,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    condition.type.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getConditionColor(condition.type),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () {
                    ref
                        .read(scenarioProvider.notifier)
                        .removeCondition(condition.id);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              condition.description,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildConditionDetails(condition),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionDetails(ScenarioCondition condition) {
    if (condition.type == ConditionType.connectivity) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
            label: 'Protocol',
            value: condition.protocol?.displayName ?? 'N/A',
          ),
          _DetailRow(label: 'Source', value: condition.sourceDeviceID ?? 'N/A'),
          _DetailRow(label: 'Target', value: condition.targetAddress ?? 'N/A'),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: 'Device', value: condition.targetDeviceID ?? 'N/A'),
          _DetailRow(label: 'Property', value: condition.property ?? 'N/A'),
          _DetailRow(
            label: 'Operator',
            value: condition.operator?.displayName ?? 'N/A',
          ),
          _DetailRow(
            label: 'Expected',
            value: condition.expectedValue ?? 'N/A',
          ),
        ],
      );
    }
  }

  Color _getConditionColor(ConditionType type) {
    switch (type) {
      case ConditionType.connectivity:
        return Colors.blue;
      case ConditionType.propertyCheck:
        return Colors.green;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Dialog for adding a new condition
class _AddConditionDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddConditionDialog> createState() =>
      _AddConditionDialogState();
}

class _AddConditionDialogState extends ConsumerState<_AddConditionDialog> {
  ConditionType _selectedType = ConditionType.connectivity;
  final _descriptionController = TextEditingController();

  // Connectivity fields
  ConnectivityProtocol _selectedProtocol = ConnectivityProtocol.ping;
  String? _selectedSourceDeviceId;
  final _targetAddressController = TextEditingController();

  // Property check fields
  String? _selectedTargetDeviceId;
  String? _selectedProperty;
  PropertyOperator _selectedOperator = PropertyOperator.equals;
  final _expectedValueController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _targetAddressController.dispose();
    _expectedValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider);
    final devices = canvasState.devices;

    return Dialog(
      child: ShadCard(
        // constraints: const BoxConstraints(maxWidth: 500),
        title: Text("Add Success Condition"),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Condition Type Toggle Buttons
              Row(
                children: [
                  Expanded(
                    child: _ConditionTypeButton(
                      type: ConditionType.connectivity,
                      isSelected: _selectedType == ConditionType.connectivity,
                      onTap: () {
                        setState(() {
                          _selectedType = ConditionType.connectivity;
                          // Reset selections when type changes
                          _selectedSourceDeviceId = null;
                          _selectedTargetDeviceId = null;
                          _selectedProperty = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ConditionTypeButton(
                      type: ConditionType.propertyCheck,
                      isSelected: _selectedType == ConditionType.propertyCheck,
                      onTap: () {
                        setState(() {
                          _selectedType = ConditionType.propertyCheck;
                          // Reset selections when type changes
                          _selectedSourceDeviceId = null;
                          _selectedTargetDeviceId = null;
                          _selectedProperty = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ShadInputFormField(
                controller: _descriptionController,
                label: Text("Description"),
                placeholder: Text(
                  "Give a detailed description of the condition",
                ),
                description: Text("e.g., PC-01 must ping the server"),

                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Type-specific fields with device dropdowns
              if (_selectedType == ConditionType.connectivity)
                _buildConnectivityFields(devices)
              else
                _buildPropertyCheckFields(devices),

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveCondition,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectivityFields(List<CanvasDevice> devices) {
    return Column(
      children: [
        ShadSelectFormField<ConnectivityProtocol>(
          id: 'protocol',
          initialValue: _selectedProtocol,
          minWidth: double.infinity,
          label: const Text('Protocol'),
          options: ConnectivityProtocol.values.map((protocol) {
            return ShadOption(
              value: protocol,
              child: Text(protocol.displayName),
            );
          }).toList(),
          selectedOptionBuilder: (context, value) => Text(value.displayName),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedProtocol = value);
            }
          },
        ),
        const SizedBox(height: 12),

        // Device dropdown for source
        ShadSelectFormField<String>(
          id: 'sourceDevice',
          minWidth: double.infinity,
          key: ValueKey(_selectedSourceDeviceId),
          initialValue: _selectedSourceDeviceId,
          label: const Text('Source Device'),
          placeholder: const Text('Select source device'),
          options: devices.map((device) {
            return ShadOption(
              value: device.id,
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(device.type.icon, size: 16, color: device.type.color),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            device.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            '${device.id} • ${device.type.displayName}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          selectedOptionBuilder: (context, value) {
            final device = devices.firstWhere((d) => d.id == value);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(device.type.icon, size: 16, color: device.type.color),
                const SizedBox(width: 8),
                Text(device.name),
              ],
            );
          },
          onChanged: (value) {
            setState(() => _selectedSourceDeviceId = value);
          },
        ),
        const SizedBox(height: 12),

        ShadInputFormField(
          controller: _targetAddressController,
          label: Text("Target Address"),
          description: Text("e.g., 8.8.8.8 or google.com"),
          placeholder: Text("Please enter address"),
        ),
      ],
    );
  }

  Widget _buildPropertyCheckFields(List<CanvasDevice> devices) {
    final canvasNotifier = ref.read(canvasProvider.notifier);
    List<String> availableProperties = [];

    // Get properties for selected device
    if (_selectedTargetDeviceId != null) {
      final networkDevice = canvasNotifier.getNetworkDevice(
        _selectedTargetDeviceId!,
      );
      if (networkDevice != null) {
        // Use LinkedHashSet to preserve order and remove duplicates
        final propertySet = <String>{};
        for (final prop in networkDevice.properties) {
          propertySet.add(prop.label);
        }
        availableProperties = propertySet.toList();

        // If selected property is not in the new list, clear it
        if (_selectedProperty != null &&
            !availableProperties.contains(_selectedProperty)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedProperty = null;
              });
            }
          });
        }
      }
    }

    return Column(
      children: [
        // Device dropdown for target
        ShadSelectFormField<String>(
          id: 'targetDevice',
          minWidth: double.infinity,
          key: ValueKey(_selectedTargetDeviceId),
          initialValue: _selectedTargetDeviceId,
          label: const Text('Target Device'),
          placeholder: const Text('Select target device'),
          options: devices.map((device) {
            return ShadOption(
              value: device.id,
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(device.type.icon, size: 16, color: device.type.color),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            device.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            '${device.id} • ${device.type.displayName}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          selectedOptionBuilder: (context, value) {
            final device = devices.firstWhere((d) => d.id == value);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(device.type.icon, size: 16, color: device.type.color),
                const SizedBox(width: 8),
                Text(device.name),
              ],
            );
          },
          onChanged: (value) {
            setState(() {
              _selectedTargetDeviceId = value;
              _selectedProperty = null; // Reset property when device changes
            });
          },
        ),
        const SizedBox(height: 12),

        // Property dropdown (only show if device selected)
        if (_selectedTargetDeviceId != null)
          ShadSelectFormField<String>(
            id: 'property',
            minWidth: double.infinity,
            key: ValueKey('property_$_selectedTargetDeviceId'),
            initialValue: _selectedProperty,
            label: const Text('Property'),
            placeholder: const Text('Select property'),
            options: availableProperties.map((property) {
              return ShadOption(value: property, child: Text(property));
            }).toList(),
            selectedOptionBuilder: (context, value) => Text(value),
            onChanged: (value) {
              setState(() => _selectedProperty = value);
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select a device first to see available properties',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        ShadSelectFormField<PropertyOperator>(
          id: 'operator',
          minWidth: double.infinity,
          initialValue: _selectedOperator,
          label: const Text('Operator'),
          options: PropertyOperator.values.map((operator) {
            return ShadOption(
              value: operator,
              child: Text(operator.displayName),
            );
          }).toList(),
          selectedOptionBuilder: (context, value) => Text(value.displayName),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedOperator = value);
            }
          },
        ),
        const SizedBox(height: 12),

        ShadInputFormField(
          controller: _expectedValueController,
          label: Text("Expected Value"),
          description: Text("e.g., ON, 192.168.1.1"),
          placeholder: Text("Please enter the expected value"),
        ),
      ],
    );
  }

  void _saveCondition() {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    ScenarioCondition condition;

    if (_selectedType == ConditionType.connectivity) {
      if (_selectedSourceDeviceId == null ||
          _targetAddressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all connectivity fields')),
        );
        return;
      }

      condition = ScenarioCondition(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: _descriptionController.text,
        type: ConditionType.connectivity,
        protocol: _selectedProtocol,
        sourceDeviceID: _selectedSourceDeviceId,
        targetAddress: _targetAddressController.text,
      );
    } else {
      if (_selectedTargetDeviceId == null ||
          _selectedProperty == null ||
          _expectedValueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all property check fields'),
          ),
        );
        return;
      }

      condition = ScenarioCondition(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: _descriptionController.text,
        type: ConditionType.propertyCheck,
        targetDeviceID: _selectedTargetDeviceId,
        property: _selectedProperty,
        operator: _selectedOperator,
        expectedValue: _expectedValueController.text,
      );
    }

    ref.read(scenarioProvider.notifier).addCondition(condition);
    Navigator.pop(context);
  }
}

/// Custom toggle button for condition type selection
class _ConditionTypeButton extends StatelessWidget {
  final ConditionType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConditionTypeButton({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (type) {
      case ConditionType.connectivity:
        return Icons.network_check;
      case ConditionType.propertyCheck:
        return Icons.settings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.grey.withValues(alpha: 0.3),
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
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
