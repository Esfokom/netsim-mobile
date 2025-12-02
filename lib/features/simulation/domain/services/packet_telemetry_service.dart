import 'dart:async';
import 'package:netsim_mobile/core/utils/app_logger.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/packet.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/packet_telemetry.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/device_packet_stats.dart';
import 'package:netsim_mobile/features/simulation/domain/services/simulation_engine.dart';

/// Service to track packet events and compute statistics
class PacketTelemetryService {
  StreamSubscription<PacketEvent>? _packetSubscription;

  // Storage
  final Map<String, PacketTelemetry> _packetHistory = {};
  final Map<String, DevicePacketStats> _deviceStats = {};

  // ICMP Request/Reply matching
  final Map<String, DateTime> _pendingIcmpRequests =
      {}; // key: "sourceIp:destIp"

  // Configuration
  static const int maxPacketHistory = 1000; // Limit memory usage
  static const Duration requestTimeout = Duration(seconds: 5);

  bool _isInitialized = false;

  /// Initialize the telemetry service by subscribing to packet stream
  void initialize(SimulationEngine engine) {
    if (_isInitialized) {
      appLogger.w('[PacketTelemetry] Already initialized');
      return;
    }

    appLogger.i('[PacketTelemetry] Initializing packet telemetry service');

    _packetSubscription = engine.packetStream.listen(
      _onPacketEvent,
      onError: (error, stackTrace) {
        appLogger.e(
          '[PacketTelemetry] Error in packet stream',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    _isInitialized = true;
  }

  /// Reset all telemetry data
  void reset() {
    appLogger.i('[PacketTelemetry] Resetting telemetry data');
    _packetHistory.clear();
    _deviceStats.clear();
    _pendingIcmpRequests.clear();
  }

  /// Dispose and cleanup
  void dispose() {
    _packetSubscription?.cancel();
    _packetSubscription = null;
    _isInitialized = false;
    reset();
  }

  // ==================== Query Methods ====================

  /// Get statistics for a specific device
  DevicePacketStats getDeviceStats(String deviceId) {
    return _deviceStats.putIfAbsent(
      deviceId,
      () => DevicePacketStats(deviceId: deviceId),
    );
  }

  /// Get packet history with optional filters
  List<PacketTelemetry> getPacketHistory({
    String? deviceId,
    PacketType? type,
    DateTime? after,
  }) {
    var packets = _packetHistory.values;

    if (deviceId != null) {
      packets = packets.where(
        (p) => p.sourceDeviceId == deviceId || p.targetDeviceId == deviceId,
      );
    }

    if (type != null) {
      packets = packets.where((p) => p.type == type);
    }

    if (after != null) {
      packets = packets.where((p) => p.sentTime.isAfter(after));
    }

    return packets.toList()..sort((a, b) => b.sentTime.compareTo(a.sentTime));
  }

  /// Check if a device sent a specific packet type
  bool didDeviceSendPacket(
    String deviceId,
    PacketType type, {
    DateTime? after,
  }) {
    return _packetHistory.values.any((p) {
      if (p.sourceDeviceId != deviceId || p.type != type) return false;
      if (after != null && p.sentTime.isBefore(after)) return false;
      return true;
    });
  }

  /// Check if a device received a specific packet type
  bool didDeviceReceivePacket(
    String deviceId,
    PacketType type, {
    String? fromDeviceId,
    DateTime? after,
  }) {
    return _packetHistory.values.any((p) {
      if (p.targetDeviceId != deviceId || p.type != type) return false;
      if (!p.isDelivered) return false;
      if (fromDeviceId != null && p.sourceDeviceId != fromDeviceId) {
        return false;
      }
      if (after != null && p.sentTime.isBefore(after)) return false;
      return true;
    });
  }

  /// Get response time between two devices for ICMP
  Duration? getResponseTime(String sourceDeviceId, String targetDeviceId) {
    final stats = getDeviceStats(sourceDeviceId);
    if (stats.lastResponseTime != null) {
      return stats.lastResponseTime;
    }

    // Fallback: search packet history
    for (final packet in _packetHistory.values.toList().reversed) {
      if (packet.sourceDeviceId == sourceDeviceId &&
          packet.targetDeviceId == targetDeviceId &&
          packet.type == PacketType.icmpEchoRequest &&
          packet.responseTime != null) {
        return packet.responseTime;
      }
    }

    return null;
  }

  // ==================== Private Methods ====================

  void _onPacketEvent(PacketEvent event) {
    try {
      switch (event.type) {
        case PacketEventType.sent:
          _trackPacketSent(event);
          break;
        case PacketEventType.delivered:
          _trackPacketDelivered(event);
          break;
        case PacketEventType.dropped:
          _trackPacketDropped(event);
          break;
        case PacketEventType.forwarded:
          _trackPacketForwarded(event);
          break;
      }

      // Cleanup old entries if needed
      _cleanupOldEntries();
    } catch (e, stackTrace) {
      appLogger.e(
        '[PacketTelemetry] Error processing packet event',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _trackPacketSent(PacketEvent event) {
    final packet = event.packet;
    final sourceId = event.sourceDeviceId;

    if (sourceId == null) return;

    // Create telemetry record
    final telemetry = PacketTelemetry(
      packetId: packet.id,
      type: packet.type,
      sourceDeviceId: sourceId,
      targetDeviceId: event.targetDeviceId,
      sourceIp: packet.sourceIp,
      destIp: packet.destIp,
      sentTime: packet.timestamp,
      finalStatus: PacketEventType.sent,
    );

    _packetHistory[packet.id] = telemetry;

    // Update device stats
    final stats = getDeviceStats(sourceId);
    stats.totalPacketsSent++;

    switch (packet.type) {
      case PacketType.icmpEchoRequest:
        stats.icmpEchoRequestSent++;
        // Register pending request for response time tracking
        if (packet.sourceIp != null && packet.destIp != null) {
          final key = '${packet.sourceIp}:${packet.destIp}';
          _pendingIcmpRequests[key] = packet.timestamp;
        }
        break;
      case PacketType.icmpEchoReply:
        stats.icmpEchoReplySent++;
        break;
      case PacketType.arpRequest:
        stats.arpRequestSent++;
        break;
      case PacketType.arpReply:
        stats.arpReplySent++;
        break;
      default:
        break;
    }

    appLogger.d(
      '[PacketTelemetry] Tracked sent: ${packet.type} from $sourceId',
    );
  }

  void _trackPacketDelivered(PacketEvent event) {
    final packet = event.packet;
    final targetId = event.targetDeviceId;

    if (targetId == null) return;

    // Update telemetry record
    final existingTelemetry = _packetHistory[packet.id];
    if (existingTelemetry != null) {
      _packetHistory[packet.id] = existingTelemetry.copyWith(
        targetDeviceId: targetId,
        receivedTime: DateTime.now(),
        finalStatus: PacketEventType.delivered,
      );
    }

    // Update device stats
    final stats = getDeviceStats(targetId);
    stats.totalPacketsReceived++;

    switch (packet.type) {
      case PacketType.icmpEchoRequest:
        stats.icmpEchoRequestReceived++;
        break;
      case PacketType.icmpEchoReply:
        stats.icmpEchoReplyReceived++;
        // Match with pending request for response time
        _matchIcmpReply(packet, targetId);
        break;
      case PacketType.arpRequest:
        stats.arpRequestReceived++;
        break;
      case PacketType.arpReply:
        stats.arpReplyReceived++;
        break;
      default:
        break;
    }

    appLogger.d(
      '[PacketTelemetry] Tracked delivered: ${packet.type} to $targetId',
    );
  }

  void _trackPacketDropped(PacketEvent event) {
    final packet = event.packet;
    final sourceId = event.sourceDeviceId ?? 'unknown';

    // Update telemetry record
    final existingTelemetry = _packetHistory[packet.id];
    if (existingTelemetry != null) {
      _packetHistory[packet.id] = existingTelemetry.copyWith(
        finalStatus: PacketEventType.dropped,
        dropReason: event.reason,
      );
    }

    // Update device stats
    final stats = getDeviceStats(sourceId);
    stats.totalPacketsDropped++;

    appLogger.d(
      '[PacketTelemetry] Tracked dropped: ${packet.type} at $sourceId',
    );
  }

  void _trackPacketForwarded(PacketEvent event) {
    final forwarderId = event.sourceDeviceId;
    if (forwarderId == null) return;

    final stats = getDeviceStats(forwarderId);
    stats.totalPacketsForwarded++;

    appLogger.d('[PacketTelemetry] Tracked forwarded by $forwarderId');
  }

  void _matchIcmpReply(Packet replyPacket, String receiverId) {
    // Match reply with pending request
    if (replyPacket.sourceIp == null || replyPacket.destIp == null) return;

    // Key is reversed for reply: destIp sent request, sourceIp is replying
    final key = '${replyPacket.destIp}:${replyPacket.sourceIp}';
    final requestTime = _pendingIcmpRequests.remove(key);

    if (requestTime != null) {
      final responseTime = DateTime.now().difference(requestTime);

      // Update device stats for the original sender (receiverId of reply)
      final stats = getDeviceStats(receiverId);
      stats.icmpResponseTimes.add(responseTime);

      // Find and update the original request telemetry
      for (final telemetry in _packetHistory.values) {
        if (telemetry.type == PacketType.icmpEchoRequest &&
            telemetry.sourceIp == replyPacket.destIp &&
            telemetry.destIp == replyPacket.sourceIp &&
            telemetry.sentTime == requestTime) {
          _packetHistory[telemetry.packetId] = telemetry.copyWith(
            responseTime: responseTime,
          );
          break;
        }
      }

      appLogger.d(
        '[PacketTelemetry] Matched ICMP reply: ${responseTime.inMilliseconds}ms',
      );
    }
  }

  void _cleanupOldEntries() {
    if (_packetHistory.length > maxPacketHistory) {
      // Remove oldest entries
      final sortedKeys = _packetHistory.keys.toList()
        ..sort((a, b) {
          final timeA = _packetHistory[a]!.sentTime;
          final timeB = _packetHistory[b]!.sentTime;
          return timeA.compareTo(timeB);
        });

      final toRemove = sortedKeys.take(
        _packetHistory.length - maxPacketHistory,
      );
      for (final key in toRemove) {
        _packetHistory.remove(key);
      }

      appLogger.d(
        '[PacketTelemetry] Cleaned up ${toRemove.length} old entries',
      );
    }

    // Cleanup timed-out pending requests
    final now = DateTime.now();
    _pendingIcmpRequests.removeWhere((key, requestTime) {
      return now.difference(requestTime) > requestTimeout;
    });
  }
}
