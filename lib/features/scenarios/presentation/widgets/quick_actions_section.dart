import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/switch_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart';

/// Quick actions section for devices (Ping, View ARP, Configure Ports, etc.)
class QuickActionsSection extends ConsumerWidget {
  final NetworkDevice networkDevice;
  final Function(String actionId) onActionTap;

  const QuickActionsSection({
    super.key,
    required this.networkDevice,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = networkDevice.getAvailableActions();

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((action) {
              return ActionButton(
                action: action,
                onTap: () => onActionTap(action.id),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final dynamic action; // DeviceAction type
  final VoidCallback onTap;

  const ActionButton({super.key, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
