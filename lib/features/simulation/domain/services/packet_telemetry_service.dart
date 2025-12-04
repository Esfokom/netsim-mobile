import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart'
    show DeviceType;
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/router_device.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/packet.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/packet_telemetry.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/device_packet_stats.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/ping_session.dart';
import 'package:netsim_mobile/features/simulation/domain/services/simulation_engine.dart';

/// Service to track packet events and compute statistics
class PacketTelemetryService {
  final Ref? _ref;
  StreamSubscription<PacketEvent>? _packetSubscription;

  // Storage
  final Map<String, PacketTelemetry> _packetHistory = {};
  final Map<String, DevicePacketStats> _deviceStats = {};

  // Ping session tracking (key: "sourceIp:destIp", value: session)
  final Map<String, PingSession> _activePingSessions = {};
  // Completed ping sessions per device (key: deviceId, value: list of sessions)
  final Map<String, List<PingSession>> _completedPingSessions = {};
  static const int maxSessionsPerDevice = 50; // Limit memory usage

  PacketTelemetryService([this._ref]);

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
    _activePingSessions.clear();
    _completedPingSessions.clear();
  }

  /// Dispose and cleanup
  void dispose() {
    _packetSubscription?.cancel();
    _packetSubscription = null;
    _isInitialized = false;
    reset();
  }

  // ==================== Ping Session Query Methods ====================

  /// Get all completed ping sessions for a device
  List<PingSession> getCompletedPingSessions(String deviceId) {
    return _completedPingSessions[deviceId] ?? [];
  }

  /// Get the active ping session for a source/dest IP pair
  PingSession? getActivePingSession(String sourceIp, String destIp) {
    final key = '$sourceIp:$destIp';
    return _activePingSessions[key];
  }

  /// Get all active ping sessions
  List<PingSession> get allActivePingSessions =>
      _activePingSessions.values.toList();

  /// Get all completed ping sessions (for debugging)
  Map<String, List<PingSession>> get allCompletedPingSessions =>
      Map.unmodifiable(_completedPingSessions);

  /// Get all completed ping sessions across all devices as a flat list
  List<PingSession> getAllCompletedSessionsFlat() {
    final allSessions = <PingSession>[];
    for (final sessions in _completedPingSessions.values) {
      allSessions.addAll(sessions);
    }
    // Sort by start time descending (most recent first)
    allSessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return allSessions;
  }

  /// Find the latest completed ping session matching a source/destination IP pair
  /// Returns null if no matching session is found
  PingSession? findLatestSessionByIps(String sourceIp, String destIp) {
    final allSessions = getAllCompletedSessionsFlat();

    for (final session in allSessions) {
      if (session.sourceIp == sourceIp && session.targetIp == destIp) {
        appLogger.d(
          '[PacketTelemetry] Found latest session for $sourceIp -> $destIp: '
          '${session.id} (status: ${session.status.displayName})',
        );
        return session;
      }
    }

    appLogger.d(
      '[PacketTelemetry] No completed session found for $sourceIp -> $destIp',
    );
    return null;
  }

  /// Find all completed ping sessions matching a source/destination IP pair
  List<PingSession> findSessionsByIps(String sourceIp, String destIp) {
    final allSessions = getAllCompletedSessionsFlat();

    return allSessions.where((session) {
      return session.sourceIp == sourceIp && session.targetIp == destIp;
    }).toList();
  }

  // ==================== Query Methods ====================

  /// Get statistics for a specific device
  DevicePacketStats getDeviceStats(String deviceId) {
    return _deviceStats.putIfAbsent(
      deviceId,
      () => DevicePacketStats(deviceId: deviceId),
    );
  }

  /// Set ping timeout threshold for a specific device
  void setPingTimeout(String deviceId, Duration timeout) {
    final stats = getDeviceStats(deviceId);
    stats.pingTimeout = timeout;
    appLogger.i(
      '[PacketTelemetry] Set ping timeout for device $deviceId: ${timeout.inMilliseconds}ms',
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

  /// Register ping session start (called when ping() is initiated, before ARP/ICMP)
  /// This tracks the full ping time including ARP resolution
  ///
  /// [sourceDeviceId] - The device initiating the ping
  /// [sourceIp] - The source IP address
  /// [destIp] - The destination IP address
  /// [timeoutMs] - Optional timeout in milliseconds (uses device's pingTimeoutMs)
  void registerPingSessionStart(
    String sourceDeviceId,
    String sourceIp,
    String destIp, {
    int? timeoutMs,
  }) {
    final stats = getDeviceStats(sourceDeviceId);
    final now = DateTime.now();

    // Sync device's ping timeout with telemetry stats if provided
    if (timeoutMs != null) {
      stats.pingTimeout = Duration(milliseconds: timeoutMs);
      appLogger.d(
        '[PacketTelemetry] Synced ping timeout for $sourceDeviceId: ${timeoutMs}ms',
      );
    }

    // Track last ping time for this device (full session start)
    stats.lastPingTime = now;
    stats.lastPingResponseTime = null; // Reset response time
    stats.lastPingTimedOut = false; // Reset timeout flag

    // Register pending request with session start time
    final key = '$sourceIp:$destIp';
    _pendingIcmpRequests[key] = now;

    // Create a new PingSession to track all events
    final sourceDeviceName = _getDeviceName(sourceDeviceId);
    final sessionId = '${sourceDeviceId}_${now.millisecondsSinceEpoch}';

    final session = PingSession(
      id: sessionId,
      sourceDeviceId: sourceDeviceId,
      sourceDeviceName: sourceDeviceName,
      sourceIp: sourceIp,
      targetIp: destIp,
      startTime: now,
      status: PingSessionStatus.inProgress,
      events: [],
    );

    _activePingSessions[key] = session;

    appLogger.d(
      '[PacketTelemetry] Ping session created: $key (device: $sourceDeviceId)',
    );
  }

  /// Get device name from canvas state
  String _getDeviceName(String deviceId) {
    final canvasState = _ref?.read(canvasProvider);
    if (canvasState != null) {
      final device = canvasState.devices
          .where((d) => d.id == deviceId)
          .firstOrNull;
      return device?.name ?? deviceId;
    }
    return deviceId;
  }

  /// Get device name from IP address by searching all network devices
  /// Returns the device name if found, or null if no device has this IP
  String? _getDeviceNameFromIp(String? ipAddress) {
    if (ipAddress == null || ipAddress.isEmpty) return null;

    final canvasState = _ref?.read(canvasProvider);
    if (canvasState == null) return null;

    // Search through all network devices to find one with matching IP
    for (final entry in canvasState.networkDevices.entries) {
      final networkDevice = entry.value;
      String? foundName;

      // Handle EndDevice (List<NetworkInterface>)
      if (networkDevice is EndDevice) {
        for (final iface in networkDevice.interfaces) {
          if (iface.ipAddress == ipAddress) {
            foundName = networkDevice.hostname;
            break;
          }
        }
      }
      // Handle RouterDevice (Map<String, RouterInterface>)
      else if (networkDevice is RouterDevice) {
        for (final iface in networkDevice.interfaces.values) {
          if (iface.ipAddress == ipAddress) {
            foundName = networkDevice.name;
            break;
          }
        }
      }

      if (foundName != null) {
        // Also try to get the canvas device name if available
        final canvasDevice = canvasState.devices
            .where((d) => d.id == entry.key)
            .firstOrNull;
        return canvasDevice?.name ?? foundName;
      }
    }

    return null;
  }

  /// Get device ID from IP address by searching all network devices
  /// Returns the device ID if found, or null if no device has this IP
  String? _getDeviceIdFromIp(String? ipAddress) {
    if (ipAddress == null || ipAddress.isEmpty) return null;

    final canvasState = _ref?.read(canvasProvider);
    if (canvasState == null) return null;

    // Search through all network devices to find one with matching IP
    for (final entry in canvasState.networkDevices.entries) {
      final networkDevice = entry.value;

      // Handle EndDevice (List<NetworkInterface>)
      if (networkDevice is EndDevice) {
        for (final iface in networkDevice.interfaces) {
          if (iface.ipAddress == ipAddress) {
            return entry.key; // Return the device ID
          }
        }
      }
      // Handle RouterDevice (Map<String, RouterInterface>)
      else if (networkDevice is RouterDevice) {
        for (final iface in networkDevice.interfaces.values) {
          if (iface.ipAddress == ipAddress) {
            return entry.key; // Return the device ID
          }
        }
      }
    }

    return null;
  }

  /// Resolve device name, trying deviceId first, then IP address
  /// This ensures we always get a meaningful name when possible
  String _resolveDeviceName(String? deviceId, String? ipAddress) {
    // First try to get name from device ID if it's valid
    if (deviceId != null && deviceId != 'unknown' && deviceId.isNotEmpty) {
      final name = _getDeviceName(deviceId);
      if (name != deviceId) {
        return name; // Found a valid name
      }
    }

    // Try to get name from IP address
    final nameFromIp = _getDeviceNameFromIp(ipAddress);
    if (nameFromIp != null) {
      return nameFromIp;
    }

    // Fallback to deviceId or 'Unknown'
    return deviceId ?? 'Unknown';
  }

  /// Resolve device ID, trying deviceId first, then IP address
  String _resolveDeviceId(String? deviceId, String? ipAddress) {
    // First check if deviceId is valid
    if (deviceId != null && deviceId != 'unknown' && deviceId.isNotEmpty) {
      return deviceId;
    }

    // Try to get ID from IP address
    final idFromIp = _getDeviceIdFromIp(ipAddress);
    if (idFromIp != null) {
      return idFromIp;
    }

    // Fallback
    return deviceId ?? 'unknown';
  }

  /// Add a packet event to the active ping session
  void _addEventToPingSession(
    String sourceIp,
    String destIp,
    PingPacketEvent event,
  ) {
    // Try to find the session by source->dest or dest->source (for replies)
    var key = '$sourceIp:$destIp';
    var session = _activePingSessions[key];

    // For replies, the key is reversed
    if (session == null) {
      key = '$destIp:$sourceIp';
      session = _activePingSessions[key];
    }

    if (session != null) {
      final updatedEvents = [...session.events, event];
      _activePingSessions[key] = session.copyWith(events: updatedEvents);
    }
  }

  /// Complete a ping session with success
  void _completePingSession(
    String sourceIp,
    String destIp,
    Duration responseTime,
    String receiverDeviceId,
  ) {
    final key = '$sourceIp:$destIp';
    final session = _activePingSessions.remove(key);

    if (session != null) {
      final now = DateTime.now();

      // Calculate ARP time vs ICMP time
      Duration? arpTime;
      Duration? icmpTime;

      final arpEvents = session.events.where((e) => e.isArp).toList();
      final icmpEvents = session.events.where((e) => e.isIcmp).toList();

      if (arpEvents.isNotEmpty && icmpEvents.isNotEmpty) {
        // ARP time is from session start to first ICMP event
        final firstIcmp = icmpEvents.first;
        arpTime = firstIcmp.timestamp.difference(session.startTime);
        icmpTime = responseTime - arpTime;
      } else {
        // No ARP, all time is ICMP
        icmpTime = responseTime;
      }

      final completedSession = session.copyWith(
        endTime: now,
        totalResponseTime: responseTime,
        arpTime: arpTime,
        icmpTime: icmpTime,
        status: PingSessionStatus.success,
        targetDeviceId: receiverDeviceId,
        targetDeviceName: _resolveDeviceName(receiverDeviceId, destIp),
      );

      // Store in completed sessions
      _storeCompletedSession(session.sourceDeviceId, completedSession);

      appLogger.d(
        '[PacketTelemetry] Ping completed: ${responseTime.inMilliseconds}ms '
        '(ARP: ${arpTime?.inMilliseconds ?? 0}ms, ICMP: ${icmpTime.inMilliseconds}ms)',
      );
    }
  }

  /// Mark a ping session as timed out
  void _timeoutPingSession(String sourceIp, String destIp) {
    final key = '$sourceIp:$destIp';
    final session = _activePingSessions.remove(key);

    if (session != null) {
      final completedSession = session.copyWith(
        endTime: DateTime.now(),
        status: PingSessionStatus.timeout,
        failureReason: 'Request timed out',
      );

      _storeCompletedSession(session.sourceDeviceId, completedSession);
      appLogger.d('[PacketTelemetry] Ping session timed out');
    }
  }

  /// Store a completed session, managing memory limits
  void _storeCompletedSession(String deviceId, PingSession session) {
    _completedPingSessions.putIfAbsent(deviceId, () => []);
    _completedPingSessions[deviceId]!.insert(0, session); // Most recent first

    // Trim to max sessions
    if (_completedPingSessions[deviceId]!.length > maxSessionsPerDevice) {
      _completedPingSessions[deviceId] = _completedPingSessions[deviceId]!
          .take(maxSessionsPerDevice)
          .toList();
    }
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

    if (sourceId == null) {
      appLogger.w(
        '[PacketTelemetry] Packet sent event has null sourceDeviceId!',
      );
      return;
    }

    appLogger.d(
      '[PacketTelemetry] Tracking packet sent from device: $sourceId',
    );

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

        // Only set last ping time if not already set (by registerPingSessionStart)
        // This preserves the full session start time including ARP
        if (stats.lastPingTime == null ||
            stats.lastPingTime!.isBefore(
              packet.timestamp.subtract(const Duration(seconds: 1)),
            )) {
          stats.lastPingTime = packet.timestamp;
          stats.lastPingResponseTime = null;
          stats.lastPingTimedOut = false;
        }

        appLogger.i(
          '[PacketTelemetry] ICMP Echo Request sent from $sourceId: '
          'Total requests sent: ${stats.icmpEchoRequestSent}',
        );
        // Register pending request for response time tracking if not already registered
        if (packet.sourceIp != null && packet.destIp != null) {
          final key = '${packet.sourceIp}:${packet.destIp}';
          if (!_pendingIcmpRequests.containsKey(key)) {
            _pendingIcmpRequests[key] = packet.timestamp;
            appLogger.d(
              '[PacketTelemetry] Registered pending ICMP request: $key',
            );
          } else {
            appLogger.d(
              '[PacketTelemetry] Pending request already exists for: $key (ping session started earlier)',
            );
          }
        }
        break;
      case PacketType.icmpEchoReply:
        stats.icmpEchoReplySent++;
        appLogger.i(
          '[PacketTelemetry] ICMP Echo Reply sent from $sourceId: '
          'Total replies sent: ${stats.icmpEchoReplySent}',
        );
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

    // Add event to active ping session if this packet is related
    if (packet.sourceIp != null && packet.destIp != null) {
      // Resolve device IDs and names - use IP address as fallback for unknown targets
      final resolvedToDeviceId = _resolveDeviceId(
        event.targetDeviceId,
        packet.destIp,
      );
      final resolvedToDeviceName = _resolveDeviceName(
        event.targetDeviceId,
        packet.destIp,
      );
      final resolvedFromDeviceName = _resolveDeviceName(
        sourceId,
        packet.sourceIp,
      );

      final packetEvent = PingPacketEvent(
        id: packet.id,
        packetType: packet.type,
        fromDeviceId: sourceId,
        fromDeviceName: resolvedFromDeviceName,
        toDeviceId: resolvedToDeviceId,
        toDeviceName: resolvedToDeviceName,
        fromIp: packet.sourceIp,
        toIp: packet.destIp,
        timestamp: packet.timestamp,
        status: PacketEventType.sent,
        statusMessage: 'Packet sent',
      );
      _addEventToPingSession(packet.sourceIp!, packet.destIp!, packetEvent);
    }

    appLogger.d(
      '[PacketTelemetry] Tracked sent: ${packet.type} from $sourceId',
    );
  }

  void _trackPacketDelivered(PacketEvent event) {
    final packet = event.packet;
    final targetId = event.targetDeviceId;

    if (targetId == null) {
      appLogger.w(
        '[PacketTelemetry] Packet delivered event has null targetDeviceId!',
      );
      return;
    }

    appLogger.d(
      '[PacketTelemetry] Tracking packet delivered to device: $targetId',
    );

    // Update telemetry record
    final existingTelemetry = _packetHistory[packet.id];
    if (existingTelemetry != null) {
      _packetHistory[packet.id] = existingTelemetry.copyWith(
        targetDeviceId: targetId,
        receivedTime: DateTime.now(),
        finalStatus: PacketEventType.delivered,
      );
    }

    // Add delivered event to active ping session FIRST (before matching/completing)
    // This ensures the event is recorded before the session is removed
    if (packet.sourceIp != null && packet.destIp != null) {
      final existingTelemetryForDuration = _packetHistory[packet.id];
      Duration? duration;
      if (existingTelemetryForDuration != null) {
        duration = DateTime.now().difference(
          existingTelemetryForDuration.sentTime,
        );
      }

      // Resolve device IDs and names - use IP address as fallback
      final resolvedFromDeviceId = _resolveDeviceId(
        event.sourceDeviceId,
        packet.sourceIp,
      );
      final resolvedFromDeviceName = _resolveDeviceName(
        event.sourceDeviceId,
        packet.sourceIp,
      );
      final resolvedToDeviceName = _resolveDeviceName(targetId, packet.destIp);

      final packetEvent = PingPacketEvent(
        id: '${packet.id}_delivered',
        packetType: packet.type,
        fromDeviceId: resolvedFromDeviceId,
        fromDeviceName: resolvedFromDeviceName,
        toDeviceId: targetId,
        toDeviceName: resolvedToDeviceName,
        fromIp: packet.sourceIp,
        toIp: packet.destIp,
        timestamp: DateTime.now(),
        duration: duration,
        status: PacketEventType.delivered,
        statusMessage: 'Packet delivered',
      );
      _addEventToPingSession(packet.sourceIp!, packet.destIp!, packetEvent);
    }

    // Update device stats
    final stats = getDeviceStats(targetId);
    stats.totalPacketsReceived++;

    switch (packet.type) {
      case PacketType.icmpEchoRequest:
        stats.icmpEchoRequestReceived++;
        appLogger.i(
          '[PacketTelemetry] ICMP Echo Request received by $targetId: '
          'Total requests received: ${stats.icmpEchoRequestReceived}',
        );
        break;
      case PacketType.icmpEchoReply:
        stats.icmpEchoReplyReceived++;
        appLogger.i(
          '[PacketTelemetry] ICMP Echo Reply received by $targetId: '
          'Total replies received: ${stats.icmpEchoReplyReceived}',
        );

        // IMPORTANT: Only match replies at PING-CAPABLE DEVICES (PC/Server/Router),
        // not intermediate forwarding devices (switches)
        // This prevents the reply from being matched multiple times as it traverses the network
        final canvasState = _ref?.read(canvasProvider);

        if (canvasState != null) {
          final canvasDevice = canvasState.devices
              .where((d) => d.id == targetId)
              .firstOrNull;

          // Check if it's a ping-capable device (can initiate pings) using DeviceType enum
          // Switches only forward packets, they don't initiate pings
          final isPingCapableDevice =
              canvasDevice?.type == DeviceType.computer ||
              canvasDevice?.type == DeviceType.server ||
              canvasDevice?.type == DeviceType.router;

          if (isPingCapableDevice) {
            _matchIcmpReply(packet, targetId);
          }
        } else {
          // Fallback: match if we can't determine device type
          _matchIcmpReply(packet, targetId);
        }
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
    if (replyPacket.sourceIp == null || replyPacket.destIp == null) {
      appLogger.d(
        '[PacketTelemetry] Cannot match ICMP reply: missing IP addresses',
      );
      return;
    }

    // Key is reversed for reply: destIp sent request, sourceIp is replying
    final key = '${replyPacket.destIp}:${replyPacket.sourceIp}';

    // DEBUG: Show all pending requests
    appLogger.d(
      '[PacketTelemetry] Looking for key: $key\n'
      'Pending requests: ${_pendingIcmpRequests.keys.toList()}\n'
      'Reply packet: sourceIp=${replyPacket.sourceIp}, destIp=${replyPacket.destIp}',
    );

    final requestTime = _pendingIcmpRequests.remove(key);

    if (requestTime != null) {
      final responseTime = DateTime.now().difference(requestTime);

      // Update device stats for the original sender (receiverId of reply)
      final stats = getDeviceStats(receiverId);
      stats.icmpResponseTimes.add(responseTime);

      // Update last ping response time and CLEAR timeout flag
      stats.lastPingResponseTime = responseTime;
      stats.lastPingTimedOut = false;

      appLogger.i(
        '[PacketTelemetry] Matched ICMP reply for device $receiverId: '
        '${responseTime.inMilliseconds}ms (from ${replyPacket.sourceIp})',
      );

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

      // Complete the ping session
      _completePingSession(
        replyPacket.destIp!, // Original source IP
        replyPacket.sourceIp!, // Original dest IP
        responseTime,
        receiverId,
      );

      appLogger.d(
        '[PacketTelemetry] Matched ICMP reply: ${responseTime.inMilliseconds}ms',
      );
    } else {
      appLogger.w(
        '[PacketTelemetry] ICMP reply received but no matching request found '
        'for key: $key (from ${replyPacket.sourceIp} to ${replyPacket.destIp})',
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

    // Cleanup timed-out pending requests and mark devices with high ping
    final now = DateTime.now();
    final timedOutRequests = <String, DateTime>{};

    _pendingIcmpRequests.removeWhere((key, requestTime) {
      final hasTimedOut = now.difference(requestTime) > requestTimeout;
      if (hasTimedOut) {
        timedOutRequests[key] = requestTime;
        appLogger.w('[PacketTelemetry] Ping request timed out: $key');

        // Also timeout the corresponding ping session
        final parts = key.split(':');
        if (parts.length == 2) {
          _timeoutPingSession(parts[0], parts[1]);
        }
      }
      return hasTimedOut;
    });

    // Mark devices with timed-out last pings
    // IMPORTANT: Only mark as timeout if reply was truly NOT received
    for (final stats in _deviceStats.values) {
      if (stats.lastPingTime != null &&
          stats.lastPingResponseTime == null &&
          !stats.lastPingTimedOut) {
        final timeSincePing = now.difference(stats.lastPingTime!);

        // Only mark as timeout if we've exceeded device's threshold AND
        // the ping is still pending (not matched yet)
        if (timeSincePing >= stats.pingTimeout) {
          // Double-check: If reply was received, lastPingResponseTime should be set
          // This check prevents race conditions where reply comes during cleanup
          if (stats.lastPingResponseTime == null) {
            stats.lastPingTimedOut = true;
            appLogger.w(
              '[PacketTelemetry] Device ${stats.deviceId} last ping timed out '
              '(${timeSincePing.inMilliseconds}ms > ${stats.pingTimeout.inMilliseconds}ms) - no reply received',
            );
          }
        }
      }
    }
  }
}
