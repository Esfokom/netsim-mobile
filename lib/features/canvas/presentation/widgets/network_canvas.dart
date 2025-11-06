import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/canvas_device_widget.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/links_painter.dart';

/// Notifier for the canvas transformation controller
class CanvasTransformationNotifier extends Notifier<TransformationController?> {
  @override
  TransformationController? build() => null;

  void setController(TransformationController controller) {
    state = controller;
  }
}

/// Provider for the canvas transformation controller
final canvasTransformationControllerProvider =
    NotifierProvider<CanvasTransformationNotifier, TransformationController?>(
      CanvasTransformationNotifier.new,
    );

class NetworkCanvas extends ConsumerStatefulWidget {
  const NetworkCanvas({super.key});

  @override
  ConsumerState<NetworkCanvas> createState() => _NetworkCanvasState();
}

class _NetworkCanvasState extends ConsumerState<NetworkCanvas> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    // Initialize the canvas centered on the grid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get the screen size
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final viewportSize = renderBox.size;

        // Canvas is 2000x2000, center it
        const canvasWidth = 2000.0;
        const canvasHeight = 2000.0;

        // Calculate offset to center the canvas
        final offsetX = (viewportSize.width - canvasWidth) / 2;
        final offsetY = (viewportSize.height - canvasHeight) / 2;

        // Set the transformation to center the canvas
        _transformationController.value = Matrix4.identity()
          ..setTranslationRaw(offsetX, offsetY, 0);
      }

      // Make the controller available to other widgets
      ref
          .read(canvasTransformationControllerProvider.notifier)
          .setController(_transformationController);
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Get the next number for a device type
  int _getNextDeviceNumber(DeviceType type, List<CanvasDevice> devices) {
    final devicesOfType = devices.where((d) => d.type == type).length;
    return devicesOfType + 1;
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider);
    final canvasNotifier = ref.read(canvasProvider.notifier);

    return DragTarget<DeviceType>(
      onAcceptWithDetails: (details) {
        // Get the position where the device was dropped
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);

        // Adjust for current transformation
        final matrix = _transformationController.value;
        final scale = matrix.getMaxScaleOnAxis();
        final translation = matrix.getTranslation();

        // Calculate the actual position on the canvas
        final adjustedPosition = Offset(
          (localPosition.dx - translation.x) / scale -
              40, // -40 to center the device
          (localPosition.dy - translation.y) / scale - 40,
        );

        // Get the next number for this device type
        final deviceNumber = _getNextDeviceNumber(
          details.data,
          canvasState.devices,
        );

        // Create and add the device
        final device = CanvasDevice(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '${details.data.displayName} $deviceNumber',
          type: details.data,
          position: adjustedPosition,
        );

        canvasNotifier.addDevice(device);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            // Deselect all devices when tapping empty space
            if (!canvasState.isLinkingMode) {
              canvasNotifier.deselectAllDevices();
            }
          },
          child: Container(
            color: candidateData.isNotEmpty
                ? Colors.green.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              constrained: false,
              child: SizedBox(
                width: 2000,
                height: 2000,
                child: Stack(
                  children: [
                    // Grid background
                    CustomPaint(
                      size: const Size(2000, 2000),
                      painter: GridPainter(),
                    ),
                    // Links between devices
                    CustomPaint(
                      size: const Size(2000, 2000),
                      painter: LinksPainter(
                        devices: canvasState.devices,
                        links: canvasState.links,
                      ),
                    ),
                    // Devices
                    ...canvasState.devices.map((device) {
                      return CanvasDeviceWidget(
                        key: ValueKey(device.id),
                        device: device,
                        scale: _transformationController.value
                            .getMaxScaleOnAxis(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Painter for grid background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    const gridSize = 50.0;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}
