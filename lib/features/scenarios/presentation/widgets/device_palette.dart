import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';

class DevicePalette extends ConsumerWidget {
  const DevicePalette({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: DeviceType.values.map((type) {
            return _DevicePaletteItem(deviceType: type);
          }).toList(),
        ),
      ),
    );
  }
}

class _DevicePaletteItem extends ConsumerWidget {
  final DeviceType deviceType;

  const _DevicePaletteItem({required this.deviceType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Draggable<DeviceType>(
      data: deviceType,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: _buildDeviceCard(context, isDragging: true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildDeviceCard(context),
      ),
      child: _buildDeviceCard(context),
    );
  }

  Widget _buildDeviceCard(BuildContext context, {bool isDragging = false}) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: deviceType.color.withValues(alpha: 0.1),
        border: Border.all(color: deviceType.color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(deviceType.icon, size: 36, color: deviceType.color),
          const SizedBox(height: 4),
          Text(
            deviceType.displayName,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
