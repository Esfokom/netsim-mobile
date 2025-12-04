import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/packet.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/ping_session.dart';
import 'package:netsim_mobile/features/simulation/domain/services/simulation_engine.dart'
    show PacketEventType;
import 'package:netsim_mobile/features/simulation/presentation/providers/packet_telemetry_provider.dart';

/// Screen showing detailed ping event history with visual flow animations
class PingEventsHistoryScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final String deviceName;

  const PingEventsHistoryScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  ConsumerState<PingEventsHistoryScreen> createState() =>
      _PingEventsHistoryScreenState();
}

class _PingEventsHistoryScreenState
    extends ConsumerState<PingEventsHistoryScreen>
    with TickerProviderStateMixin {
  PingSession? _selectedSession;
  late AnimationController _flowAnimationController;
  late Animation<double> _flowAnimation;

  @override
  void initState() {
    super.initState();
    _flowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _flowAnimation = CurvedAnimation(
      parent: _flowAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _flowAnimationController.dispose();
    super.dispose();
  }

  void _selectSession(PingSession session) {
    setState(() {
      _selectedSession = session;
    });
    _flowAnimationController.reset();
    _flowAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(
      devicePingSessionsProvider(widget.deviceId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ping Event History'),
            Text(
              widget.deviceName,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Sessions',
            onPressed: () {
              // Force refresh by invalidating the provider
              ref.invalidate(devicePingSessionsProvider(widget.deviceId));
            },
          ),
          if (_selectedSession != null)
            IconButton(
              icon: const Icon(Icons.replay),
              tooltip: 'Replay Animation',
              onPressed: () {
                _flowAnimationController.reset();
                _flowAnimationController.forward();
              },
            ),
        ],
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return _buildEmptyState();
          }

          // Use responsive layout - Column for mobile
          return Column(
            children: [
              // Session list (horizontal scrollable at top)
              SizedBox(
                height: 100,
                child: _buildHorizontalSessionList(sessions),
              ),
              const Divider(height: 1),
              // Session details (below)
              Expanded(
                child: _selectedSession != null
                    ? _buildSessionDetails(_selectedSession!)
                    : _buildSelectSessionPrompt(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'No Ping History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send pings from this device to see\ndetailed event history here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSessionList(List<PingSession> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
          child: Text(
            'Ping Sessions (${sessions.length})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final isSelected = _selectedSession?.id == session.id;

              return _HorizontalPingSessionCard(
                session: session,
                isSelected: isSelected,
                onTap: () => _selectSession(session),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectSessionPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a Ping Session',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a session on the left to see\nthe detailed packet flow',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetails(PingSession session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Summary Card
          _buildSessionSummary(session),
          const SizedBox(height: 24),

          // Time Breakdown
          if (session.status == PingSessionStatus.success)
            _buildTimeBreakdown(session),

          const SizedBox(height: 24),

          // Packet Flow Timeline
          Text(
            'Packet Flow',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Animated packet flow
          _buildPacketFlowTimeline(session),
        ],
      ),
    );
  }

  Widget _buildSessionSummary(PingSession session) {
    final statusColor = _getStatusColor(session.status);
    final statusIcon = _getStatusIcon(session.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ping to ${session.targetIp}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      session.status.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (session.totalResponseTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${session.totalResponseTime!.inMilliseconds}ms',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildSummaryItem(
                icon: Icons.compare_arrows,
                label: 'Events',
                value: '${session.totalEventCount}',
              ),
              _buildSummaryItem(
                icon: Icons.router,
                label: 'Hops',
                value: '${session.hopCount}',
              ),
              _buildSummaryItem(
                icon: Icons.lan,
                label: 'ARP',
                value: '${session.arpPacketCount}',
              ),
              _buildSummaryItem(
                icon: Icons.network_ping,
                label: 'ICMP',
                value: '${session.icmpPacketCount}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBreakdown(PingSession session) {
    final totalMs = session.totalResponseTime?.inMilliseconds ?? 0;
    final arpMs = session.arpTime?.inMilliseconds ?? 0;
    final icmpMs = session.icmpTime?.inMilliseconds ?? 0;

    final arpPercent = totalMs > 0 ? (arpMs / totalMs) : 0.0;
    final icmpPercent = totalMs > 0 ? (icmpMs / totalMs) : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Breakdown',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // Time bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  if (arpMs > 0)
                    Expanded(
                      flex: (arpPercent * 100).round(),
                      child: Container(
                        color: Colors.orange,
                        alignment: Alignment.center,
                        child: Text(
                          'ARP ${arpMs}ms',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    flex: (icmpPercent * 100).round().clamp(1, 100),
                    child: Container(
                      color: Colors.blue,
                      alignment: Alignment.center,
                      child: Text(
                        'ICMP ${icmpMs}ms',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (session.requiredArp)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ARP: ${arpMs}ms',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flash_on,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ARP Cache Hit',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ICMP: ${icmpMs}ms',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPacketFlowTimeline(PingSession session) {
    if (session.events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No packet events recorded',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _flowAnimation,
      builder: (context, child) {
        return Column(
          children: List.generate(session.events.length, (index) {
            final event = session.events[index];
            final animationProgress = _flowAnimation.value;
            final eventProgress = (index + 1) / session.events.length;
            final isVisible = animationProgress >= (eventProgress - 0.2);
            final opacity = isVisible
                ? ((animationProgress - eventProgress + 0.2) / 0.2).clamp(
                    0.0,
                    1.0,
                  )
                : 0.0;

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: opacity,
              child: _PacketEventCard(
                event: event,
                isFirst: index == 0,
                isLast: index == session.events.length - 1,
                index: index,
              ),
            );
          }),
        );
      },
    );
  }

  Color _getStatusColor(PingSessionStatus status) {
    switch (status) {
      case PingSessionStatus.success:
        return Colors.green;
      case PingSessionStatus.timeout:
        return Colors.red;
      case PingSessionStatus.inProgress:
        return Colors.blue;
      case PingSessionStatus.failed:
      case PingSessionStatus.noRoute:
      case PingSessionStatus.unreachable:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(PingSessionStatus status) {
    switch (status) {
      case PingSessionStatus.success:
        return Icons.check_circle;
      case PingSessionStatus.timeout:
        return Icons.timer_off;
      case PingSessionStatus.inProgress:
        return Icons.pending;
      case PingSessionStatus.failed:
        return Icons.error;
      case PingSessionStatus.noRoute:
        return Icons.alt_route;
      case PingSessionStatus.unreachable:
        return Icons.cloud_off;
    }
  }
}

/// Horizontal card showing a ping session (for mobile horizontal list)
class _HorizontalPingSessionCard extends StatelessWidget {
  final PingSession session;
  final bool isSelected;
  final VoidCallback onTap;

  const _HorizontalPingSessionCard({
    required this.session,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(session.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getStatusIcon(session.status),
                    size: 12,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  if (session.totalResponseTime != null)
                    Text(
                      '${session.totalResponseTime!.inMilliseconds}ms',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  if (session.requiredArp) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'ARP',
                        style: TextStyle(
                          fontSize: 7,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                session.targetIp,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: isSelected
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.inverseSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatTime(session.startTime),
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.inverseSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(PingSessionStatus status) {
    switch (status) {
      case PingSessionStatus.success:
        return Colors.green;
      case PingSessionStatus.timeout:
        return Colors.red;
      case PingSessionStatus.inProgress:
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(PingSessionStatus status) {
    switch (status) {
      case PingSessionStatus.success:
        return Icons.check_circle;
      case PingSessionStatus.timeout:
        return Icons.timer_off;
      case PingSessionStatus.inProgress:
        return Icons.pending;
      default:
        return Icons.error;
    }
  }
}

/// Card showing a single packet event in the timeline
class _PacketEventCard extends StatelessWidget {
  final PingPacketEvent event;
  final bool isFirst;
  final bool isLast;
  final int index;

  const _PacketEventCard({
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final protocolColor = _getProtocolColor(event.packetType);
    final isRequest = event.isRequest;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line with dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: protocolColor.withValues(alpha: 0.3),
                    ),
                  ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: protocolColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: protocolColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isRequest ? Icons.arrow_forward : Icons.arrow_back,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: protocolColor.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),

          // Event content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(
                bottom: isLast ? 0 : 8,
                top: isFirst ? 0 : 8,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: protocolColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: protocolColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.protocolName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: protocolColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: event.status == PacketEventType.delivered
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.statusText,
                          style: TextStyle(
                            fontSize: 10,
                            color: event.status == PacketEventType.delivered
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (event.duration != null)
                        Text(
                          '${event.duration!.inMilliseconds}ms',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.fromDeviceName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (event.fromIp != null)
                              Text(
                                event.fromIp!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: protocolColor,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              event.toDeviceName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (event.toIp != null)
                              Text(
                                event.toIp!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProtocolColor(PacketType type) {
    switch (type) {
      case PacketType.arpRequest:
        return Colors.orange;
      case PacketType.arpReply:
        return Colors.amber;
      case PacketType.icmpEchoRequest:
        return Colors.blue;
      case PacketType.icmpEchoReply:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
