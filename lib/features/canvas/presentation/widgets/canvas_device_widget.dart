import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';

class CanvasDeviceWidget extends ConsumerStatefulWidget {
  final CanvasDevice device;
  final double scale;

  const CanvasDeviceWidget({
    super.key,
    required this.device,
    required this.scale,
  });

  @override
  ConsumerState<CanvasDeviceWidget> createState() => _CanvasDeviceWidgetState();
}

class _CanvasDeviceWidgetState extends ConsumerState<CanvasDeviceWidget> {
  Offset? dragStartPosition;

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider);
    final canvasNotifier = ref.read(canvasProvider.notifier);

    return Positioned(
      left: widget.device.position.dx,
      top: widget.device.position.dy,
      child: GestureDetector(
        onTap: () {
          if (canvasState.isLinkingMode) {
            // Complete linking
            canvasNotifier.completeLinking(widget.device.id);
          } else {
            // Select device
            canvasNotifier.selectDevice(widget.device.id);
          }
        },
        onLongPress: () {
          _showDeviceMenu(context);
        },
        onPanStart: (details) {
          if (!canvasState.isLinkingMode) {
            dragStartPosition = widget.device.position;
            canvasNotifier.selectDevice(widget.device.id);
          }
        },
        onPanUpdate: (details) {
          if (!canvasState.isLinkingMode && dragStartPosition != null) {
            final newPosition = Offset(
              dragStartPosition!.dx + details.localPosition.dx,
              dragStartPosition!.dy + details.localPosition.dy,
            );
            canvasNotifier.updateDevicePosition(widget.device.id, newPosition);
          }
        },
        onPanEnd: (details) {
          dragStartPosition = null;
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: widget.device.type.color.withValues(alpha: 0.2),
            border: Border.all(
              color: widget.device.isSelected
                  ? Colors.blue
                  : widget.device.type.color,
              width: widget.device.isSelected ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.device.isSelected
                ? [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.device.type.icon,
                size: 32,
                color: widget.device.type.color,
              ),
              const SizedBox(height: 4),
              Text(
                widget.device.name,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.device.status.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeviceMenu(BuildContext context) {
    final canvasNotifier = ref.read(canvasProvider.notifier);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.device.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Create Link'),
              onTap: () {
                Navigator.pop(context);
                canvasNotifier.startLinking(widget.device.id);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.power_settings_new,
                color: widget.device.status.color,
              ),
              title: const Text('Toggle Status'),
              onTap: () {
                final newStatus = widget.device.status == DeviceStatus.online
                    ? DeviceStatus.offline
                    : DeviceStatus.online;
                canvasNotifier.updateDeviceStatus(widget.device.id, newStatus);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                canvasNotifier.removeDevice(widget.device.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
