import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/alert_notification.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/alert_notification_provider.dart';

/// Dialog showing alert history
class AlertHistoryDialog extends ConsumerStatefulWidget {
  const AlertHistoryDialog({super.key});

  @override
  ConsumerState<AlertHistoryDialog> createState() => _AlertHistoryDialogState();
}

class _AlertHistoryDialogState extends ConsumerState<AlertHistoryDialog> {
  AlertType? _filterType;
  String? _filterDevice;

  @override
  Widget build(BuildContext context) {
    final alertState = ref.watch(alertNotificationProvider);
    final history = alertState.alertHistory;

    // Apply filters
    final filteredHistory = history.where((alert) {
      if (_filterType != null && alert.type != _filterType) {
        return false;
      }
      if (_filterDevice != null &&
          alert.sourceDeviceName != _filterDevice &&
          alert.targetDeviceName != _filterDevice) {
        return false;
      }
      return true;
    }).toList();

    // Get unique device names for filter
    final deviceNames = <String>{};
    for (final alert in history) {
      if (alert.sourceDeviceName != null) {
        deviceNames.add(alert.sourceDeviceName!);
      }
      if (alert.targetDeviceName != null) {
        deviceNames.add(alert.targetDeviceName!);
      }
    }

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.history, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Alert History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Filters
            Row(
              children: [
                // Type filter
                Expanded(
                  child: DropdownButtonFormField<AlertType?>(
                    initialValue: _filterType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...AlertType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getAlertIcon(type), size: 16),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _capitalizeFirst(type.name),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _filterType = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Device filter
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _filterDevice,
                    decoration: const InputDecoration(
                      labelText: 'Device',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Devices'),
                      ),
                      ...deviceNames.map((device) {
                        return DropdownMenuItem(
                          value: device,
                          child: Text(device),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _filterDevice = value);
                    },
                  ),
                ),

                // Clear history button
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Clear History',
                  onPressed: history.isEmpty
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear History'),
                              content: const Text(
                                'Are you sure you want to clear all alert history?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(
                                          alertNotificationProvider.notifier,
                                        )
                                        .clearHistory();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          );
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Alert count
            Text(
              '${filteredHistory.length} alert(s)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),

            // Alert list
            Expanded(
              child: filteredHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No alerts found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredHistory.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final alert = filteredHistory[index];
                        return _AlertHistoryItem(alert: alert);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
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

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

/// Individual alert history item
class _AlertHistoryItem extends StatelessWidget {
  final AlertNotification alert;

  const _AlertHistoryItem({required this.alert});

  Color _getAlertColor() {
    switch (alert.type) {
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
    switch (alert.type) {
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

    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: alertColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_getAlertIcon(), color: alertColor, size: 20),
      ),
      title: Text(
        alert.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            alert.message,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(alert.timestamp),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (alert.protocolType != null)
                _DetailRow(
                  label: 'Protocol',
                  value: alert.protocolType!.toUpperCase(),
                ),
              if (alert.sourceDeviceName != null)
                _DetailRow(
                  label: 'Source Device',
                  value: alert.sourceDeviceName!,
                ),
              if (alert.targetDeviceName != null)
                _DetailRow(
                  label: 'Target Device',
                  value: alert.targetDeviceName!,
                ),
              if (alert.responseTimeMs != null)
                _DetailRow(
                  label: 'Response Time',
                  value: '${alert.responseTimeMs}ms',
                  valueColor: alert.responseTimeMs! > 100
                      ? Colors.orange
                      : Colors.green,
                ),
              _DetailRow(label: 'Alert ID', value: alert.id),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime time) {
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
