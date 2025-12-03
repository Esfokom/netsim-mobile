import 'package:netsim_mobile/features/simulation/domain/entities/packet.dart';
import 'package:netsim_mobile/features/simulation/domain/services/simulation_engine.dart';

/// Telemetry data for a single packet's lifecycle
class PacketTelemetry {
  final String packetId;
  final PacketType type;
  final String sourceDeviceId;
  final String? targetDeviceId;
  final String? sourceIp;
  final String? destIp;
  final DateTime sentTime;
  final DateTime? receivedTime;
  final Duration? responseTime;
  final PacketEventType finalStatus;
  final List<String> pathDevices; // Forwarding path
  final String? dropReason;

  PacketTelemetry({
    required this.packetId,
    required this.type,
    required this.sourceDeviceId,
    this.targetDeviceId,
    this.sourceIp,
    this.destIp,
    required this.sentTime,
    this.receivedTime,
    this.responseTime,
    required this.finalStatus,
    this.pathDevices = const [],
    this.dropReason,
  });

  PacketTelemetry copyWith({
    String? packetId,
    PacketType? type,
    String? sourceDeviceId,
    String? targetDeviceId,
    String? sourceIp,
    String? destIp,
    DateTime? sentTime,
    DateTime? receivedTime,
    Duration? responseTime,
    PacketEventType? finalStatus,
    List<String>? pathDevices,
    String? dropReason,
  }) {
    return PacketTelemetry(
      packetId: packetId ?? this.packetId,
      type: type ?? this.type,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      targetDeviceId: targetDeviceId ?? this.targetDeviceId,
      sourceIp: sourceIp ?? this.sourceIp,
      destIp: destIp ?? this.destIp,
      sentTime: sentTime ?? this.sentTime,
      receivedTime: receivedTime ?? this.receivedTime,
      responseTime: responseTime ?? this.responseTime,
      finalStatus: finalStatus ?? this.finalStatus,
      pathDevices: pathDevices ?? this.pathDevices,
      dropReason: dropReason ?? this.dropReason,
    );
  }

  bool get isDelivered => finalStatus == PacketEventType.delivered;
  bool get isDropped => finalStatus == PacketEventType.dropped;
  bool get hasResponse => receivedTime != null;
}
