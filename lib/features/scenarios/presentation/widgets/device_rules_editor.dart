import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/device_rule.dart';
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
                  'Properties are hidden by default. Set permission to Read Only or Editable to show in simulation mode.',
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
                'No permissions defined\nAll properties are hidden in simulation',
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
    // Get color based on permission level
    Color permissionColor;
    IconData permissionIcon;
    switch (rule.permission) {
      case PropertyPermission.editable:
        permissionColor = Colors.green;
        permissionIcon = Icons.edit;
        break;
      case PropertyPermission.readonly:
        permissionColor = Colors.orange;
        permissionIcon = Icons.visibility;
        break;
      case PropertyPermission.denied:
        permissionColor = Colors.red;
        permissionIcon = Icons.visibility_off;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(permissionIcon, size: 18, color: permissionColor),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: permissionColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: permissionColor),
              ),
              child: Text(
                rule.permission.shortName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: permissionColor,
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
  PropertyPermission _selectedPermission = PropertyPermission.editable;
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
            // Permission Level Selector
            const Text(
              'Permission Level',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PermissionButton(
                    permission: PropertyPermission.denied,
                    isSelected:
                        _selectedPermission == PropertyPermission.denied,
                    onTap: () => setState(
                      () => _selectedPermission = PropertyPermission.denied,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PermissionButton(
                    permission: PropertyPermission.readonly,
                    isSelected:
                        _selectedPermission == PropertyPermission.readonly,
                    onTap: () => setState(
                      () => _selectedPermission = PropertyPermission.readonly,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PermissionButton(
                    permission: PropertyPermission.editable,
                    isSelected:
                        _selectedPermission == PropertyPermission.editable,
                    onTap: () => setState(
                      () => _selectedPermission = PropertyPermission.editable,
                    ),
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
      permission: _selectedPermission,
      actionType: _selectedActionType,
      propertyId: _selectedPropertyId,
    );

    ref.read(scenarioProvider.notifier).addDeviceRule(widget.deviceId, rule);
    Navigator.pop(context);
  }
}

/// Permission level toggle button
class _PermissionButton extends StatelessWidget {
  final PropertyPermission permission;
  final bool isSelected;
  final VoidCallback onTap;

  const _PermissionButton({
    required this.permission,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (permission) {
      case PropertyPermission.editable:
        color = Colors.green;
        icon = Icons.edit;
        break;
      case PropertyPermission.readonly:
        color = Colors.orange;
        icon = Icons.visibility;
        break;
      case PropertyPermission.denied:
        color = Colors.red;
        icon = Icons.visibility_off;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
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
              icon,
              size: 24,
              color: isSelected ? color : Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            Text(
              permission.shortName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
