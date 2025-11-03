import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/data/models/device_link.dart';

class LinksPainter extends CustomPainter {
  final List<CanvasDevice> devices;
  final List<DeviceLink> links;

  LinksPainter({required this.devices, required this.links});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final link in links) {
      final fromDevice = devices
          .where((d) => d.id == link.fromDeviceId)
          .firstOrNull;
      final toDevice = devices
          .where((d) => d.id == link.toDeviceId)
          .firstOrNull;

      if (fromDevice != null && toDevice != null) {
        // Calculate center points of devices (40 is half of device width/height)
        final start = Offset(
          fromDevice.position.dx + 40,
          fromDevice.position.dy + 40,
        );
        final end = Offset(
          toDevice.position.dx + 40,
          toDevice.position.dy + 40,
        );

        // Set color based on link type
        paint.color = link.isSelected ? Colors.blue : _getLinkColor(link.type);

        // Draw dashed line for wireless, solid for others
        if (link.type == LinkType.wireless) {
          _drawDashedLine(canvas, start, end, paint);
        } else {
          canvas.drawLine(start, end, paint);
        }

        // Draw arrow at the end
        _drawArrow(canvas, start, end, paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5;
    const dashSpace = 5;
    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startDash = Offset.lerp(
        start,
        end,
        i * (dashWidth + dashSpace) / distance,
      )!;
      final endDash = Offset.lerp(
        start,
        end,
        (i * (dashWidth + dashSpace) + dashWidth) / distance,
      )!;
      canvas.drawLine(startDash, endDash, paint);
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    const arrowSize = 10;
    final angle = (end - start).direction;

    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx -
          arrowSize *
              (1.5 * (end.dx - start.dx).sign) *
              (1 +
                  0.5 *
                      ((end.dy - start.dy).abs() / (end.dx - start.dx).abs())),
      end.dy - arrowSize * 0.5 * (end.dy - start.dy).sign,
    );
    arrowPath.lineTo(
      end.dx - arrowSize * 0.5 * (end.dx - start.dx).sign,
      end.dy -
          arrowSize *
              (1.5 * (end.dy - start.dy).sign) *
              (1 +
                  0.5 *
                      ((end.dx - start.dx).abs() / (end.dy - start.dy).abs())),
    );
    arrowPath.close();

    canvas.save();
    canvas.translate(end.dx, end.dy);
    canvas.rotate(angle);
    canvas.translate(-end.dx, -end.dy);

    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    // Simple arrow triangle
    final arrowPath2 = Path();
    arrowPath2.moveTo(end.dx, end.dy);
    arrowPath2.lineTo(end.dx - arrowSize, end.dy - arrowSize / 2);
    arrowPath2.lineTo(end.dx - arrowSize, end.dy + arrowSize / 2);
    arrowPath2.close();

    canvas.drawPath(arrowPath2, arrowPaint);
    canvas.restore();
  }

  Color _getLinkColor(LinkType type) {
    switch (type) {
      case LinkType.ethernet:
        return Colors.blue;
      case LinkType.wireless:
        return Colors.green;
      case LinkType.fiber:
        return Colors.orange;
    }
  }

  @override
  bool shouldRepaint(LinksPainter oldDelegate) {
    return oldDelegate.devices != devices || oldDelegate.links != links;
  }
}
