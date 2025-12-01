import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/scenario_condition.dart';
import 'package:netsim_mobile/features/scenarios/utils/property_verification_helper.dart';
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
          if (condition.propertyDataType != null)
            _DetailRow(
              label: 'Data Type',
              value: condition.propertyDataType!.displayName,
            ),
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
      case ConditionType.deviceProperty:
        return Colors.green;
      default:
        return Colors.grey;
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
  PropertyDataType? _selectedPropertyDataType;
  PropertyOperator _selectedOperator = PropertyOperator.equals;
  final _expectedValueController = TextEditingController();

  // NEW: Interface property fields
  String? _selectedInterfaceName;

  // NEW: ARP cache fields
  final _targetIpController = TextEditingController();

  // NEW: Routing table fields
  final _targetNetworkController = TextEditingController();

  // NEW: Link check fields
  String? _targetDeviceForLink;

  // NEW: Composite fields
  final List<Map<String, dynamic>> _subConditions = [];
  CompositeLogic _compositeLogic = CompositeLogic.and;

  @override
  void dispose() {
    _descriptionController.dispose();
    _targetAddressController.dispose();
    _expectedValueController.dispose();
    _targetIpController.dispose();
    _targetNetworkController.dispose();
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
              // Condition Type Selection Grid (7 types)
              Text(
                'Condition Type',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ConditionTypeChip(
                    type: ConditionType.connectivity,
                    isSelected: _selectedType == ConditionType.connectivity,
                    onTap: () {
                      setState(() {
                        _selectedType = ConditionType.connectivity;
                        _resetFields();
                      });
                    },
                  ),
                  _ConditionTypeChip(
                    type: ConditionType.deviceProperty,
                    isSelected: _selectedType == ConditionType.deviceProperty,
                    onTap: () {
                      setState(() {
                        _selectedType = ConditionType.deviceProperty;
                        _resetFields();
                      });
                    },
                  ),
                  _ConditionTypeChip(
                    type: ConditionType.interfaceProperty,
                    isSelected:
                        _selectedType == ConditionType.interfaceProperty,
                    onTap: () {
                      setState(() {
                        _selectedType = ConditionType.interfaceProperty;
                        _resetFields();
                      });
                    },
                  ),
                  _ConditionTypeChip(
                    type: ConditionType.arpCacheCheck,
                    isSelected: _selectedType == ConditionType.arpCacheCheck,
                    onTap: () {
                      setState(() {
                        _selectedType = ConditionType.arpCacheCheck;
                        _resetFields();
                      });
                    },
                  ),
                  _ConditionTypeChip(
                    type: ConditionType.routingTableCheck,
                    isSelected:
                        _selectedType == ConditionType.routingTableCheck,
                    onTap: () {
                      setState(() {
                        _selectedType = ConditionType.routingTableCheck;
                        _resetFields();
                      });
                    },
                  ),
                  _ConditionTypeChip(
                    type: ConditionType.linkCheck,
                    isSelected: _selectedType == ConditionType.linkCheck,
                    onTap: () {
                      setState(() {
                        _selectedType = ConditionType.linkCheck;
                        _resetFields();
                      });
                    },
                  ),
                  _ConditionTypeChip(
                    type: ConditionType.composite,
                    isSelected: _selectedType == ConditionType.composite,
                    onTap: () {
                      setState(() {
                        _selectedType = ConditionType.composite;
                        _resetFields();
                      });
                    },
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
              Builder(
                builder: (context) {
                  switch (_selectedType) {
                    case ConditionType.connectivity:
                      return _buildConnectivityFields(devices);
                    case ConditionType.deviceProperty:
                      return _buildPropertyCheckFields(devices);
                    case ConditionType.interfaceProperty:
                      return _buildInterfacePropertyFields(devices);
                    case ConditionType.arpCacheCheck:
                      return _buildArpCacheFields(devices);
                    case ConditionType.routingTableCheck:
                      return _buildRoutingTableFields(devices);
                    case ConditionType.linkCheck:
                      return _buildLinkCheckFields(devices);
                    case ConditionType.composite:
                      return _buildCompositeFields(devices);
                  }
                },
              ),

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

        // Show target device selector for link protocol, otherwise target address
        if (_selectedProtocol == ConnectivityProtocol.link)
          ShadSelectFormField<String>(
            key: const ValueKey('targetDeviceSelector'),
            id: 'targetDevice',
            minWidth: double.infinity,
            initialValue: _selectedTargetDeviceId,
            label: const Text('Target Device'),
            placeholder: const Text('Select target device'),
            options: devices
                .where((device) => device.id != _selectedSourceDeviceId)
                .map((device) {
                  return ShadOption(
                    value: device.id,
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            device.type.icon,
                            size: 16,
                            color: device.type.color,
                          ),
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
                })
                .toList(),
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
              setState(() => _selectedTargetDeviceId = value);
            },
          )
        else
          ShadInputFormField(
            key: const ValueKey('targetAddressInput'),
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
    final Map<String, PropertyDataType> propertyDataTypes = {};
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
          propertyDataTypes[prop.label] = getPropertyDataType(prop);
        }
        availableProperties = propertySet.toList();

        // If selected property is not in the new list, clear it
        if (_selectedProperty != null &&
            !availableProperties.contains(_selectedProperty)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedProperty = null;
                _selectedPropertyDataType = null;
              });
            }
          });
        }
      }
    }

    // Get valid operators for selected property data type
    final validOperators =
        _selectedPropertyDataType?.validOperators ?? PropertyOperator.values;

    // Reset operator if current one is not valid for the selected data type
    if (!validOperators.contains(_selectedOperator)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedOperator = validOperators.first;
          });
        }
      });
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
              _selectedPropertyDataType = null;
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
              final dataType = propertyDataTypes[property]!;
              return ShadOption(
                value: property,
                child: Row(
                  children: [
                    Expanded(child: Text(property)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getDataTypeColor(
                          dataType,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _getDataTypeColor(dataType)),
                      ),
                      child: Text(
                        dataType.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getDataTypeColor(dataType),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            selectedOptionBuilder: (context, value) => Text(value),
            onChanged: (value) {
              setState(() {
                _selectedProperty = value;
                _selectedPropertyDataType = propertyDataTypes[value];
                // Clear expected value when property changes
                _expectedValueController.clear();
              });
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

        // Show data type info if property selected
        if (_selectedPropertyDataType != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _getDataTypeColor(
                _selectedPropertyDataType!,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getDataTypeColor(_selectedPropertyDataType!),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getDataTypeIcon(_selectedPropertyDataType!),
                  size: 16,
                  color: _getDataTypeColor(_selectedPropertyDataType!),
                ),
                const SizedBox(width: 8),
                Text(
                  'Data Type: ${_selectedPropertyDataType!.displayName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: _getDataTypeColor(_selectedPropertyDataType!),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // Operator dropdown - filtered based on data type
        ShadSelectFormField<PropertyOperator>(
          id: 'operator',
          minWidth: double.infinity,
          key: ValueKey('operator_$_selectedPropertyDataType'),
          initialValue: _selectedOperator,
          label: const Text('Operator'),
          options: validOperators.map((operator) {
            return ShadOption(
              value: operator,
              child: Row(
                children: [
                  Text(operator.symbol),
                  const SizedBox(width: 8),
                  Text(operator.displayName),
                ],
              ),
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

        // Expected value field - different based on data type
        _buildExpectedValueField(),
      ],
    );
  }

  Widget _buildExpectedValueField() {
    if (_selectedPropertyDataType == null) {
      return ShadInputFormField(
        controller: _expectedValueController,
        label: const Text("Expected Value"),
        description: const Text("Select a property first"),
        placeholder: const Text("Please select a property"),
        enabled: false,
      );
    }

    switch (_selectedPropertyDataType!) {
      case PropertyDataType.boolean:
        return ShadSelectFormField<String>(
          id: 'expectedValueBoolean',
          minWidth: double.infinity,
          initialValue: _expectedValueController.text.isEmpty
              ? null
              : _expectedValueController.text,
          label: const Text('Expected Value'),
          placeholder: const Text('Select True or False'),
          options: const [
            ShadOption(value: 'true', child: Text('True')),
            ShadOption(value: 'false', child: Text('False')),
          ],
          selectedOptionBuilder: (context, value) =>
              Text(value == 'true' ? 'True' : 'False'),
          onChanged: (value) {
            if (value != null) {
              _expectedValueController.text = value;
            }
          },
        );

      case PropertyDataType.integer:
        return ShadInputFormField(
          controller: _expectedValueController,
          label: const Text("Expected Value"),
          description: const Text("Enter a number"),
          placeholder: const Text("e.g., 5, 100"),
          keyboardType: TextInputType.number,
        );

      case PropertyDataType.ipAddress:
        return ShadInputFormField(
          controller: _expectedValueController,
          label: const Text("Expected Value"),
          description: const Text("Enter an IP address"),
          placeholder: const Text("e.g., 192.168.1.1"),
          keyboardType: TextInputType.number,
        );

      case PropertyDataType.string:
        return ShadInputFormField(
          controller: _expectedValueController,
          label: const Text("Expected Value"),
          description: const Text("Enter expected text"),
          placeholder: const Text("e.g., ON, ACTIVE"),
        );
    }
  }

  Color _getDataTypeColor(PropertyDataType dataType) {
    switch (dataType) {
      case PropertyDataType.boolean:
        return Colors.purple;
      case PropertyDataType.integer:
        return Colors.blue;
      case PropertyDataType.ipAddress:
        return Colors.green;
      case PropertyDataType.string:
        return Colors.orange;
    }
  }

  IconData _getDataTypeIcon(PropertyDataType dataType) {
    switch (dataType) {
      case PropertyDataType.boolean:
        return Icons.toggle_on;
      case PropertyDataType.integer:
        return Icons.numbers;
      case PropertyDataType.ipAddress:
        return Icons.settings_ethernet;
      case PropertyDataType.string:
        return Icons.text_fields;
    }
  }

  // NEW BUILDER METHODS FOR ENHANCED CONDITION TYPES

  Widget _buildInterfacePropertyFields(List<CanvasDevice> devices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check interface properties (e.g., eth0 status, IP)',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        // Device selector
        ShadSelectFormField<String>(
          id: 'interfaceDevice',
          minWidth: double.infinity,
          label: const Text('Device'),
          placeholder: const Text('Select device'),
          options: devices
              .map(
                (device) =>
                    ShadOption(value: device.id, child: Text(device.name)),
              )
              .toList(),
          selectedOptionBuilder: (context, value) {
            final device = devices.firstWhere((d) => d.id == value);
            return Text(device.name);
          },
          onChanged: (value) => setState(() => _selectedTargetDeviceId = value),
        ),
        const SizedBox(height: 12),
        // Interface name input
        ShadInputFormField(
          id: 'interfaceName',
          label: const Text('Interface Name'),
          placeholder: const Text('e.g., eth0, eth1'),
          onChanged: (value) => setState(() => _selectedInterfaceName = value),
        ),
        const SizedBox(height: 12),
        // Property input (for now, simple text field)
        ShadInputFormField(
          id: 'interfaceProperty',
          label: const Text('Property'),
          placeholder: const Text('e.g., interfaceStatus, interfaceIpAddress'),
          onChanged: (value) => setState(() => _selectedProperty = value),
        ),
        const SizedBox(height: 12),
        // Expected value
        ShadInputFormField(
          controller: _expectedValueController,
          label: const Text('Expected Value'),
          placeholder: const Text('e.g., UP, 192.168.1.10'),
        ),
      ],
    );
  }

  Widget _buildArpCacheFields(List<CanvasDevice> devices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check ARP cache entries',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        // Device selector
        ShadSelectFormField<String>(
          id: 'arpDevice',
          minWidth: double.infinity,
          label: const Text('Device'),
          placeholder: const Text('Select device'),
          options: devices
              .map(
                (device) =>
                    ShadOption(value: device.id, child: Text(device.name)),
              )
              .toList(),
          selectedOptionBuilder: (context, value) {
            final device = devices.firstWhere((d) => d.id == value);
            return Text(device.name);
          },
          onChanged: (value) => setState(() => _selectedTargetDeviceId = value),
        ),
        const SizedBox(height: 12),
        // Property selector
        ShadInputFormField(
          id: 'arpProperty',
          label: const Text('Property'),
          placeholder: const Text('e.g., hasArpEntry, arpEntryCount'),
          onChanged: (value) => setState(() => _selectedProperty = value),
        ),
        const SizedBox(height: 12),
        // Target IP (optional, for hasArpEntry)
        ShadInputFormField(
          controller: _targetIpController,
          label: const Text('Target IP (optional)'),
          placeholder: const Text('e.g., 192.168.1.1'),
        ),
        const SizedBox(height: 12),
        // Expected value
        ShadInputFormField(
          controller: _expectedValueController,
          label: const Text('Expected Value'),
          placeholder: const Text('e.g., true, 5'),
        ),
      ],
    );
  }

  Widget _buildRoutingTableFields(List<CanvasDevice> devices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check routing table entries',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        // Device selector
        ShadSelectFormField<String>(
          id: 'routingDevice',
          minWidth: double.infinity,
          label: const Text('Device'),
          placeholder: const Text('Select device'),
          options: devices
              .map(
                (device) =>
                    ShadOption(value: device.id, child: Text(device.name)),
              )
              .toList(),
          selectedOptionBuilder: (context, value) {
            final device = devices.firstWhere((d) => d.id == value);
            return Text(device.name);
          },
          onChanged: (value) => setState(() => _selectedTargetDeviceId = value),
        ),
        const SizedBox(height: 12),
        // Property selector
        ShadInputFormField(
          id: 'routingProperty',
          label: const Text('Property'),
          placeholder: const Text(
            'e.g., hasRoute, hasDefaultRoute, routeCount',
          ),
          onChanged: (value) => setState(() => _selectedProperty = value),
        ),
        const SizedBox(height: 12),
        // Target network (optional)
        ShadInputFormField(
          controller: _targetNetworkController,
          label: const Text('Target Network (optional)'),
          placeholder: const Text('e.g., 192.168.1.0/24, 0.0.0.0/0'),
        ),
        const SizedBox(height: 12),
        // Expected value
        ShadInputFormField(
          controller: _expectedValueController,
          label: const Text('Expected Value'),
          placeholder: const Text('e.g., true, 192.168.1.1'),
        ),
      ],
    );
  }

  Widget _buildLinkCheckFields(List<CanvasDevice> devices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check device connections',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        // Device selector
        ShadSelectFormField<String>(
          id: 'linkDevice',
          minWidth: double.infinity,
          label: const Text('Device'),
          placeholder: const Text('Select device'),
          options: devices
              .map(
                (device) =>
                    ShadOption(value: device.id, child: Text(device.name)),
              )
              .toList(),
          selectedOptionBuilder: (context, value) {
            final device = devices.firstWhere((d) => d.id == value);
            return Text(device.name);
          },
          onChanged: (value) => setState(() => _selectedTargetDeviceId = value),
        ),
        const SizedBox(height: 12),
        // Property selector
        ShadInputFormField(
          id: 'linkProperty',
          label: const Text('Property'),
          placeholder: const Text('e.g., linkCount, isLinkedToDevice'),
          onChanged: (value) => setState(() => _selectedProperty = value),
        ),
        const SizedBox(height: 12),
        // Target device (optional, for isLinkedToDevice)
        ShadSelectFormField<String>(
          id: 'targetDevice',
          minWidth: double.infinity,
          label: const Text('Target Device (optional)'),
          placeholder: const Text('Select target device'),
          options: devices
              .map(
                (device) =>
                    ShadOption(value: device.id, child: Text(device.name)),
              )
              .toList(),
          selectedOptionBuilder: (context, value) {
            final device = devices.firstWhere((d) => d.id == value);
            return Text(device.name);
          },
          onChanged: (value) => setState(() => _targetDeviceForLink = value),
        ),
        const SizedBox(height: 12),
        // Expected value
        ShadInputFormField(
          controller: _expectedValueController,
          label: const Text('Expected Value'),
          placeholder: const Text('e.g., 2, true'),
        ),
      ],
    );
  }

  Widget _buildCompositeFields(List<CanvasDevice> devices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Composite conditions (Coming Soon)',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Composite conditions allow combining multiple checks. This feature will be available soon!',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Reset all field selections when condition type changes
  void _resetFields() {
    _selectedSourceDeviceId = null;
    _selectedTargetDeviceId = null;
    _selectedProperty = null;
    _selectedPropertyDataType = null;
    _selectedInterfaceName = null;
    _targetDeviceForLink = null;
    _targetAddressController.clear();
    _expectedValueController.clear();
    _targetIpController.clear();
    _targetNetworkController.clear();
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
      // Validate based on protocol type
      if (_selectedProtocol == ConnectivityProtocol.link) {
        // For link protocol, we need source and target device IDs
        if (_selectedSourceDeviceId == null ||
            _selectedTargetDeviceId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select both source and target devices'),
            ),
          );
          return;
        }

        condition = ScenarioCondition(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          description: _descriptionController.text,
          type: ConditionType.connectivity,
          protocol: _selectedProtocol,
          sourceDeviceID: _selectedSourceDeviceId,
          targetDeviceID: _selectedTargetDeviceId,
        );
      } else {
        // For other protocols, we need source device and target address
        if (_selectedSourceDeviceId == null ||
            _targetAddressController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill all connectivity fields'),
            ),
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
      }
    } else if (_selectedType == ConditionType.deviceProperty) {
      if (_selectedTargetDeviceId == null ||
          _selectedProperty == null ||
          _selectedPropertyDataType == null ||
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
        type: ConditionType.deviceProperty,
        targetDeviceID: _selectedTargetDeviceId,
        property: _selectedProperty,
        propertyDataType: _selectedPropertyDataType,
        operator: _selectedOperator,
        expectedValue: _expectedValueController.text,
      );
    } else if (_selectedType == ConditionType.interfaceProperty) {
      if (_selectedTargetDeviceId == null ||
          _selectedInterfaceName == null ||
          _selectedProperty == null ||
          _expectedValueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all interface fields')),
        );
        return;
      }

      condition = ScenarioCondition(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: _descriptionController.text,
        type: ConditionType.interfaceProperty,
        targetDeviceID: _selectedTargetDeviceId,
        interfaceName: _selectedInterfaceName,
        property: _selectedProperty,
        expectedValue: _expectedValueController.text,
        operator: _selectedOperator,
      );
    } else if (_selectedType == ConditionType.arpCacheCheck) {
      if (_selectedTargetDeviceId == null ||
          _selectedProperty == null ||
          _expectedValueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all ARP cache fields')),
        );
        return;
      }

      condition = ScenarioCondition(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: _descriptionController.text,
        type: ConditionType.arpCacheCheck,
        targetDeviceID: _selectedTargetDeviceId,
        property: _selectedProperty,
        targetIpForCheck: _targetIpController.text.isEmpty
            ? null
            : _targetIpController.text,
        expectedValue: _expectedValueController.text,
        operator: _selectedOperator,
      );
    } else if (_selectedType == ConditionType.routingTableCheck) {
      if (_selectedTargetDeviceId == null ||
          _selectedProperty == null ||
          _expectedValueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all routing table fields')),
        );
        return;
      }

      condition = ScenarioCondition(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: _descriptionController.text,
        type: ConditionType.routingTableCheck,
        targetDeviceID: _selectedTargetDeviceId,
        property: _selectedProperty,
        targetNetworkForCheck: _targetNetworkController.text.isEmpty
            ? null
            : _targetNetworkController.text,
        expectedValue: _expectedValueController.text,
        operator: _selectedOperator,
      );
    } else if (_selectedType == ConditionType.linkCheck) {
      if (_selectedTargetDeviceId == null ||
          _selectedProperty == null ||
          _expectedValueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all link check fields')),
        );
        return;
      }

      condition = ScenarioCondition(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: _descriptionController.text,
        type: ConditionType.linkCheck,
        targetDeviceID: _selectedTargetDeviceId,
        property: _selectedProperty,
        targetDeviceIdForLink: _targetDeviceForLink,
        expectedValue: _expectedValueController.text,
        operator: _selectedOperator,
      );
    } else if (_selectedType == ConditionType.composite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Composite conditions coming soon!')),
      );
      return;
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unknown condition type')));
      return;
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
      case ConditionType.deviceProperty:
        return Icons.settings_outlined;
      case ConditionType.interfaceProperty:
        return Icons.cable;
      case ConditionType.arpCacheCheck:
        return Icons.storage;
      case ConditionType.routingTableCheck:
        return Icons.route;
      case ConditionType.linkCheck:
        return Icons.link;
      case ConditionType.composite:
        return Icons.layers;
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

/// Compact chip for condition type selection
class _ConditionTypeChip extends StatelessWidget {
  final ConditionType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConditionTypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (type) {
      case ConditionType.connectivity:
        return Icons.network_check;
      case ConditionType.deviceProperty:
        return Icons.settings_outlined;
      case ConditionType.interfaceProperty:
        return Icons.cable;
      case ConditionType.arpCacheCheck:
        return Icons.storage;
      case ConditionType.routingTableCheck:
        return Icons.route;
      case ConditionType.linkCheck:
        return Icons.link;
      case ConditionType.composite:
        return Icons.layers;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 16,
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            type.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey.withValues(alpha: 0.05),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      checkmarkColor: theme.colorScheme.primary,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : Colors.grey.withValues(alpha: 0.3),
        width: isSelected ? 1.5 : 1,
      ),
    );
  }
}
