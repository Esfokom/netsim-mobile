import 'package:netsim_mobile/features/simulation/domain/entities/packet.dart';
import 'package:netsim_mobile/features/simulation/domain/services/simulation_engine.dart';

/// Represents a single packet event in a ping session flow
class PingPacketEvent {
  final String id;
  final PacketType packetType;
  final String fromDeviceId;
  final String fromDeviceName;
  final String toDeviceId;
  final String toDeviceName;
  final String? fromIp;
  final String? toIp;
  final DateTime timestamp;
  final Duration? duration; // Time taken for this hop
  final PacketEventType status;
  final String? statusMessage;

  PingPacketEvent({
    required this.id,
    required this.packetType,
    required this.fromDeviceId,
    required this.fromDeviceName,
    required this.toDeviceId,
    required this.toDeviceName,
    this.fromIp,
    this.toIp,
    required this.timestamp,
    this.duration,
    required this.status,
    this.statusMessage,
  });

  String get protocolName {
    switch (packetType) {
      case PacketType.arpRequest:
        return 'ARP Request';
      case PacketType.arpReply:
        return 'ARP Reply';
      case PacketType.icmpEchoRequest:
        return 'ICMP Echo Request';
      case PacketType.icmpEchoReply:
        return 'ICMP Echo Reply';
      default:
        return packetType.toString().split('.').last;
    }
  }

  String get statusText {
    switch (status) {
      case PacketEventType.sent:
        return 'Sent';
      case PacketEventType.delivered:
        return 'Delivered';
      case PacketEventType.dropped:
        return 'Dropped';
      case PacketEventType.forwarded:
        return 'Forwarded';
    }
  }

  bool get isArp =>
      packetType == PacketType.arpRequest || packetType == PacketType.arpReply;

  bool get isIcmp =>
      packetType == PacketType.icmpEchoRequest ||
      packetType == PacketType.icmpEchoReply;

  bool get isRequest =>
      packetType == PacketType.arpRequest ||
      packetType == PacketType.icmpEchoRequest;

  bool get isReply =>
      packetType == PacketType.arpReply ||
      packetType == PacketType.icmpEchoReply;
}

/// Represents a complete ping session from initiation to response
class PingSession {
  final String id;
  final String sourceDeviceId;
  final String sourceDeviceName;
  final String? sourceIp;
  final String targetIp;
  final String? targetDeviceId;
  final String? targetDeviceName;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? totalResponseTime;
  final Duration? arpTime; // Time spent on ARP resolution
  final Duration? icmpTime; // Time for ICMP round-trip (after ARP)
  final List<PingPacketEvent> events;
  final PingSessionStatus status;
  final String? failureReason;

  PingSession({
    required this.id,
    required this.sourceDeviceId,
    required this.sourceDeviceName,
    this.sourceIp,
    required this.targetIp,
    this.targetDeviceId,
    this.targetDeviceName,
    required this.startTime,
    this.endTime,
    this.totalResponseTime,
    this.arpTime,
    this.icmpTime,
    this.events = const [],
    required this.status,
    this.failureReason,
  });

  /// Whether this ping required ARP resolution
  bool get requiredArp => events.any((e) => e.isArp);

  /// Count of ARP packets in this session
  int get arpPacketCount => events.where((e) => e.isArp).length;

  /// Count of ICMP packets in this session
  int get icmpPacketCount => events.where((e) => e.isIcmp).length;

  /// Total number of packet events
  int get totalEventCount => events.length;

  /// Get total hops (unique devices traversed)
  int get hopCount {
    final devices = <String>{};
    for (final event in events) {
      devices.add(event.fromDeviceId);
      devices.add(event.toDeviceId);
    }
    return devices.length;
  }

  PingSession copyWith({
    String? id,
    String? sourceDeviceId,
    String? sourceDeviceName,
    String? sourceIp,
    String? targetIp,
    String? targetDeviceId,
    String? targetDeviceName,
    DateTime? startTime,
    DateTime? endTime,
    Duration? totalResponseTime,
    Duration? arpTime,
    Duration? icmpTime,
    List<PingPacketEvent>? events,
    PingSessionStatus? status,
    String? failureReason,
  }) {
    return PingSession(
      id: id ?? this.id,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      sourceDeviceName: sourceDeviceName ?? this.sourceDeviceName,
      sourceIp: sourceIp ?? this.sourceIp,
      targetIp: targetIp ?? this.targetIp,
      targetDeviceId: targetDeviceId ?? this.targetDeviceId,
      targetDeviceName: targetDeviceName ?? this.targetDeviceName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalResponseTime: totalResponseTime ?? this.totalResponseTime,
      arpTime: arpTime ?? this.arpTime,
      icmpTime: icmpTime ?? this.icmpTime,
      events: events ?? this.events,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}

/// Status of a ping session
enum PingSessionStatus {
  inProgress,
  success,
  timeout,
  failed,
  noRoute,
  unreachable,
}

extension PingSessionStatusExtension on PingSessionStatus {
  String get displayName {
    switch (this) {
      case PingSessionStatus.inProgress:
        return 'In Progress';
      case PingSessionStatus.success:
        return 'Success';
      case PingSessionStatus.timeout:
        return 'Timeout';
      case PingSessionStatus.failed:
        return 'Failed';
      case PingSessionStatus.noRoute:
        return 'No Route';
      case PingSessionStatus.unreachable:
        return 'Unreachable';
    }
  }

  bool get isComplete => this != PingSessionStatus.inProgress;
}
