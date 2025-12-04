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
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag devices onto the canvas',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),

          // Device Grid - compact layout
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DeviceType.values.map((type) {
              return _DevicePaletteItem(deviceType: type);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DevicePaletteItem extends ConsumerStatefulWidget {
  final DeviceType deviceType;

  const _DevicePaletteItem({required this.deviceType});

  @override
  ConsumerState<_DevicePaletteItem> createState() => _DevicePaletteItemState();
}

class _DevicePaletteItemState extends ConsumerState<_DevicePaletteItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate item width to fit 4 items per row with spacing (more compact)
    final itemWidth = (screenWidth - 72) / 4; // 72 = padding + spacing

    // Constrain the size to reasonable bounds
    final constrainedWidth = itemWidth.clamp(60.0, 80.0);

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: LongPressDraggable<DeviceType>(
        data: widget.deviceType,
        delay: const Duration(milliseconds: 100),
        hapticFeedbackOnStart: true,
        onDragStarted: () {
          setState(() => _isDragging = true);
          _animationController.forward();
        },
        onDragEnd: (_) {
          setState(() => _isDragging = false);
          _animationController.reverse();
        },
        onDraggableCanceled: (_, __) {
          setState(() => _isDragging = false);
          _animationController.reverse();
        },
        // Feedback is the dragged widget - sized to match canvas device (80x80)
        feedback: _DragFeedback(deviceType: widget.deviceType),
        // Use feedbackOffset to center the feedback on the touch point
        feedbackOffset: const Offset(-40, -40),
        childWhenDragging: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: 0.3,
              child: Transform.scale(
                scale: 0.9,
                child: _buildPaletteCard(context, constrainedWidth),
              ),
            );
          },
        ),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isDragging ? 0.95 : _scaleAnimation.value,
              child: _buildPaletteCard(context, constrainedWidth),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaletteCard(BuildContext context, double width) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: 70, // Reduced from 100
      decoration: BoxDecoration(
        color: widget.deviceType.color.withValues(alpha: isDark ? 0.15 : 0.1),
        border: Border.all(
          color: widget.deviceType.color.withValues(alpha: 0.6),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.deviceType.icon,
            size: 24, // Reduced from 36
            color: widget.deviceType.color,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              widget.deviceType.displayName,
              style: TextStyle(
                fontSize: 9, // Reduced from 12
                fontWeight: FontWeight.w600,
                color: widget.deviceType.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated drag feedback widget that matches canvas device size
class _DragFeedback extends StatefulWidget {
  final DeviceType deviceType;

  const _DragFeedback({required this.deviceType});

  @override
  State<_DragFeedback> createState() => _DragFeedbackState();
}

class _DragFeedbackState extends State<_DragFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(12),
              shadowColor: widget.deviceType.color.withValues(alpha: 0.5),
              child: Container(
                width: 80, // Match canvas device size
                height: 80,
                decoration: BoxDecoration(
                  color: widget.deviceType.color.withValues(alpha: 0.2),
                  border: Border.all(color: widget.deviceType.color, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.deviceType.color.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.deviceType.icon,
                      size: 32,
                      color: widget.deviceType.color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.deviceType.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: widget.deviceType.color,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
