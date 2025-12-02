import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/simulation/presentation/providers/packet_telemetry_provider.dart';

/// Bottom sheet for viewing ping statistics for a selected device
class PingStatsBottomSheet extends ConsumerStatefulWidget {
  const PingStatsBottomSheet({super.key});

  @override
  ConsumerState<PingStatsBottomSheet> createState() =>
      _PingStatsBottomSheetState();
}

class _PingStatsBottomSheetState extends ConsumerState<PingStatsBottomSheet> {
  String? selectedDeviceId;

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider);
    final devices = canvasState.devices;

    return Column(
      children: [
        // Device selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildDeviceSelector(devices),
        ),

        // Statistics display or empty state (scrollable)
        Expanded(
          child: SingleChildScrollView(
            child: selectedDeviceId != null
                ? _buildStatisticsDisplay(selectedDeviceId!)
                : _buildEmptyState(),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceSelector(List<CanvasDevice> devices) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: selectedDeviceId != null
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _showDeviceSelectionDialog(devices),
        child: Row(
          children: [
            Icon(
              Icons.computer,
              color: selectedDeviceId != null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Device',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedDeviceId != null
                        ? devices
                              .firstWhere((d) => d.id == selectedDeviceId)
                              .name
                        : 'Tap to select a device',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selectedDeviceId != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontStyle: selectedDeviceId != null
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsDisplay(String deviceId) {
    final stats = ref.watch(devicePacketStatsProvider(deviceId));
    final hasActivity =
        stats.icmpEchoRequestSent > 0 || stats.icmpEchoReplyReceived > 0;

    if (!hasActivity) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No ping activity yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a ping from this device to see statistics',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.analytics,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Packet Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Statistics Grid
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.upload_outlined,
                  label: 'Sent',
                  value: '${stats.icmpEchoRequestSent}',
                  subtitle: 'ICMP Requests',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.download_outlined,
                  label: 'Received',
                  value: '${stats.icmpEchoReplyReceived}',
                  subtitle: 'ICMP Replies',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Average Time',
                  value: stats.averageResponseTime > 0
                      ? '${stats.averageResponseTime.toStringAsFixed(1)}ms'
                      : 'N/A',
                  subtitle: 'Response time',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.speed,
                  label: 'Last Time',
                  value: stats.lastResponseTime != null
                      ? '${stats.lastResponseTime!.inMilliseconds}ms'
                      : 'N/A',
                  subtitle: 'Most recent',
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          // Success Rate
          if (stats.icmpEchoRequestSent > 0) ...[
            const SizedBox(height: 20),
            _SuccessRateDisplay(
              successRate: stats.icmpSuccessRate,
              sent: stats.icmpEchoRequestSent,
              received: stats.icmpEchoReplyReceived,
            ),
          ],

          // ARP Statistics (if available)
          if (stats.arpRequestSent > 0 || stats.arpReplyReceived > 0) ...[
            const SizedBox(height: 20),
            Divider(color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'ARP Statistics',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.send_outlined,
                    label: 'ARP Sent',
                    value: '${stats.arpRequestSent}',
                    subtitle: 'Requests',
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.call_received_outlined,
                    label: 'ARP Received',
                    value: '${stats.arpReplyReceived}',
                    subtitle: 'Replies',
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(
            Icons.devices_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Device Selected',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a device to view its ping statistics',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showDeviceSelectionDialog(List<CanvasDevice> devices) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Device'),
        content: SizedBox(
          width: double.maxFinite,
          child: devices.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No devices available',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isSelected = device.id == selectedDeviceId;
                    return ListTile(
                      leading: Icon(
                        device.type.icon,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(device.name),
                      subtitle: Text(device.type.displayName),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      selected: isSelected,
                      onTap: () {
                        setState(() => selectedDeviceId = device.id);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          if (selectedDeviceId != null)
            TextButton.icon(
              onPressed: () {
                setState(() => selectedDeviceId = null);
                Navigator.of(ctx).pop();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Individual statistic card
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Success rate display with progress bar
class _SuccessRateDisplay extends StatelessWidget {
  final double successRate;
  final int sent;
  final int received;

  const _SuccessRateDisplay({
    required this.successRate,
    required this.sent,
    required this.received,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (successRate * 100).toStringAsFixed(0);
    final color = successRate >= 0.8
        ? Colors.green
        : successRate >= 0.5
        ? Colors.orange
        : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  'Success Rate',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Text(
              '$percentage% ($received/$sent)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: successRate,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
