import 'package:flutter/foundation.dart';

/// Types of alerts
enum AlertType {
  info, // General information
  success, // Positive events
  warning, // Potential issues
  error, // Critical issues
}

/// Alert notification for protocol events and condition checks
@immutable
class AlertNotification {
  final String id;
  final String title;
  final String message;
  final AlertType type;
  final DateTime timestamp;
  final Map<String, dynamic> details;
  final String? sourceDeviceId;
  final String? sourceDeviceName;
  final String? targetDeviceId;
  final String? targetDeviceName;
  final String? protocolType; // ICMP, ARP, etc.
  final int? responseTimeMs; // Response time in milliseconds

  const AlertNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.details = const {},
    this.sourceDeviceId,
    this.sourceDeviceName,
    this.targetDeviceId,
    this.targetDeviceName,
    this.protocolType,
    this.responseTimeMs,
  });

  AlertNotification copyWith({
    String? id,
    String? title,
    String? message,
    AlertType? type,
    DateTime? timestamp,
    Map<String, dynamic>? details,
    String? sourceDeviceId,
    String? sourceDeviceName,
    String? targetDeviceId,
    String? targetDeviceName,
    String? protocolType,
    int? responseTimeMs,
  }) {
    return AlertNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      details: details ?? this.details,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      sourceDeviceName: sourceDeviceName ?? this.sourceDeviceName,
      targetDeviceId: targetDeviceId ?? this.targetDeviceId,
      targetDeviceName: targetDeviceName ?? this.targetDeviceName,
      protocolType: protocolType ?? this.protocolType,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
      if (sourceDeviceId != null) 'sourceDeviceId': sourceDeviceId,
      if (sourceDeviceName != null) 'sourceDeviceName': sourceDeviceName,
      if (targetDeviceId != null) 'targetDeviceId': targetDeviceId,
      if (targetDeviceName != null) 'targetDeviceName': targetDeviceName,
      if (protocolType != null) 'protocolType': protocolType,
      if (responseTimeMs != null) 'responseTimeMs': responseTimeMs,
    };
  }

  factory AlertNotification.fromJson(Map<String, dynamic> json) {
    return AlertNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: AlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlertType.info,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      details: Map<String, dynamic>.from(json['details'] as Map? ?? {}),
      sourceDeviceId: json['sourceDeviceId'] as String?,
      sourceDeviceName: json['sourceDeviceName'] as String?,
      targetDeviceId: json['targetDeviceId'] as String?,
      targetDeviceName: json['targetDeviceName'] as String?,
      protocolType: json['protocolType'] as String?,
      responseTimeMs: json['responseTimeMs'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AlertNotification(id: $id, title: $title, type: $type, timestamp: $timestamp)';
  }
}
