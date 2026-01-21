/// Statistics for packet activity on a specific device
class DevicePacketStats {
  final String deviceId;

  // ICMP Statistics
  int icmpEchoRequestSent = 0;
  int icmpEchoReplySent = 0;
  int icmpEchoRequestReceived = 0;
  int icmpEchoReplyReceived = 0;
  final List<Duration> icmpResponseTimes = [];

  // Last Ping Tracking
  DateTime? lastPingTime; // When the last ping was sent
  Duration? lastPingResponseTime; // Response time for the last ping
  bool lastPingTimedOut = false; // Whether the last ping timed out
  Duration pingTimeout = const Duration(
    seconds: 5,
  ); // Configurable timeout threshold (default 5s)

  // ARP Statistics
  int arpRequestSent = 0;
  int arpReplySent = 0;
  int arpRequestReceived = 0;
  int arpReplyReceived = 0;

  // General Statistics
  int totalPacketsSent = 0;
  int totalPacketsReceived = 0;
  int totalPacketsDropped = 0;
  int totalPacketsForwarded = 0;

  DevicePacketStats({required this.deviceId});

  /// Average response time for ICMP Echo Request/Reply pairs
  double get averageResponseTime {
    if (icmpResponseTimes.isEmpty) return 0.0;
    final totalMs = icmpResponseTimes.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return totalMs / icmpResponseTimes.length;
  }

  /// Success rate for ICMP pings (replies received / requests sent)
  double get icmpSuccessRate {
    if (icmpEchoRequestSent == 0) return 0.0;
    return icmpEchoReplyReceived / icmpEchoRequestSent;
  }

  /// Last recorded ICMP response time
  Duration? get lastResponseTime {
    if (icmpResponseTimes.isEmpty) return null;
    return icmpResponseTimes.last;
  }

  /// Get last ping status (returns actual time or "High Ping" if timed out)
  String get lastPingStatus {
    if (lastPingTime == null) return 'No pings sent';

    if (lastPingTimedOut) {
      return 'High Ping (>${pingTimeout.inMilliseconds}ms)';
    }

    if (lastPingResponseTime != null) {
      return '${lastPingResponseTime!.inMilliseconds}ms';
    }

    // Check if we're still waiting but haven't timed out yet
    final timeSincePing = DateTime.now().difference(lastPingTime!);
    if (timeSincePing < pingTimeout) {
      return 'Waiting... (${timeSincePing.inMilliseconds}ms)';
    }

    return 'Timeout (no response)';
  }

  /// Whether the last ping is still pending (waiting for response)
  bool get isLastPingPending {
    if (lastPingTime == null) return false;
    if (lastPingResponseTime != null) return false;
    if (lastPingTimedOut) return false;

    final timeSincePing = DateTime.now().difference(lastPingTime!);
    return timeSincePing < pingTimeout;
  }

  /// ARP success rate (replies received / requests sent)
  double get arpSuccessRate {
    if (arpRequestSent == 0) return 0.0;
    return arpReplyReceived / arpRequestSent;
  }

  /// Total packets handled by this device
  int get totalPackets {
    return totalPacketsSent + totalPacketsReceived + totalPacketsForwarded;
  }

  /// Reset all statistics
  void reset() {
    icmpEchoRequestSent = 0;
    icmpEchoReplySent = 0;
    icmpEchoRequestReceived = 0;
    icmpEchoReplyReceived = 0;
    icmpResponseTimes.clear();

    arpRequestSent = 0;
    arpReplySent = 0;
    arpRequestReceived = 0;
    arpReplyReceived = 0;

    totalPacketsSent = 0;
    totalPacketsReceived = 0;
    totalPacketsDropped = 0;
    totalPacketsForwarded = 0;

    // Reset last ping tracking
    lastPingTime = null;
    lastPingResponseTime = null;
    lastPingTimedOut = false;
  }

  @override
  String toString() {
    return 'DevicePacketStats($deviceId: '
        'ICMP Sent=$icmpEchoRequestSent, '
        'ICMP Received=$icmpEchoReplyReceived, '
        'Avg Response=${averageResponseTime.toStringAsFixed(1)}ms)';
  }
}
