import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/canvas/domain/interfaces/device_capability.dart';
import 'package:netsim_mobile/features/canvas/domain/interfaces/device_property.dart';

/// Dedicated Firewall Device - Filters traffic between networks
class FirewallDevice extends NetworkDevice
    implements IPowerable, IFirewallEnabled, IConfigurable {
  String name;
  bool _isPoweredOn;
  List<FirewallInterface> interfaces;
  String _defaultPolicy; // "ALLOW" | "DENY"
  List<FirewallRule> _firewallRules;
  List<String> log;
  bool showIpOnCanvas;

  FirewallDevice({
    required super.deviceId,
    required super.position,
    String? name,
    bool isPoweredOn = true,
    String defaultPolicy = 'DENY',
    List<FirewallInterface>? interfaces,
    List<FirewallRule>? rules,
    this.showIpOnCanvas = false,
  }) : name = name ?? deviceId,
       _isPoweredOn = isPoweredOn,
       _defaultPolicy = defaultPolicy,
       interfaces =
           interfaces ??
           [
             FirewallInterface(interfaceId: 'INSIDE', ipAddress: '192.168.1.1'),
             FirewallInterface(
               interfaceId: 'OUTSIDE',
               ipAddress: '203.0.113.1',
             ),
           ],
       _firewallRules = rules ?? [],
       log = [],
       super(deviceType: 'Firewall');

  @override
  IconData get icon => Icons.security;

  @override
  Color get color => Colors.red;

  @override
  String get displayName => showIpOnCanvas && interfaces.isNotEmpty
      ? interfaces.first.ipAddress
      : name;

  @override
  DeviceStatus get status {
    if (!_isPoweredOn) return DeviceStatus.offline;
    return DeviceStatus.online;
  }

  // IPowerable implementation
  @override
  bool get isPoweredOn => _isPoweredOn;

  @override
  void powerOn() => _isPoweredOn = true;

  @override
  void powerOff() {
    _isPoweredOn = false;
    log.clear();
  }

  @override
  void reboot() {
    powerOff();
    Future.delayed(const Duration(milliseconds: 500), powerOn);
  }

  // IFirewallEnabled implementation
  @override
  String get defaultPolicy => _defaultPolicy;

  @override
  List<Map<String, dynamic>> get firewallRules =>
      _firewallRules.map((r) => r.toMap()).toList();

  @override
  void addRule(Map<String, dynamic> rule) {
    _firewallRules.add(FirewallRule.fromMap(rule));
  }

  @override
  void removeRule(String ruleId) {
    _firewallRules.removeWhere((r) => r.ruleId == ruleId);
  }

  @override
  void setDefaultPolicy(String policy) {
    _defaultPolicy = policy;
  }

  void editRule(String ruleId, Map<String, dynamic> newConfig) {
    final index = _firewallRules.indexWhere((r) => r.ruleId == ruleId);
    if (index != -1) {
      _firewallRules[index] = FirewallRule.fromMap(newConfig);
    }
  }

  void moveRuleUp(String ruleId) {
    final index = _firewallRules.indexWhere((r) => r.ruleId == ruleId);
    if (index > 0) {
      final rule = _firewallRules.removeAt(index);
      _firewallRules.insert(index - 1, rule);
    }
  }

  void moveRuleDown(String ruleId) {
    final index = _firewallRules.indexWhere((r) => r.ruleId == ruleId);
    if (index < _firewallRules.length - 1) {
      final rule = _firewallRules.removeAt(index);
      _firewallRules.insert(index + 1, rule);
    }
  }

  void enableRule(String ruleId) {
    final rule = _firewallRules.firstWhere((r) => r.ruleId == ruleId);
    rule.enabled = true;
  }

  void disableRule(String ruleId) {
    final rule = _firewallRules.firstWhere((r) => r.ruleId == ruleId);
    rule.enabled = false;
  }

  // IConfigurable implementation
  @override
  Map<String, dynamic> get configuration => {
    'defaultPolicy': _defaultPolicy,
    'rules': firewallRules,
    'interfaces': interfaces.map((i) => i.toMap()).toList(),
  };

  @override
  void updateConfiguration(Map<String, dynamic> config) {
    if (config.containsKey('defaultPolicy')) {
      _defaultPolicy = config['defaultPolicy'];
    }
  }

  @override
  String get capabilityName => 'Firewall';

  @override
  List<DeviceAction> get availableActions => getAvailableActions();

  @override
  List<DeviceCapability> get capabilities => [this];

  @override
  List<DeviceProperty> get properties {
    final List<DeviceProperty> props = [
      BooleanProperty(
        id: 'showIpOnCanvas',
        label: 'Show IP on Canvas',
        value: showIpOnCanvas,
      ),
      StatusProperty(
        id: 'powerState',
        label: 'Power',
        value: _isPoweredOn ? 'ON' : 'OFF',
        color: _isPoweredOn ? Colors.green : Colors.red,
      ),
    ];

    // Add IP addresses for each interface (read-only)
    for (var iface in interfaces) {
      props.add(
        IpAddressProperty(
          id: 'ip_${iface.interfaceId}',
          label: '${iface.interfaceId} IP',
          value: iface.ipAddress,
          isReadOnly: true,
        ),
      );
    }

    props.addAll([
      SelectionProperty(
        id: 'defaultPolicy',
        label: 'Default Policy',
        value: _defaultPolicy,
        options: ['ALLOW', 'DENY'],
      ),
      IntegerProperty(
        id: 'ruleCount',
        label: 'Active Rules',
        value: _firewallRules.where((r) => r.enabled).length,
        isReadOnly: true,
      ),
      IntegerProperty(
        id: 'totalRules',
        label: 'Total Rules',
        value: _firewallRules.length,
        isReadOnly: true,
      ),
    ]);

    return props;
  }

  @override
  List<DeviceAction> getAvailableActions() {
    return [
      DeviceAction(
        id: 'power_toggle',
        label: _isPoweredOn ? 'Power Off' : 'Power On',
        icon: Icons.power_settings_new,
        onExecute: _isPoweredOn ? powerOff : powerOn,
      ),
      DeviceAction(
        id: 'configure_rules',
        label: 'Configure Rules',
        icon: Icons.rule,
        onExecute: () {},
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'view_log',
        label: 'View Log',
        icon: Icons.description,
        onExecute: () {},
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'toggle_policy',
        label: 'Toggle Default Policy',
        icon: Icons.swap_vert,
        onExecute: () =>
            setDefaultPolicy(_defaultPolicy == 'ALLOW' ? 'DENY' : 'ALLOW'),
        isEnabled: _isPoweredOn,
      ),
    ];
  }
}

