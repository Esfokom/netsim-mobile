import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/alert_notification.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/alert_notification_provider.dart';

/// Z-stack widget that displays alert notifications
class AlertNotificationStack extends ConsumerStatefulWidget {
  final double bottomOffset; // Offset from bottom (e.g., for bottom sheets)

  const AlertNotificationStack({super.key, this.bottomOffset = 16.0});

  @override
  ConsumerState<AlertNotificationStack> createState() =>
      _AlertNotificationStackState();
}

class _AlertNotificationStackState
    extends ConsumerState<AlertNotificationStack> {
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertState = ref.watch(alertNotificationProvider);
    final currentAlert = alertState.currentAlert;
    final isShowing = alertState.isShowingAlert;

    // Start dismiss timer when alert is shown
    if (isShowing && currentAlert != null) {
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          ref.read(alertNotificationProvider.notifier).dismissCurrentAlert();
        }
      });
    }

    if (!isShowing || currentAlert == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: widget.bottomOffset,
      child: _AlertCard(
        alert: currentAlert,
        onDismiss: () {
          _dismissTimer?.cancel();
          ref.read(alertNotificationProvider.notifier).dismissCurrentAlert();
        },
      ),
    );
  }
}

/// Compact alert card with expansion capability
class _AlertCard extends StatefulWidget {
  final AlertNotification alert;
  final VoidCallback onDismiss;

  const _AlertCard({required this.alert, required this.onDismiss});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Color _getAlertColor() {
    switch (widget.alert.type) {
      case AlertType.info:
        return Colors.blue;
      case AlertType.success:
        return Colors.green;
      case AlertType.warning:
        return Colors.orange;
      case AlertType.error:
        return Colors.red;
    }
  }

  IconData _getAlertIcon() {
    switch (widget.alert.type) {
      case AlertType.info:
        return Icons.info_outline;
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.warning:
        return Icons.warning_amber_outlined;
      case AlertType.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertColor = _getAlertColor();
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _toggleExpand,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: alertColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact view (always visible)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Alert icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: alertColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_getAlertIcon(), color: alertColor, size: 24),
                    ),
                    const SizedBox(width: 12),

                    // Title and message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.alert.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.alert.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: _isExpanded ? null : 1,
                            overflow: _isExpanded
                                ? null
                                : TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Expand/collapse button
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),

                    // Dismiss button
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: widget.onDismiss,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),

              // Expanded details
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Protocol type
                      if (widget.alert.protocolType != null)
                        _DetailRow(
                          label: 'Protocol',
                          value: widget.alert.protocolType!.toUpperCase(),
                          icon: Icons.dns,
                        ),

                      // Source device
                      if (widget.alert.sourceDeviceName != null)
                        _DetailRow(
                          label: 'Source',
                          value: widget.alert.sourceDeviceName!,
                          icon: Icons.devices,
                        ),

                      // Target device
                      if (widget.alert.targetDeviceName != null)
                        _DetailRow(
                          label: 'Target',
                          value: widget.alert.targetDeviceName!,
                          icon: Icons.devices,
                        ),

                      // Response time
                      if (widget.alert.responseTimeMs != null)
                        _DetailRow(
                          label: 'Response Time',
                          value: '${widget.alert.responseTimeMs}ms',
                          icon: Icons.timer,
                          valueColor: widget.alert.responseTimeMs! > 100
                              ? Colors.orange
                              : Colors.green,
                        ),

                      // Timestamp
                      _DetailRow(
                        label: 'Time',
                        value: _formatTime(widget.alert.timestamp),
                        icon: Icons.access_time,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Detail row widget
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
