import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/canvas/domain/interfaces/device_capability.dart';
import 'package:netsim_mobile/features/canvas/domain/interfaces/device_property.dart';

/// Server Device - Extends End Device with service hosting capabilities
class ServerDevice extends EndDevice implements IServiceHost {
  Map<String, ServiceConfig> services;

  ServerDevice({
    required super.deviceId,
    required super.position,
    required super.hostname,
    required super.macAddress,
    Map<String, ServiceConfig>? services,
  }) : services = services ?? {},
       super(deviceType: 'Server');

  @override
  IconData get icon => Icons.dns;

  @override
  Color get color => Colors.orange;

  /// Server IP addresses are static and cannot be changed after initialization
  @override
  bool get canEditIpAddress => false;

  // IServiceHost implementation
  @override
  List<String> get runningServices => services.entries
      .where((e) => e.value.isRunning)
      .map((e) => e.key)
      .toList();

  @override
  void startService(String serviceName) {
    if (services.containsKey(serviceName)) {
      services[serviceName]!.isRunning = true;
    }
  }

  @override
  void stopService(String serviceName) {
    if (services.containsKey(serviceName)) {
      services[serviceName]!.isRunning = false;
    }
  }

  @override
  void configureService(String serviceName, Map<String, dynamic> config) {
    if (services.containsKey(serviceName)) {
      services[serviceName]!.configuration = config;
    }
  }

  @override
  List<DeviceProperty> get properties => [
    ...super.properties,
    IntegerProperty(
      id: 'serviceCount',
      label: 'Installed Services',
      value: services.length,
      isReadOnly: true,
    ),
    IntegerProperty(
      id: 'runningServiceCount',
      label: 'Running Services',
      value: runningServices.length,
      isReadOnly: true,
    ),
  ];

  @override
  List<DeviceAction> getAvailableActions() {
    final baseActions = super.getAvailableActions();
    final serviceActions = services.entries.map((e) {
      return DeviceAction(
        id: 'service_${e.key}',
        label: '${e.value.isRunning ? "Stop" : "Start"} ${e.key}',
        icon: e.value.isRunning ? Icons.stop : Icons.play_arrow,
        onExecute: () =>
            e.value.isRunning ? stopService(e.key) : startService(e.key),
        isEnabled: isPoweredOn,
      );
    }).toList();

    return [...baseActions, ...serviceActions];
  }

  void addService(String name, ServiceConfig config) {
    services[name] = config;
  }
}

/// Service Configuration
class ServiceConfig {
  final String name;
  bool isRunning;
  Map<String, dynamic> configuration;

  ServiceConfig({
    required this.name,
    this.isRunning = false,
    this.configuration = const {},
  });
}

/// DHCP Service Configuration
class DhcpServiceConfig extends ServiceConfig {
  String poolStart;
  String poolEnd;
  String defaultGateway;
  String dnsServer;
  int leaseDuration;

  DhcpServiceConfig({
    this.poolStart = '192.168.1.100',
    this.poolEnd = '192.168.1.150',
    this.defaultGateway = '192.168.1.1',
    this.dnsServer = '192.168.1.1',
    this.leaseDuration = 86400,
    super.isRunning = false,
  }) : super(name: 'DHCP', configuration: {});

  @override
  Map<String, dynamic> get configuration => {
    'poolStart': poolStart,
    'poolEnd': poolEnd,
    'defaultGateway': defaultGateway,
    'dnsServer': dnsServer,
    'leaseDuration': leaseDuration,
  };
}

/// DNS Service Configuration
class DnsServiceConfig extends ServiceConfig {
  List<DnsRecord> zoneFile;

  DnsServiceConfig({this.zoneFile = const [], super.isRunning = false})
    : super(name: 'DNS', configuration: {});

  void addRecord(String name, String type, String value) {
    zoneFile.add(DnsRecord(name: name, type: type, value: value));
  }

  void removeRecord(String name) {
    zoneFile.removeWhere((r) => r.name == name);
  }
}

class DnsRecord {
  final String name;
  final String type; // "A", "CNAME", "MX", etc.
  final String value;

  DnsRecord({required this.name, required this.type, required this.value});
}

/// Web Service Configuration
class WebServiceConfig extends ServiceConfig {
  int port;
  String welcomeMessage;

  WebServiceConfig({
    this.port = 80,
    this.welcomeMessage = 'Site is UP!',
    super.isRunning = false,
  }) : super(name: 'WEB', configuration: {});

  @override
  Map<String, dynamic> get configuration => {
    'port': port,
    'welcomeMessage': welcomeMessage,
  };
}
