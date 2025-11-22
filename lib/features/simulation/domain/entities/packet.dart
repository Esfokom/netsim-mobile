import 'package:flutter/foundation.dart';

enum PacketType {
  arpRequest,
  arpReply,
  icmpEchoRequest,
  icmpEchoReply,
  tcp,
  udp,
  unknown,
}

class Packet {
  final String id;
  final String sourceMac;
  final String destMac;
  final String? sourceIp;
  final String? destIp;
  final PacketType type;
  final Map<String, dynamic> payload;
  final int ttl;
  final DateTime timestamp;

  Packet({
    String? id,
    required this.sourceMac,
    required this.destMac,
    this.sourceIp,
    this.destIp,
    required this.type,
    this.payload = const {},
    this.ttl = 64,
    DateTime? timestamp,
  }) : id = id ?? UniqueKey().toString(),
       timestamp = timestamp ?? DateTime.now();

  Packet copyWith({
    String? id,
    String? sourceMac,
    String? destMac,
    String? sourceIp,
    String? destIp,
    PacketType? type,
    Map<String, dynamic>? payload,
    int? ttl,
    DateTime? timestamp,
  }) {
    return Packet(
      id: id ?? this.id,
      sourceMac: sourceMac ?? this.sourceMac,
      destMac: destMac ?? this.destMac,
      sourceIp: sourceIp ?? this.sourceIp,
      destIp: destIp ?? this.destIp,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      ttl: ttl ?? this.ttl,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'Packet($type, Src: $sourceMac ($sourceIp), Dst: $destMac ($destIp))';
  }
}
