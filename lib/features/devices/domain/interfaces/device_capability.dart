import 'package:flutter/material.dart';

/// Base interface for device capabilities
/// Each capability defines what actions a device can perform
abstract class DeviceCapability {
  String get capabilityName;
  List<DeviceAction> get availableActions;
}

/// Represents an action that can be performed on a device
class DeviceAction {
  final String id;
  final String label;
  final IconData icon;
  final Function() onExecute;
  final bool isEnabled;

  DeviceAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onExecute,
    this.isEnabled = true,
  });
}

/// Power management capability
abstract class IPowerable implements DeviceCapability {
  bool get isPoweredOn;
  void powerOn();
  void powerOff();
  void reboot();
}

/// Network configuration capability
abstract class INetworkConfigurable implements DeviceCapability {
  String? get ipAddress;
  String? get subnetMask;
  String? get defaultGateway;
  void setStaticIp(String ip, String subnet, String gateway);
  void enableDhcp();
}

/// Cable connectivity capability
abstract class IConnectable implements DeviceCapability {
  String get linkState; // "UP" | "DOWN"
  void connectCable(String targetDeviceId, int targetPort);
  void disconnectCable();
}

/// Terminal/CLI capability
abstract class ITerminalAccessible implements DeviceCapability {
  List<String> get availableCommands;
  String runCommand(String command, List<String> args);
}

/// Configuration panel capability
abstract class IConfigurable implements DeviceCapability {
  Map<String, dynamic> get configuration;
  void updateConfiguration(Map<String, dynamic> config);
}

/// Service hosting capability (for servers)
abstract class IServiceHost implements DeviceCapability {
  List<String> get runningServices;
  void startService(String serviceName);
  void stopService(String serviceName);
  void configureService(String serviceName, Map<String, dynamic> config);
}

/// Routing capability (for routers)
abstract class IRoutable implements DeviceCapability {
  List<Map<String, dynamic>> get routingTable;
  void addStaticRoute(String destination, String mask, String gateway);
  void removeStaticRoute(String destination);
}

/// Switching capability (for switches)
abstract class ISwitchable implements DeviceCapability {
  List<Map<String, dynamic>> get macAddressTable;
  void clearMacAddressTable();
  void createVlan(int vlanId, String name);
  void assignPortToVlan(int portId, int vlanId);
}

/// Firewall capability
abstract class IFirewallEnabled implements DeviceCapability {
  String get defaultPolicy; // "ALLOW" | "DENY"
  List<Map<String, dynamic>> get firewallRules;
  void addRule(Map<String, dynamic> rule);
  void removeRule(String ruleId);
  void setDefaultPolicy(String policy);
}

/// Wireless capability (for WAPs)
abstract class IWirelessEnabled implements DeviceCapability {
  String get ssid;
  bool get radioEnabled;
  String get securityMode;
  void setSsid(String newSsid);
  void setSecurityMode(String mode, String? password);
  void enableRadio();
  void disableRadio();
}
