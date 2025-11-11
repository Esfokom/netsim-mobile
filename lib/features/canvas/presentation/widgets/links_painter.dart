import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/data/models/device_link.dart';

class LinksPainter extends CustomPainter {
  final List<CanvasDevice> devices;
  final List<DeviceLink> links;
  final String? hoveredLinkId;

  LinksPainter({
    required this.devices,
    required this.links,
    this.hoveredLinkId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final link in links) {
      final fromDevice = devices
          .where((d) => d.id == link.fromDeviceId)
          .firstOrNull;
      final toDevice = devices
          .where((d) => d.id == link.toDeviceId)
          .firstOrNull;

      if (fromDevice != null && toDevice != null) {
        _drawLink(canvas, link, fromDevice, toDevice);
      }
    }
  }

  void _drawLink(
    Canvas canvas,
    DeviceLink link,
    CanvasDevice fromDevice,
    CanvasDevice toDevice,
  ) {
    // Calculate center points of devices (40 is half of device width/height)
    final start = Offset(
      fromDevice.position.dx + 40,
      fromDevice.position.dy + 40,
    );
    final end = Offset(toDevice.position.dx + 40, toDevice.position.dy + 40);

    final isHovered = link.id == hoveredLinkId;
    final isSelected = link.isSelected;

    // Main link paint with anti-aliasing
    final paint = Paint()
      ..strokeWidth = isSelected ? 3.5 : (isHovered ? 3.0 : 2.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Set color based on selection/hover state and link type
    if (isSelected) {
      paint.color = Colors.blue.shade600;
    } else if (isHovered) {
      paint.color = Colors.blue.shade400;
    } else {
      paint.color = _getLinkColor(link.type);
    }

    // Draw shadow for depth
    final shadowPaint = Paint()
      ..strokeWidth = paint.strokeWidth + 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Draw shadow first
    if (link.type == LinkType.wireless) {
      _drawDashedLine(canvas, start, end, shadowPaint);
    } else {
      canvas.drawLine(start, end, shadowPaint);
    }

    // Draw main line
    if (link.type == LinkType.wireless) {
      _drawDashedLine(canvas, start, end, paint);
    } else {
      canvas.drawLine(start, end, paint);
    }

    // Draw bidirectional arrows
    _drawBidirectionalArrows(canvas, start, end, paint);

    // Draw link info label if hovered or selected
    if (isHovered || isSelected) {
      _drawLinkInfo(canvas, start, end, link);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 6.0;
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

  void _drawBidirectionalArrows(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const arrowSize = 8.0;
    final direction = (end - start);
    final angle = direction.direction;

    // Calculate midpoint
    final mid = Offset.lerp(start, end, 0.5)!;

    // Arrow paint
    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw arrow pointing towards end
    canvas.save();
    canvas.translate(
      mid.dx + direction.dx * 0.15,
      mid.dy + direction.dy * 0.15,
    );
    canvas.rotate(angle);
    _drawArrowHead(canvas, arrowPaint, arrowSize);
    canvas.restore();

    // Draw arrow pointing towards start
    canvas.save();
    canvas.translate(
      mid.dx - direction.dx * 0.15,
      mid.dy - direction.dy * 0.15,
    );
    canvas.rotate(angle + 3.14159); // Rotate 180 degrees
    _drawArrowHead(canvas, arrowPaint, arrowSize);
    canvas.restore();
  }

  void _drawArrowHead(Canvas canvas, Paint paint, double size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(-size, -size * 0.5)
      ..lineTo(-size, size * 0.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawLinkInfo(Canvas canvas, Offset start, Offset end, DeviceLink link) {
    final mid = Offset.lerp(start, end, 0.5)!;

    final textSpan = TextSpan(
      text: '${link.type.displayName} Link',
      style: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw background for text
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: mid,
        width: textPainter.width + 12,
        height: textPainter.height + 6,
      ),
      const Radius.circular(4),
    );

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawRRect(bgRect, bgPaint);

    // Draw text
    textPainter.paint(
      canvas,
      Offset(mid.dx - textPainter.width / 2, mid.dy - textPainter.height / 2),
    );
  }

  Color _getLinkColor(LinkType type) {
    switch (type) {
      case LinkType.ethernet:
        return Colors.blue.shade700;
      case LinkType.wireless:
        return Colors.green.shade700;
      case LinkType.fiber:
        return Colors.orange.shade700;
    }
  }

  @override
  bool shouldRepaint(LinksPainter oldDelegate) {
    return oldDelegate.devices != devices ||
        oldDelegate.links != links ||
        oldDelegate.hoveredLinkId != hoveredLinkId;
  }
}
