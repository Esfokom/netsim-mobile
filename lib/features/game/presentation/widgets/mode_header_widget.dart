import 'package:flutter/material.dart';

/// Mode types for the header
enum HeaderMode { edit, simulation, playing }

/// Extension for header mode styling
extension HeaderModeExtension on HeaderMode {
  String get label {
    switch (this) {
      case HeaderMode.edit:
        return 'EDIT MODE';
      case HeaderMode.simulation:
        return 'SIMULATION MODE';
      case HeaderMode.playing:
        return 'PLAYING';
    }
  }

  IconData get icon {
    switch (this) {
      case HeaderMode.edit:
        return Icons.edit;
      case HeaderMode.simulation:
        return Icons.play_circle;
      case HeaderMode.playing:
        return Icons.play_circle;
    }
  }

  Color get color {
    switch (this) {
      case HeaderMode.edit:
        return Colors.blue;
      case HeaderMode.simulation:
        return Colors.green;
      case HeaderMode.playing:
        return Colors.green;
    }
  }
}

/// Reusable mode header widget for scenario editor and game screens
/// Displays mode badge, title, description, and optional actions
class ModeHeaderWidget extends StatelessWidget {
  final HeaderMode mode;
  final String title;
  final String description;
  final bool isCollapsible;
  final VoidCallback? onTap;
  final List<Widget>? actions;
  final Widget? timer;

  const ModeHeaderWidget({
    super.key,
    required this.mode,
    required this.title,
    required this.description,
    this.isCollapsible = false,
    this.onTap,
    this.actions,
    this.timer,
  });

  @override
  Widget build(BuildContext context) {
    final Widget header = Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildModeBadge(),
              const Spacer(),
              if (timer != null) ...[timer!, const SizedBox(width: 8)],
              if (actions != null) ...actions!,
              if (isCollapsible)
                Icon(Icons.expand_more, size: 20, color: Colors.grey.shade600),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: isCollapsible ? 1 : null,
            overflow: isCollapsible ? TextOverflow.ellipsis : null,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            maxLines: isCollapsible ? 1 : null,
            overflow: isCollapsible ? TextOverflow.ellipsis : null,
          ),
        ],
      ),
    );

    if (isCollapsible && onTap != null) {
      return GestureDetector(onTap: onTap, child: header);
    }

    return header;
  }

  Widget _buildModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: mode.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mode.icon, size: 16, color: mode.color),
          const SizedBox(width: 4),
          Text(
            mode.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: mode.color,
            ),
          ),
        ],
      ),
    );
  }
}
