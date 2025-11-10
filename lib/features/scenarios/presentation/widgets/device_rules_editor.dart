import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:netsim_mobile/features/scenarios/data/models/device_rule.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';

/// Widget for managing device rules in edit mode
class DeviceRulesEditor extends ConsumerWidget {
  final String deviceId;

  const DeviceRulesEditor({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarioNotifier = ref.read(scenarioProvider.notifier);
    final rules = scenarioNotifier.getDeviceRules(deviceId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Simulation Rules',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _showAddRuleDialog(context, ref),
              tooltip: 'Add Rule',
            ),
          ],
        ),
        const SizedBox(height: 8),
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
                  'No rules = No actions allowed. Add allow rules to enable actions in simulation mode.',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (rules.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No rules defined\nAll actions blocked in simulation',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...rules.map((rule) => _RuleCard(deviceId: deviceId, rule: rule)),
      ],
    );
  }

  void _showAddRuleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AddRuleDialog(deviceId: deviceId),
    );
  }
}

/// Card displaying a single rule
class _RuleCard extends ConsumerWidget {
  final String deviceId;
  final DeviceRule rule;

  const _RuleCard({required this.deviceId, required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: rule.type == RuleType.allow
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: rule.type == RuleType.allow
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              child: Text(
                rule.type.displayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: rule.type == RuleType.allow
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.actionType.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (rule.propertyId != null)
                    Text(
                      'Property: ${rule.propertyId}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              onPressed: () {
                ref
                    .read(scenarioProvider.notifier)
                    .removeDeviceRule(deviceId, rule.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for adding a new rule
class _AddRuleDialog extends ConsumerStatefulWidget {
  final String deviceId;

  const _AddRuleDialog({required this.deviceId});

  @override
  ConsumerState<_AddRuleDialog> createState() => _AddRuleDialogState();
}

class _AddRuleDialogState extends ConsumerState<_AddRuleDialog> {
  RuleType _selectedRuleType = RuleType.allow;
  DeviceActionType _selectedActionType = DeviceActionType.editProperty;
  String? _selectedPropertyId;

  @override
  Widget build(BuildContext context) {
    final canvasNotifier = ref.read(canvasProvider.notifier);
    final networkDevice = canvasNotifier.getNetworkDevice(widget.deviceId);
    final properties = networkDevice?.properties ?? [];

    return Dialog(
      child: ShadCard(
        title: const Text('Add Rule'),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rule Type Toggle
            Row(
              children: [
                Expanded(
                  child: _RuleTypeButton(
                    type: RuleType.allow,
                    isSelected: _selectedRuleType == RuleType.allow,
                    onTap: () =>
                        setState(() => _selectedRuleType = RuleType.allow),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RuleTypeButton(
                    type: RuleType.deny,
                    isSelected: _selectedRuleType == RuleType.deny,
                    onTap: () =>
                        setState(() => _selectedRuleType = RuleType.deny),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Type
            ShadSelectFormField<DeviceActionType>(
              id: 'actionType',
              minWidth: double.infinity,
              initialValue: _selectedActionType,
              label: const Text('Action Type'),
              options: DeviceActionType.values.map((action) {
                return ShadOption(
                  value: action,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        action.description,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              selectedOptionBuilder: (context, value) =>
                  Text(value.displayName),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedActionType = value;
                    if (value != DeviceActionType.editProperty) {
                      _selectedPropertyId = null;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Property selector (only for editProperty action)
            if (_selectedActionType == DeviceActionType.editProperty)
              ShadSelectFormField<String>(
                id: 'property',
                minWidth: double.infinity,
                initialValue: _selectedPropertyId,
                label: const Text('Property (Optional)'),
                placeholder: const Text('All properties'),
                options: [
                  const ShadOption(
                    value: '__ALL__',
                    child: Text('All Properties'),
                  ),
                  ...properties.map((prop) {
                    return ShadOption(value: prop.id, child: Text(prop.label));
                  }),
                ],
                selectedOptionBuilder: (context, value) {
                  if (value == '__ALL__') return const Text('All Properties');
                  return Text(
                    properties.where((p) => p.id == value).firstOrNull?.label ??
                        value,
                  );
                },
                onChanged: (value) {
                  setState(() {
                    _selectedPropertyId = value == '__ALL__' ? null : value;
                  });
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
                ElevatedButton(onPressed: _saveRule, child: const Text('Add')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveRule() {
    final rule = DeviceRule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedRuleType,
      actionType: _selectedActionType,
      propertyId: _selectedPropertyId,
    );

    ref.read(scenarioProvider.notifier).addDeviceRule(widget.deviceId, rule);
    Navigator.pop(context);
  }
}

/// Rule type toggle button
class _RuleTypeButton extends StatelessWidget {
  final RuleType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _RuleTypeButton({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = type == RuleType.allow ? Colors.green : Colors.red;

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
              type == RuleType.allow ? Icons.check_circle : Icons.block,
              size: 32,
              color: isSelected ? color : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 13,
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
