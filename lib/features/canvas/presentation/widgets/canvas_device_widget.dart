import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/canvas/domain/factories/device_factory.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/device_details_panel.dart';

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

    // Get NetworkDevice to access displayName (which respects showIpOnCanvas toggle)
    NetworkDevice? networkDevice = canvasNotifier.getNetworkDevice(
      widget.device.id,
    );

    // If not cached yet, create it
    if (networkDevice == null) {
      networkDevice = DeviceFactory.fromCanvasDevice(widget.device);
      // Cache it after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        canvasNotifier.setNetworkDevice(widget.device.id, networkDevice!);
      });
    }

    return Positioned(
      left: widget.device.position.dx,
      top: widget.device.position.dy,
      child: GestureDetector(
        onTap: () {
          if (canvasState.isLinkingMode) {
            // Complete linking
            canvasNotifier.completeLinking(widget.device.id);
          } else {
            // Select device and show details
            canvasNotifier.selectDevice(widget.device.id);
            _showDeviceMenu(context);
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
                networkDevice
                    .displayName, // Use NetworkDevice displayName instead of widget.device.name
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
    // Show the new DeviceDetailsPanel with rich device information
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          // Watch canvas state to rebuild when device changes
          final canvasState = ref.watch(canvasProvider);
          final canvasNotifier = ref.read(canvasProvider.notifier);

          // Find the current device from canvas state
          final canvasDevice = canvasState.devices.firstWhere(
            (d) => d.id == widget.device.id,
            orElse: () => widget.device,
          );

          // Get or create NetworkDevice
          NetworkDevice networkDevice;
          final cachedDevice = canvasNotifier.getNetworkDevice(canvasDevice.id);

          if (cachedDevice != null) {
            // Use cached device to preserve state
            networkDevice = cachedDevice;
            // Update position if changed
            networkDevice.updatePosition(canvasDevice.position);
          } else {
            // Create new NetworkDevice and cache it AFTER build completes
            networkDevice = DeviceFactory.fromCanvasDevice(canvasDevice);

            // Delay the cache update until after the build phase
            WidgetsBinding.instance.addPostFrameCallback((_) {
              canvasNotifier.setNetworkDevice(canvasDevice.id, networkDevice);
            });
          }

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: DeviceDetailsPanel(
              device: networkDevice,
              onClose: () {
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}
