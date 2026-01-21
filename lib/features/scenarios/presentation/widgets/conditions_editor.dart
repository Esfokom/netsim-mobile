import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/scenario_condition.dart';
import 'package:netsim_mobile/features/scenarios/utils/property_verification_helper.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/router_device.dart';

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
    switch (condition.type) {
      case ConditionType.ping:
        // New session-based ping condition
        if (condition.pingSessionCheckType != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                label: 'Check Type',
                value: condition.pingSessionCheckType!.displayName,
              ),
              if (condition.pingSessionCheckType ==
                  PingSessionCheckType.responseTime) ...[
                _DetailRow(
                  label: 'Operator',
                  value: condition.responseTimeOperator?.displayName ?? 'N/A',
                ),
                _DetailRow(
                  label: 'Threshold',
                  value: '${condition.responseTimeThreshold ?? 0}ms',
                ),
              ],
              _DetailRow(
                label: 'Source',
                value: _formatDeviceInterface(
                  condition.sourceDeviceIdForSession,
                  condition.sourceInterfaceForSession,
                ),
              ),
              _DetailRow(
                label: 'Destination',
                value: _formatDeviceInterface(
                  condition.destDeviceIdForSession,
                  condition.destInterfaceForSession,
                ),
              ),
            ],
          );
        }
        // Legacy ping condition display
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Type', value: 'Ping (Legacy)'),
            if (condition.protocolType != null)
              _DetailRow(
                label: 'Protocol',
                value: condition.protocolType!.name.toUpperCase(),
              ),
            if (condition.pingCheckType != null)
              _DetailRow(
                label: 'Check Type',
                value: _formatPingCheckType(condition.pingCheckType!),
              ),
            _DetailRow(
              label: 'Source',
              value: condition.sourceDeviceID ?? 'N/A',
            ),
            _DetailRow(
              label: 'Target',
              value:
                  condition.targetDeviceIdForPing ??
                  condition.targetAddress ??
                  'N/A',
            ),
            if (condition.responseTimeThreshold != null)
              _DetailRow(
                label: 'Threshold',
                value: '${condition.responseTimeThreshold}ms',
              ),
          ],
        );

      case ConditionType.linkCheck:
        if (condition.linkCheckMode == LinkCheckMode.booleanLinkStatus) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Mode', value: 'Link Status'),
              _DetailRow(
                label: 'Source',
                value: condition.sourceDeviceIDForLink ?? 'N/A',
              ),
              _DetailRow(
                label: 'Target',
                value: condition.targetDeviceIdForLink ?? 'N/A',
              ),
              _DetailRow(
                label: 'Expected',
                value: condition.expectedValue == 'true'
                    ? 'Linked'
                    : 'Not Linked',
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Mode', value: 'Link Count'),
              _DetailRow(
                label: 'Device',
                value: condition.targetDeviceID ?? 'N/A',
              ),
              _DetailRow(
                label: 'Expected Count',
                value: condition.expectedValue ?? 'N/A',
              ),
            ],
          );
        }

      case ConditionType.interfaceProperty:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              label: 'Device',
              value: condition.targetDeviceID ?? 'N/A',
            ),
            _DetailRow(
              label: 'Interface',
              value: condition.interfaceName ?? 'N/A',
            ),
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

      case ConditionType.arpCacheCheck:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              label: 'Device',
              value: condition.targetDeviceID ?? 'N/A',
            ),
            _DetailRow(label: 'Property', value: condition.property ?? 'N/A'),
            if (condition.targetIpForCheck != null)
              _DetailRow(
                label: 'Target IP',
                value: condition.targetIpForCheck!,
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

      case ConditionType.routingTableCheck:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              label: 'Device',
              value: condition.targetDeviceID ?? 'N/A',
            ),
            _DetailRow(label: 'Property', value: condition.property ?? 'N/A'),
            if (condition.targetNetworkForCheck != null)
              _DetailRow(
                label: 'Target Network',
                value: condition.targetNetworkForCheck!,
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

      case ConditionType.composite:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              label: 'Logic',
              value: condition.compositeLogic?.name.toUpperCase() ?? 'N/A',
            ),
            _DetailRow(
              label: 'Sub-Conditions',
              value: '${condition.subConditions?.length ?? 0}',
            ),
          ],
        );

      case ConditionType.deviceProperty:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              label: 'Device',
              value: condition.targetDeviceID ?? 'N/A',
            ),
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
      case ConditionType.ping:
        return Colors.blue;
      case ConditionType.deviceProperty:
        return Colors.green;
      case ConditionType.linkCheck:
        return Colors.orange;
      case ConditionType.interfaceProperty:
        return Colors.purple;
      case ConditionType.arpCacheCheck:
        return Colors.teal;
      case ConditionType.routingTableCheck:
        return Colors.indigo;
      case ConditionType.composite:
        return Colors.deepPurple;
    }
  }

  /// Format device and interface for display
  String _formatDeviceInterface(String? deviceId, String? interfaceName) {
    if (deviceId == null) return 'N/A';
    if (interfaceName != null) {
      return '$deviceId ($interfaceName)';
    }
    return deviceId;
  }

  String _formatPingCheckType(PingCheckType type) {
    switch (type) {
      case PingCheckType.sent:
        return 'Packet Sent';
      case PingCheckType.received:
        return 'Packet Received';
      case PingCheckType.receivedFromAny:
        return 'Received from Any';
      case PingCheckType.receivedFromSpecific:
        return 'Received from Specific';
      case PingCheckType.responseTime:
        return 'Response Time';
      case PingCheckType.finalReply:
        return 'Final Reply';
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
  ConditionType _selectedType = ConditionType.ping;
  final _descriptionController = TextEditingController();

  // Ping fields (legacy)
  String? _selectedSourceDeviceId;
  String? _selectedTargetDeviceIdForPing;
  final _targetAddressController = TextEditingController();
  PingProtocolType _selectedProtocolType = PingProtocolType.icmp;
  PingCheckType _selectedPingCheckType = PingCheckType.finalReply;
  final _responseTimeController = TextEditingController(text: '100');

  // ICMP-specific fields (legacy)
  IcmpEventType _icmpEventType = IcmpEventType.sent;
  PingDeviceScope _icmpDeviceScope = PingDeviceScope.anyDevice;
  String? _icmpSpecificDeviceId;

  // NEW: Ping session-based fields
  bool _usePingSessionMode = true; // Default to new session-based mode
  PingSessionCheckType _pingSessionCheckType = PingSessionCheckType.success;
  ResponseTimeOperator _responseTimeOperator = ResponseTimeOperator.lessThan;
  String? _sourceDeviceIdForSession;
  String? _sourceInterfaceForSession;
  String? _destDeviceIdForSession;
  String? _destInterfaceForSession;

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
  LinkCheckMode _linkCheckMode = LinkCheckMode.booleanLinkStatus;
  String? _sourceDeviceForLink;
  String? _targetDeviceForLink;
  double _linkCountValue = 1.0;

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
              // Condition Type Selection - Compact Dropdown
              ShadSelectFormField<ConditionType>(
                id: 'conditionType',
                minWidth: double.infinity,
                initialValue: _selectedType,
                label: const Text('Condition Type'),
                placeholder: const Text('Select condition type'),
                options: ConditionType.values.map((type) {
                  return ShadOption(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_getConditionTypeIcon(type), size: 18),
                        const SizedBox(width: 12),
                        Expanded(child: Text(type.displayName)),
                      ],
                    ),
                  );
                }).toList(),
                selectedOptionBuilder: (context, value) {
                  return Row(
                    children: [
                      Icon(_getConditionTypeIcon(value), size: 18),
                      const SizedBox(width: 12),
                      Text(value.displayName),
                    ],
                  );
                },
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      _resetFields();
                    });
                  }
                },
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
                    case ConditionType.ping:
                      return _buildPingFields(devices);
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

  Widget _buildPingFields(List<CanvasDevice> devices) {
    final canvasState = ref.watch(canvasProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode selector: Session-based (new) vs Legacy
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Configure ping session verification',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Session Check Type selector
        ShadSelectFormField<PingSessionCheckType>(
          id: 'pingSessionCheckType',
          minWidth: double.infinity,
          initialValue: _pingSessionCheckType,
          label: const Text('Check Type'),
          placeholder: const Text('Select what to verify'),
          options: PingSessionCheckType.values.map((checkType) {
            return ShadOption(
              value: checkType,
              child: Row(
                children: [
                  Icon(checkType.icon, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(checkType.displayName),
                        Text(
                          checkType.description,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          selectedOptionBuilder: (context, value) => Row(
            children: [
              Icon(value.icon, size: 16),
              const SizedBox(width: 8),
              Text(value.displayName),
            ],
          ),
          onChanged: (value) {
            setState(() => _pingSessionCheckType = value!);
          },
        ),
        const SizedBox(height: 16),

        // Response Time Operator and Threshold (only for responseTime check type)
        if (_pingSessionCheckType == PingSessionCheckType.responseTime) ...[
          Row(
            children: [
              Expanded(
                child: ShadSelectFormField<ResponseTimeOperator>(
                  id: 'responseTimeOperator',
                  minWidth: double.infinity,
                  initialValue: _responseTimeOperator,
                  label: const Text('Operator'),
                  options: ResponseTimeOperator.values.map((op) {
                    return ShadOption(
                      value: op,
                      child: Text('${op.symbol} ${op.displayName}'),
                    );
                  }).toList(),
                  selectedOptionBuilder: (context, value) =>
                      Text('${value.symbol} ${value.displayName}'),
                  onChanged: (value) {
                    setState(() => _responseTimeOperator = value!);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShadInputFormField(
                  controller: _responseTimeController,
                  label: const Text('Threshold (ms)'),
                  placeholder: const Text('e.g., 100'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Source Device and Interface selector
        Text(
          'Source (Ping Initiator)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        _buildDeviceInterfaceSelector(
          devices: devices,
          canvasState: canvasState,
          selectedDeviceId: _sourceDeviceIdForSession,
          selectedInterfaceName: _sourceInterfaceForSession,
          deviceLabel: 'Source Device',
          interfaceLabel: 'Source Interface',
          onDeviceChanged: (deviceId) {
            setState(() {
              _sourceDeviceIdForSession = deviceId;
              _sourceInterfaceForSession =
                  null; // Reset interface on device change
            });
          },
          onInterfaceChanged: (interfaceName) {
            setState(() => _sourceInterfaceForSession = interfaceName);
          },
        ),
        const SizedBox(height: 16),

        // Destination Device and Interface selector
        Text(
          'Destination (Ping Target)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        _buildDeviceInterfaceSelector(
          devices: devices,
          canvasState: canvasState,
          selectedDeviceId: _destDeviceIdForSession,
          selectedInterfaceName: _destInterfaceForSession,
          deviceLabel: 'Destination Device',
          interfaceLabel: 'Destination Interface',
          onDeviceChanged: (deviceId) {
            setState(() {
              _destDeviceIdForSession = deviceId;
              _destInterfaceForSession =
                  null; // Reset interface on device change
            });
          },
          onInterfaceChanged: (interfaceName) {
            setState(() => _destInterfaceForSession = interfaceName);
          },
        ),
      ],
    );
  }

  /// Build a device and interface selector combo
  Widget _buildDeviceInterfaceSelector({
    required List<CanvasDevice> devices,
    required CanvasState canvasState,
    required String? selectedDeviceId,
    required String? selectedInterfaceName,
    required String deviceLabel,
    required String interfaceLabel,
    required void Function(String?) onDeviceChanged,
    required void Function(String?) onInterfaceChanged,
  }) {
    // Get interfaces for selected device
    List<String> availableInterfaces = [];
    String? selectedInterfaceIp;

    if (selectedDeviceId != null) {
      final networkDevice = canvasState.networkDevices[selectedDeviceId];
      if (networkDevice is EndDevice) {
        availableInterfaces = networkDevice.interfaces
            .map((i) => i.name)
            .toList();
        if (selectedInterfaceName != null) {
          final iface = networkDevice.interfaces
              .where((i) => i.name == selectedInterfaceName)
              .firstOrNull;
          selectedInterfaceIp = iface?.ipAddress;
        }
      } else if (networkDevice is RouterDevice) {
        availableInterfaces = networkDevice.interfaces.keys.toList();
        if (selectedInterfaceName != null) {
          selectedInterfaceIp =
              networkDevice.interfaces[selectedInterfaceName]?.ipAddress;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Device selector
        ShadSelectFormField<String>(
          id: '${deviceLabel.replaceAll(' ', '_').toLowerCase()}',
          minWidth: double.infinity,
          key: ValueKey('$deviceLabel-${selectedDeviceId ?? "none"}'),
          initialValue: selectedDeviceId,
          label: Text(deviceLabel),
          placeholder: Text('Select device'),
          options: devices.map((device) {
            return ShadOption(
              value: device.id,
              child: Row(
                children: [
                  Icon(device.type.icon, size: 16, color: device.type.color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(device.name)),
                ],
              ),
            );
          }).toList(),
          selectedOptionBuilder: (context, value) {
            final device = devices.firstWhere((d) => d.id == value);
            return Row(
              children: [
                Icon(device.type.icon, size: 16, color: device.type.color),
                const SizedBox(width: 8),
                Text(device.name),
              ],
            );
          },
          onChanged: onDeviceChanged,
        ),
        const SizedBox(height: 8),

        // Interface selector (only if device is selected and has interfaces)
        if (selectedDeviceId != null && availableInterfaces.isNotEmpty)
          ShadSelectFormField<String>(
            id: '${interfaceLabel.replaceAll(' ', '_').toLowerCase()}',
            minWidth: double.infinity,
            key: ValueKey('$interfaceLabel-${selectedInterfaceName ?? "none"}'),
            initialValue: selectedInterfaceName,
            label: Text(interfaceLabel),
            placeholder: Text('Select interface'),
            options: availableInterfaces.map((ifaceName) {
              // Get IP for this interface
              String? ip;
              final networkDevice =
                  canvasState.networkDevices[selectedDeviceId];
              if (networkDevice is EndDevice) {
                final iface = networkDevice.interfaces
                    .where((i) => i.name == ifaceName)
                    .firstOrNull;
                ip = iface?.ipAddress;
              } else if (networkDevice is RouterDevice) {
                ip = networkDevice.interfaces[ifaceName]?.ipAddress;
              }

              return ShadOption(
                value: ifaceName,
                child: Row(
                  children: [
                    Icon(Icons.settings_ethernet, size: 14),
                    const SizedBox(width: 8),
                    Text(ifaceName),
                    if (ip != null && ip.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '($ip)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            selectedOptionBuilder: (context, value) {
              return Row(
                children: [
                  Icon(Icons.settings_ethernet, size: 14),
                  const SizedBox(width: 8),
                  Text(value),
                  if (selectedInterfaceIp != null &&
                      selectedInterfaceIp.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '($selectedInterfaceIp)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              );
            },
            onChanged: onInterfaceChanged,
          )
        else if (selectedDeviceId != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'No interfaces found on this device',
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                ),
              ],
            ),
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
          'Check device link/connection status',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),

        // Mode toggle buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _linkCheckMode = LinkCheckMode.booleanLinkStatus;
                    // Initialize expected value for boolean mode if empty
                    if (_expectedValueController.text.isEmpty) {
                      _expectedValueController.text = 'true';
                    }
                  });
                },
                icon: Icon(
                  Icons.link,
                  size: 18,
                  color: _linkCheckMode == LinkCheckMode.booleanLinkStatus
                      ? Colors.white
                      : Colors.blue,
                ),
                label: const Text('Link Status'),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      _linkCheckMode == LinkCheckMode.booleanLinkStatus
                      ? Colors.blue
                      : Colors.transparent,
                  foregroundColor:
                      _linkCheckMode == LinkCheckMode.booleanLinkStatus
                      ? Colors.white
                      : Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _linkCheckMode = LinkCheckMode.linkCount;
                  });
                },
                icon: Icon(
                  Icons.numbers,
                  size: 18,
                  color: _linkCheckMode == LinkCheckMode.linkCount
                      ? Colors.white
                      : Colors.green,
                ),
                label: const Text('Link Count'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _linkCheckMode == LinkCheckMode.linkCount
                      ? Colors.green
                      : Colors.transparent,
                  foregroundColor: _linkCheckMode == LinkCheckMode.linkCount
                      ? Colors.white
                      : Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Boolean Link Status Mode
        if (_linkCheckMode == LinkCheckMode.booleanLinkStatus) ...[
          // Source device
          ShadSelectFormField<String>(
            id: 'sourceDevice',
            minWidth: double.infinity,
            label: const Text('Source Device'),
            placeholder: const Text('Select source device'),
            options: devices.map((device) {
              return ShadOption(value: device.id, child: Text(device.name));
            }).toList(),
            selectedOptionBuilder: (context, value) {
              final device = devices.firstWhere((d) => d.id == value);
              return Text(device.name);
            },
            onChanged: (value) => setState(() => _sourceDeviceForLink = value),
          ),
          const SizedBox(height: 12),

          // Target device
          ShadSelectFormField<String>(
            id: 'targetDevice',
            minWidth: double.infinity,
            label: const Text('Target Device'),
            placeholder: const Text('Select target device'),
            options: devices.where((d) => d.id != _sourceDeviceForLink).map((
              device,
            ) {
              return ShadOption(value: device.id, child: Text(device.name));
            }).toList(),
            selectedOptionBuilder: (context, value) {
              final device = devices.firstWhere((d) => d.id == value);
              return Text(device.name);
            },
            onChanged: (value) => setState(() => _targetDeviceForLink = value),
          ),
          const SizedBox(height: 12),

          // Expected value (true/false)
          ShadSelectFormField<String>(
            id: 'expectedLinkStatus',
            minWidth: double.infinity,
            label: const Text('Expected Link Status'),
            initialValue: 'true',
            options: const [
              ShadOption(value: 'true', child: Text('Linked (true)')),
              ShadOption(value: 'false', child: Text('Not Linked (false)')),
            ],
            selectedOptionBuilder: (context, value) =>
                Text(value == 'true' ? 'Linked (true)' : 'Not Linked (false)'),
            onChanged: (value) {
              if (value != null) {
                _expectedValueController.text = value;
              }
            },
          ),
        ],

        // Link Count Mode
        if (_linkCheckMode == LinkCheckMode.linkCount) ...[
          // Device selector
          ShadSelectFormField<String>(
            id: 'deviceForCount',
            minWidth: double.infinity,
            label: const Text('Device'),
            placeholder: const Text('Select device'),
            options: devices.map((device) {
              return ShadOption(value: device.id, child: Text(device.name));
            }).toList(),
            selectedOptionBuilder: (context, value) {
              final device = devices.firstWhere((d) => d.id == value);
              return Text(device.name);
            },
            onChanged: (value) =>
                setState(() => _selectedTargetDeviceId = value),
          ),
          const SizedBox(height: 12),

          // Link count slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Expected Link Count:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    '${_linkCountValue.toInt()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _linkCountValue,
                min: 0,
                max: 10,
                divisions: 10,
                label: '${_linkCountValue.toInt()} links',
                onChanged: (value) {
                  setState(() {
                    _linkCountValue = value;
                    _expectedValueController.text = value.toInt().toString();
                  });
                },
              ),
            ],
          ),
        ],
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

  /// Get icon for condition type
  IconData _getConditionTypeIcon(ConditionType type) {
    switch (type) {
      case ConditionType.ping:
        return Icons.network_ping;
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

  /// Format protocol type for display
  String _formatProtocolType(PingProtocolType type) {
    switch (type) {
      case PingProtocolType.icmp:
        return 'ICMP (Ping)';
      case PingProtocolType.arp:
        return 'ARP';
    }
  }

  /// Format ping check type for display
  String _formatPingCheckType(PingCheckType type) {
    switch (type) {
      case PingCheckType.sent:
        return 'Packet Sent';
      case PingCheckType.received:
        return 'Packet Received';
      case PingCheckType.receivedFromAny:
        return 'Received from Any Source';
      case PingCheckType.receivedFromSpecific:
        return 'Received from Specific Source';
      case PingCheckType.responseTime:
        return 'Response Time Check';
      case PingCheckType.finalReply:
        return 'Final Reply Received';
    }
  }

  /// Reset all field selections when condition type changes
  void _resetFields() {
    _selectedSourceDeviceId = null;
    _selectedTargetDeviceIdForPing = null;
    _selectedTargetDeviceId = null;
    _selectedProperty = null;
    _selectedPropertyDataType = null;
    _selectedInterfaceName = null;
    _linkCheckMode = LinkCheckMode.booleanLinkStatus;
    _sourceDeviceForLink = null;
    _targetDeviceForLink = null;
    _linkCountValue = 1.0;
    _targetAddressController.clear();
    _expectedValueController.clear();
    _targetIpController.clear();
    _targetNetworkController.clear();
    _responseTimeController.text = '100';

    // Reset ICMP-specific fields (legacy)
    _icmpEventType = IcmpEventType.sent;
    _icmpDeviceScope = PingDeviceScope.anyDevice;
    _icmpSpecificDeviceId = null;
    _selectedProtocolType = PingProtocolType.icmp;
    _selectedPingCheckType = PingCheckType.finalReply;

    // Reset new ping session fields
    _usePingSessionMode = true;
    _pingSessionCheckType = PingSessionCheckType.success;
    _responseTimeOperator = ResponseTimeOperator.lessThan;
    _sourceDeviceIdForSession = null;
    _sourceInterfaceForSession = null;
    _destDeviceIdForSession = null;
    _destInterfaceForSession = null;

    // Initialize expected value for link check boolean mode (default)
    if (_selectedType == ConditionType.linkCheck) {
      _expectedValueController.text = 'true';
    }
  }

  void _saveCondition() {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    ScenarioCondition condition;

    if (_selectedType == ConditionType.ping) {
      // New session-based ping condition
      if (_sourceDeviceIdForSession == null ||
          _destDeviceIdForSession == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select source and destination devices'),
          ),
        );
        return;
      }

      // Parse response time threshold if applicable
      int? threshold;
      if (_pingSessionCheckType == PingSessionCheckType.responseTime) {
        threshold = int.tryParse(_responseTimeController.text);
        if (threshold == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid response time threshold'),
            ),
          );
          return;
        }
      }

      condition = ScenarioCondition(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: _descriptionController.text,
        type: ConditionType.ping,
        // New session-based fields
        pingSessionCheckType: _pingSessionCheckType,
        responseTimeOperator:
            _pingSessionCheckType == PingSessionCheckType.responseTime
            ? _responseTimeOperator
            : null,
        responseTimeThreshold: threshold,
        sourceDeviceIdForSession: _sourceDeviceIdForSession,
        sourceInterfaceForSession: _sourceInterfaceForSession,
        destDeviceIdForSession: _destDeviceIdForSession,
        destInterfaceForSession: _destInterfaceForSession,
      );
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
      // Validate based on mode
      if (_linkCheckMode == LinkCheckMode.booleanLinkStatus) {
        // Boolean mode: need source, target, and expected value
        if (_sourceDeviceForLink == null ||
            _targetDeviceForLink == null ||
            _expectedValueController.text.isEmpty) {
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
          type: ConditionType.linkCheck,
          linkCheckMode: LinkCheckMode.booleanLinkStatus,
          sourceDeviceIDForLink: _sourceDeviceForLink,
          targetDeviceIdForLink: _targetDeviceForLink,
          expectedValue: _expectedValueController.text,
          operator: PropertyOperator.equals,
        );
      } else {
        // Link count mode: need device and count value
        if (_selectedTargetDeviceId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a device')),
          );
          return;
        }

        condition = ScenarioCondition(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          description: _descriptionController.text,
          type: ConditionType.linkCheck,
          linkCheckMode: LinkCheckMode.linkCount,
          targetDeviceID: _selectedTargetDeviceId,
          expectedValue: _linkCountValue.toInt().toString(),
          operator: PropertyOperator.equals,
        );
      }
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
      case ConditionType.ping:
        return Icons.network_ping;
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
      case ConditionType.ping:
        return Icons.network_ping;
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
