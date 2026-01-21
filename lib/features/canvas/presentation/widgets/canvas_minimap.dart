import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';

/// Minimap widget that shows an overview of the entire canvas
class CanvasMinimap extends ConsumerStatefulWidget {
  final TransformationController transformationController;
  final Size canvasSize;

  const CanvasMinimap({
    super.key,
    required this.transformationController,
    required this.canvasSize,
  });

  @override
  ConsumerState<CanvasMinimap> createState() => _CanvasMinimapState();
}

class _CanvasMinimapState extends ConsumerState<CanvasMinimap> {
  @override
  void initState() {
    super.initState();
    // Listen to transformation changes to rebuild minimap
    // Add safety check for disposed controller
    try {
      widget.transformationController.addListener(_onTransformationChanged);
    } catch (e) {
      // Controller is already disposed, do nothing
    }
  }

  @override
  void didUpdateWidget(CanvasMinimap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the controller changed, update listeners
    if (oldWidget.transformationController != widget.transformationController) {
      // Remove old listener
      try {
        oldWidget.transformationController.removeListener(
          _onTransformationChanged,
        );
      } catch (e) {
        // Old controller was disposed, ignore
      }

      // Add new listener
      try {
        widget.transformationController.addListener(_onTransformationChanged);
      } catch (e) {
        // New controller is disposed, ignore
      }
    }
  }

  @override
  void dispose() {
    // Add safety check for disposed controller
    try {
      widget.transformationController.removeListener(_onTransformationChanged);
    } catch (e) {
      // Controller is already disposed, do nothing
    }
    super.dispose();
  }

  void _onTransformationChanged() {
    if (mounted) {
      setState(() {
        // Rebuild to update viewport indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Builder(
          builder: (context) {
            try {
              return CustomPaint(
                painter: MinimapPainter(
                  devices: canvasState.devices,
                  canvasSize: widget.canvasSize,
                  transformationController: widget.transformationController,
                  gridColor: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.1),
                  viewportColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  viewportBorderColor: Theme.of(context).colorScheme.primary,
                ),
              );
            } catch (e) {
              // If painting fails due to disposed controller, show fallback
              return Container(
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: Icon(
                    Icons.map_outlined,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 24,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

/// Custom painter for the minimap
class MinimapPainter extends CustomPainter {
  final List<CanvasDevice> devices;
  final Size canvasSize;
  final TransformationController transformationController;
  final Color gridColor;
  final Color viewportColor;
  final Color viewportBorderColor;

  MinimapPainter({
    required this.devices,
    required this.canvasSize,
    required this.transformationController,
    required this.gridColor,
    required this.viewportColor,
    required this.viewportBorderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale factor to fit canvas into minimap
    final scaleX = size.width / canvasSize.width;
    final scaleY = size.height / canvasSize.height;

    // Draw background grid
    _drawGrid(canvas, size);

    // Draw devices as colored dots
    _drawDevices(canvas, scaleX, scaleY);

    // Draw viewport indicator
    _drawViewport(canvas, size, scaleX, scaleY);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const gridSize = 50.0;
    final scaledGridSize = gridSize * (size.width / canvasSize.width);

    // Draw vertical lines
    for (double x = 0; x < size.width; x += scaledGridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += scaledGridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDevices(Canvas canvas, double scaleX, double scaleY) {
    for (final device in devices) {
      final paint = Paint()
        ..color = device.type.color
        ..style = PaintingStyle.fill;

      // Scale device position to minimap
      final x =
          device.position.dx * scaleX +
          40 * scaleX; // +40 to center device icon
      final y = device.position.dy * scaleY + 40 * scaleY;

      // Draw device as a small circle
      canvas.drawCircle(
        Offset(x, y),
        3.0, // Fixed dot size
        paint,
      );

      // Add white border for better visibility
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      canvas.drawCircle(Offset(x, y), 3.0, borderPaint);
    }
  }

  void _drawViewport(Canvas canvas, Size size, double scaleX, double scaleY) {
    // Get transformation matrix with safety check
    Matrix4 matrix;
    try {
      matrix = transformationController.value;
    } catch (e) {
      // Controller is disposed, use identity matrix
      matrix = Matrix4.identity();
    }

    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();

    // Calculate visible area in canvas coordinates
    final visibleLeft = -translation.x / scale;
    final visibleTop = -translation.y / scale;
    final visibleWidth = size.width / scaleX / scale;
    final visibleHeight = size.height / scaleY / scale;

    // Convert to minimap coordinates
    final viewportRect = Rect.fromLTWH(
      visibleLeft * scaleX,
      visibleTop * scaleY,
      visibleWidth * scaleX,
      visibleHeight * scaleY,
    );

    // Draw viewport fill
    final fillPaint = Paint()
      ..color = viewportColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(viewportRect, fillPaint);

    // Draw viewport border
    final borderPaint = Paint()
      ..color = viewportBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(viewportRect, borderPaint);
  }

  @override
  bool shouldRepaint(MinimapPainter oldDelegate) {
    return devices != oldDelegate.devices ||
        transformationController != oldDelegate.transformationController;
  }
}
