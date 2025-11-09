import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/scenarios/data/models/scenario_condition.dart';

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
  final _sourceDeviceController = TextEditingController();
  final _targetAddressController = TextEditingController();

  // Property check fields
  final _targetDeviceController = TextEditingController();
  final _propertyController = TextEditingController();
  PropertyOperator _selectedOperator = PropertyOperator.equals;
  final _expectedValueController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _sourceDeviceController.dispose();
    _targetAddressController.dispose();
    _targetDeviceController.dispose();
    _propertyController.dispose();
    _expectedValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Success Condition',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., PC-01 must ping the server',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // Type selector
              DropdownButtonFormField<ConditionType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Condition Type',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: ConditionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Type-specific fields
              if (_selectedType == ConditionType.connectivity)
                _buildConnectivityFields()
              else
                _buildPropertyCheckFields(),

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

  Widget _buildConnectivityFields() {
    return Column(
      children: [
        DropdownButtonFormField<ConnectivityProtocol>(
          initialValue: _selectedProtocol,
          decoration: const InputDecoration(
            labelText: 'Protocol',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: ConnectivityProtocol.values.map((protocol) {
            return DropdownMenuItem(
              value: protocol,
              child: Text(protocol.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedProtocol = value);
            }
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sourceDeviceController,
          decoration: const InputDecoration(
            labelText: 'Source Device ID',
            hintText: 'e.g., PC-01',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _targetAddressController,
          decoration: const InputDecoration(
            labelText: 'Target Address',
            hintText: 'e.g., 8.8.8.8 or google.com',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCheckFields() {
    return Column(
      children: [
        TextField(
          controller: _targetDeviceController,
          decoration: const InputDecoration(
            labelText: 'Target Device ID',
            hintText: 'e.g., Router-01',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _propertyController,
          decoration: const InputDecoration(
            labelText: 'Property Name',
            hintText: 'e.g., powerState, current_ipAddress',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PropertyOperator>(
          initialValue: _selectedOperator,
          decoration: const InputDecoration(
            labelText: 'Operator',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: PropertyOperator.values.map((operator) {
            return DropdownMenuItem(
              value: operator,
              child: Text(operator.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedOperator = value);
            }
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _expectedValueController,
          decoration: const InputDecoration(
            labelText: 'Expected Value',
            hintText: 'e.g., ON, 192.168.1.1',
            border: OutlineInputBorder(),
            isDense: true,
          ),
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

    final condition = ScenarioCondition(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: _descriptionController.text,
      type: _selectedType,
      protocol: _selectedType == ConditionType.connectivity
          ? _selectedProtocol
          : null,
      sourceDeviceID: _selectedType == ConditionType.connectivity
          ? _sourceDeviceController.text
          : null,
      targetAddress: _selectedType == ConditionType.connectivity
          ? _targetAddressController.text
          : null,
      targetDeviceID: _selectedType == ConditionType.propertyCheck
          ? _targetDeviceController.text
          : null,
      property: _selectedType == ConditionType.propertyCheck
          ? _propertyController.text
          : null,
      operator: _selectedType == ConditionType.propertyCheck
          ? _selectedOperator
          : null,
      expectedValue: _selectedType == ConditionType.propertyCheck
          ? _expectedValueController.text
          : null,
    );

    ref.read(scenarioProvider.notifier).addCondition(condition);
    Navigator.pop(context);
  }
}
