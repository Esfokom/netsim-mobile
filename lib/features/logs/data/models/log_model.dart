import 'dart:convert';

class LogModel {
  final String id;
  final String device;
  final String deviceType;
  final String eventType;
  final String message;
  final String status;
  final DateTime timestamp;
  LogModel({
    required this.id,
    required this.device,
    required this.deviceType,
    required this.eventType,
    required this.message,
    required this.status,
    required this.timestamp,
  });

  LogModel copyWith({
    String? id,
    String? device,
    String? deviceType,
    String? eventType,
    String? message,
    String? status,
    DateTime? timestamp,
  }) {
    return LogModel(
      id: id ?? this.id,
      device: device ?? this.device,
      deviceType: deviceType ?? this.deviceType,
      eventType: eventType ?? this.eventType,
      message: message ?? this.message,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'device': device,
      'deviceType': deviceType,
      'eventType': eventType,
      'message': message,
      'status': status,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    // id may come as '_id' or 'id'
    final idVal = map['_id'] ?? map['id'];
    final String id = idVal is String ? idVal : (idVal?.toString() ?? '');

    final deviceVal = map['device'];
    final String device = deviceVal is String
        ? deviceVal
        : (deviceVal?.toString() ?? '');

    final deviceTypeVal = map['deviceType'] ?? map['device_type'];
    final String deviceType = deviceTypeVal is String
        ? deviceTypeVal
        : (deviceTypeVal?.toString() ?? '');

    final eventTypeVal = map['eventType'] ?? map['event_type'];
    final String eventType = eventTypeVal is String
        ? eventTypeVal
        : (eventTypeVal?.toString() ?? '');

    final messageVal = map['message'];
    final String message = messageVal is String
        ? messageVal
        : (messageVal?.toString() ?? '');

    final statusVal = map['status'];
    final String status = statusVal is String
        ? statusVal
        : (statusVal?.toString() ?? '');

    // timestamp can be ISO string or epoch millis (int)
    DateTime timestamp;
    final tsVal = map['timestamp'] ?? map['time'];
    if (tsVal is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(tsVal);
    } else if (tsVal is String) {
      // try parse ISO or numeric string
      final parsedInt = int.tryParse(tsVal);
      if (parsedInt != null) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(parsedInt);
      } else {
        timestamp = DateTime.tryParse(tsVal) ?? DateTime.now();
      }
    } else {
      timestamp = DateTime.now();
    }

    return LogModel(
      id: id,
      device: device,
      deviceType: deviceType,
      eventType: eventType,
      message: message,
      status: status,
      timestamp: timestamp,
    );
  }

  // Capitalized display helpers
  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String get eventTypeCapitalized => _capitalizeFirst(eventType);

  String get deviceTypeCapitalized => _capitalizeFirst(deviceType);

  String toJson() => json.encode(toMap());

  factory LogModel.fromJson(String source) =>
      LogModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LogModel(id: $id, device: $device, deviceType: $deviceType, eventType: $eventType, message: $message, status: $status, timestamp: $timestamp)';
  }

  @override
  bool operator ==(covariant LogModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.device == device &&
        other.deviceType == deviceType &&
        other.eventType == eventType &&
        other.message == message &&
        other.status == status &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        device.hashCode ^
        deviceType.hashCode ^
        eventType.hashCode ^
        message.hashCode ^
        status.hashCode ^
        timestamp.hashCode;
  }
}