/// Firewall Interface
class FirewallInterface {
  final String interfaceId;
  String ipAddress;
  String status;

  FirewallInterface({
    required this.interfaceId,
    required this.ipAddress,
    this.status = 'UP',
  });

  Map<String, dynamic> toMap() => {
    'interfaceId': interfaceId,
    'ipAddress': ipAddress,
    'status': status,
  };
}

/// Firewall Rule
class FirewallRule {
  String ruleId;
  String name;
  String sourceIp;
  String destIp;
  int? destPort;
  String protocol; // "TCP" | "UDP" | "ICMP" | "ANY"
  String action; // "ALLOW" | "DENY"
  bool enabled;

  FirewallRule({
    required this.ruleId,
    required this.name,
    required this.sourceIp,
    required this.destIp,
    this.destPort,
    required this.protocol,
    required this.action,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() => {
    'ruleId': ruleId,
    'name': name,
    'sourceIp': sourceIp,
    'destIp': destIp,
    'destPort': destPort,
    'protocol': protocol,
    'action': action,
    'enabled': enabled,
  };

  factory FirewallRule.fromMap(Map<String, dynamic> map) {
    return FirewallRule(
      ruleId: map['ruleId'],
      name: map['name'],
      sourceIp: map['sourceIp'],
      destIp: map['destIp'],
      destPort: map['destPort'],
      protocol: map['protocol'],
      action: map['action'],
      enabled: map['enabled'] ?? true,
    );
  }
}
