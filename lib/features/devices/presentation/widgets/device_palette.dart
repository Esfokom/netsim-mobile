import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';

class DevicePalette extends ConsumerWidget {
  const DevicePalette({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Icon(
                  Icons.devices,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Device Palette',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Info hint
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
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
                    'Drag devices onto the canvas to add them',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),

          // Device Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: DeviceType.values.map((type) {
              return _DevicePaletteItem(deviceType: type);
            }).toList(),
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
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate item width to fit 3 items per row with spacing
    final itemWidth = (screenWidth - 80) / 3; // 80 = padding + spacing

    return Draggable<DeviceType>(
      data: deviceType,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: _buildDeviceCard(context, itemWidth, isDragging: true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildDeviceCard(context, itemWidth),
      ),
      child: _buildDeviceCard(context, itemWidth),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    double width, {
    bool isDragging = false,
  }) {
    return Container(
      width: width,
      height: 100,
      decoration: BoxDecoration(
        color: deviceType.color.withValues(alpha: 0.1),
        border: Border.all(color: deviceType.color, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: deviceType.color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(deviceType.icon, size: 36, color: deviceType.color),
          const SizedBox(height: 8),
          Text(
            deviceType.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: deviceType.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
