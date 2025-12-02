/// Statistics for packet activity on a specific device
class DevicePacketStats {
  final String deviceId;

  // ICMP Statistics
  int icmpEchoRequestSent = 0;
  int icmpEchoReplySent = 0;
  int icmpEchoRequestReceived = 0;
  int icmpEchoReplyReceived = 0;
  final List<Duration> icmpResponseTimes = [];

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
  }

  @override
  String toString() {
    return 'DevicePacketStats($deviceId: '
        'ICMP Sent=$icmpEchoRequestSent, '
        'ICMP Received=$icmpEchoReplyReceived, '
        'Avg Response=${averageResponseTime.toStringAsFixed(1)}ms)';
  }
}
