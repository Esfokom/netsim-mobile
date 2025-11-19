import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/network_canvas.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/devices/domain/factories/device_factory.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/scenario_bottom_panel.dart';

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
  Timer? _edgeScrollTimer;

  @override
  void dispose() {
    _edgeScrollTimer?.cancel();
    super.dispose();
  }

  /// Start edge scrolling when dragging near screen edges
  void _startEdgeScrolling(Offset globalPosition, BuildContext context) {
    // Don't restart timer if already scrolling in same direction
    final transformationController = ref.read(
      canvasTransformationControllerProvider,
    );
    if (transformationController == null) return;

    const edgeThreshold = 50.0; // Pixels from edge to trigger scrolling
    const scrollSpeed = 8.0; // Reduced speed for better control

    final screenSize = MediaQuery.of(context).size;

    // Calculate scroll direction based on proximity to edges
    double scrollX = 0;
    double scrollY = 0;

    if (globalPosition.dx < edgeThreshold) {
      scrollX = scrollSpeed; // Scroll right (pan canvas left)
    } else if (globalPosition.dx > screenSize.width - edgeThreshold) {
      scrollX = -scrollSpeed; // Scroll left (pan canvas right)
    }

    if (globalPosition.dy < edgeThreshold) {
      scrollY = scrollSpeed; // Scroll down (pan canvas up)
    } else if (globalPosition.dy > screenSize.height - edgeThreshold) {
      scrollY = -scrollSpeed; // Scroll up (pan canvas down)
    }

    // If not near any edge, stop scrolling
    if (scrollX == 0 && scrollY == 0) {
      _stopEdgeScrolling();
      return;
    }

    // If already scrolling, don't create new timer
    if (_edgeScrollTimer?.isActive ?? false) {
      return;
    }

    // Start periodic scrolling
    _edgeScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      final currentMatrix = transformationController.value.clone();
      final translation = currentMatrix.getTranslation();

      // Apply scroll to canvas transformation
      currentMatrix.setTranslationRaw(
        translation.x + scrollX,
        translation.y + scrollY,
        0,
      );

      transformationController.value = currentMatrix;
    });
  }

  /// Stop edge scrolling
  void _stopEdgeScrolling() {
    _edgeScrollTimer?.cancel();
    _edgeScrollTimer = null;
  }

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
            // Select device in canvas
            canvasNotifier.selectDevice(widget.device.id);

            // Also select in scenario provider for contextual editor
            Future.microtask(() {
              ref
                  .read(scenarioProvider.notifier)
                  .selectDevice(widget.device.id);
              // Switch to properties tab automatically
              ref
                  .read(bottomPanelTabProvider.notifier)
                  .setTab(BottomPanelTab.properties);
            });

            // Device details now shown in properties tab - no dialog
          }
        },
        onLongPress: () {
          // Select device for properties tab on long press
          canvasNotifier.selectDevice(widget.device.id);
          Future.microtask(() {
            ref.read(scenarioProvider.notifier).selectDevice(widget.device.id);
            // Switch to properties tab automatically
            ref
                .read(bottomPanelTabProvider.notifier)
                .setTab(BottomPanelTab.properties);
          });
        },
        onPanStart: (details) {
          if (!canvasState.isLinkingMode) {
            dragStartPosition = widget.device.position;
            canvasNotifier.selectDevice(widget.device.id);
          }
        },
        onPanUpdate: (details) {
          if (!canvasState.isLinkingMode && dragStartPosition != null) {
            // Check if near edge and start scrolling if needed
            _startEdgeScrolling(details.globalPosition, context);

            // Get current transformation
            final transformationController = ref.read(
              canvasTransformationControllerProvider,
            );

            if (transformationController != null) {
              final matrix = transformationController.value;
              final scale = matrix.getMaxScaleOnAxis();
              final translation = matrix.getTranslation();

              // Convert global position to canvas coordinates
              final canvasX =
                  (details.globalPosition.dx - translation.x) / scale;
              final canvasY =
                  (details.globalPosition.dy - translation.y) / scale;

              // Calculate new device position (centered on cursor)
              const deviceSize = 80.0;
              final newPosition = Offset(
                canvasX - (deviceSize / 2),
                canvasY - (deviceSize / 2),
              );

              // Constrain position to canvas bounds
              const canvasWidth = 2000.0;
              const canvasHeight = 2000.0;

              final constrainedPosition = Offset(
                newPosition.dx.clamp(0.0, canvasWidth - deviceSize),
                newPosition.dy.clamp(0.0, canvasHeight - deviceSize),
              );

              canvasNotifier.updateDevicePosition(
                widget.device.id,
                constrainedPosition,
              );
            }
          }
        },
        onPanEnd: (details) {
          dragStartPosition = null;
          _stopEdgeScrolling();
        },
        child: Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: widget.device.type.color.withValues(alpha: 0.2),
                border: Border.all(
                  color: widget.device.isSelected
                      ? Colors.blue
                      : canvasState.isLinkingMode &&
                            canvasState.linkingFromDeviceId == widget.device.id
                      ? Colors.green
                      : widget.device.type.color,
                  width: widget.device.isSelected
                      ? 3
                      : canvasState.isLinkingMode &&
                            canvasState.linkingFromDeviceId == widget.device.id
                      ? 3
                      : 2,
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
                    : canvasState.isLinkingMode &&
                          canvasState.linkingFromDeviceId == widget.device.id
                    ? [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.5),
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
            // Linking mode badge
            if (canvasState.isLinkingMode &&
                canvasState.linkingFromDeviceId == widget.device.id)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.cable, size: 16, color: Colors.white),
                ),
              ),
            // Clickable to link badge
            if (canvasState.isLinkingMode &&
                canvasState.linkingFromDeviceId != widget.device.id &&
                canvasState.linkingFromDeviceId != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_link,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
