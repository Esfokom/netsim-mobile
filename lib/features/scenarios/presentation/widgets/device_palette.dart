import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';

class DevicePalette extends ConsumerWidget {
  const DevicePalette({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasState = ref.watch(canvasProvider);

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (canvasState.isLinkingMode)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.withValues(alpha: 0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.link, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Linking Mode: Tap a device to connect',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.blue),
                    onPressed: () {
                      ref.read(canvasProvider.notifier).cancelLinking();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: DeviceType.values.map((type) {
                return _DevicePaletteItem(deviceType: type);
              }).toList(),
            ),
          ),
        ],
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
