import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';

/// Basic properties section (ID, Name, Position)
class BasicPropertiesSection extends ConsumerWidget {
  final CanvasDevice device;
  final bool simulationMode;

  const BasicPropertiesSection({
    super.key,
    required this.device,
    this.simulationMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasNotifier = ref.read(canvasProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Basic Properties',
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              _buildPropertyTile(
                context,
                icon: Icons.tag,
                label: 'Device ID',
                value: device.id,
                onTap: simulationMode
                    ? null
                    : () => _showEditDialog(
                        context,
                        'Device ID',
                        device.id,
                        (value) {
                          if (value.length != 13 ||
                              int.tryParse(value) == null) {
                            return 'Device ID must be exactly 13 digits';
                          }
                          // Check if ID already exists
                          final canvasState = ref.read(canvasProvider);
                          if (canvasState.devices.any(
                            (d) => d.id == value && d.id != device.id,
                          )) {
                            return 'Device ID already exists';
                          }
                          return null;
                        },
                        (value) =>
                            canvasNotifier.updateDeviceId(device.id, value),
                      ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              _buildPropertyTile(
                context,
                icon: Icons.label,
                label: 'Name',
                value: device.name,
                onTap: simulationMode
                    ? null
                    : () => _showEditDialog(
                        context,
                        'Device Name',
                        device.name,
                        (value) {
                          if (value.trim().isEmpty) {
                            return 'Device name cannot be empty';
                          }
                          // Check if name already exists
                          final canvasState = ref.read(canvasProvider);
                          if (canvasState.devices.any(
                            (d) => d.name == value.trim() && d.id != device.id,
                          )) {
                            return 'Device name already exists';
                          }
                          return null;
                        },
                        (value) => canvasNotifier.updateDeviceName(
                          device.id,
                          value.trim(),
                        ),
                      ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              _buildPropertyTile(
                context,
                icon: Icons.place,
                label: 'Position',
                value:
                    '(${device.position.dx.toInt()}, ${device.position.dy.toInt()})',
                onTap: simulationMode
                    ? null
                    : () => _showPositionEditDialog(
                        context,
                        device,
                        canvasNotifier,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.edit, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String title,
    String currentValue,
    String? Function(String) validator,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: currentValue);
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit $title'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: title,
                border: const OutlineInputBorder(),
                errorText: errorText,
              ),
              onChanged: (value) {
                setState(() {
                  errorText = validator(value);
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: errorText == null
                    ? () {
                        onSave(controller.text);
                        Navigator.pop(ctx);
                      }
                    : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPositionEditDialog(
    BuildContext context,
    CanvasDevice device,
    dynamic canvasNotifier,
  ) {
    final xController = TextEditingController(
      text: device.position.dx.toInt().toString(),
    );
    final yController = TextEditingController(
      text: device.position.dy.toInt().toString(),
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Position'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: xController,
                  decoration: InputDecoration(
                    labelText: 'X Position',
                    border: const OutlineInputBorder(),
                    errorText: errorText,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      final x = int.tryParse(value);
                      if (x == null) {
                        errorText = 'Invalid number';
                      } else if (x < 0 || x > 2000) {
                        errorText = 'X must be between 0 and 2000';
                      } else {
                        errorText = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: yController,
                  decoration: InputDecoration(
                    labelText: 'Y Position',
                    border: const OutlineInputBorder(),
                    errorText: errorText,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      final y = int.tryParse(value);
                      if (y == null) {
                        errorText = 'Invalid number';
                      } else if (y < 0 || y > 2000) {
                        errorText = 'Y must be between 0 and 2000';
                      } else {
                        errorText = null;
                      }
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: errorText == null
                    ? () {
                        final x = double.parse(xController.text);
                        final y = double.parse(yController.text);
                        canvasNotifier.updateDevicePosition(
                          device.id,
                          Offset(x, y),
                        );
                        Navigator.pop(ctx);
                      }
                    : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
