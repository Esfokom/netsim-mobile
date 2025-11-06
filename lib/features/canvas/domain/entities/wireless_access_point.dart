import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/canvas/domain/interfaces/device_capability.dart';
import 'package:netsim_mobile/features/canvas/domain/interfaces/device_property.dart';

/// Wireless Access Point - Bridges wired LAN to wireless (Wi-Fi) LAN
class WirelessAccessPoint extends NetworkDevice
    implements
        IPowerable,
        IWirelessEnabled,
        INetworkConfigurable,
        IConfigurable {
  String name;
  bool _isPoweredOn;
  String uplinkLinkState;

  // IP Config
  String ipConfigMode;
  String? staticIpAddress;
  String? currentIpAddress;

  // Wireless Radio
  bool _radioEnabled;
  String _channel; // "Auto" | "1" | "6" | "11"

  // SSID Config
  String _ssid;
  bool _broadcastSsid;
  String _securityMode; // "OPEN" | "WPA2"
  String? _wpaPassword;

  // Connected clients
  List<WirelessClient> connectedClients;
  bool showIpOnCanvas;

  WirelessAccessPoint({
    required super.deviceId,
    required super.position,
    String? name,
    bool isPoweredOn = true,
    this.uplinkLinkState = 'DOWN',
    this.ipConfigMode = 'DHCP',
    bool radioEnabled = true,
    String channel = 'Auto',
    String ssid = 'My-Network',
    bool broadcastSsid = true,
    String securityMode = 'WPA2',
    String? wpaPassword,
    this.showIpOnCanvas = false,
  }) : name = name ?? deviceId,
       _isPoweredOn = isPoweredOn,
       _radioEnabled = radioEnabled,
       _channel = channel,
       _ssid = ssid,
       _broadcastSsid = broadcastSsid,
       _securityMode = securityMode,
       _wpaPassword = wpaPassword ?? 'password123',
       connectedClients = [],
       super(deviceType: 'WAP');

  @override
  IconData get icon => Icons.wifi;

  @override
  Color get color => Colors.cyan;

  @override
  String get displayName =>
      showIpOnCanvas && currentIpAddress != null ? currentIpAddress! : name;

  @override
  DeviceStatus get status {
    if (!_isPoweredOn) return DeviceStatus.offline;
    if (uplinkLinkState == 'DOWN') return DeviceStatus.warning;
    if (!_radioEnabled) return DeviceStatus.warning;
    return DeviceStatus.online;
  }

  // IPowerable implementation
  @override
  bool get isPoweredOn => _isPoweredOn;

  @override
  void powerOn() {
    _isPoweredOn = true;
  }

  @override
  void powerOff() {
    _isPoweredOn = false;
    connectedClients.clear();
  }

  @override
  void reboot() {
    connectedClients.clear();
    powerOff();
    Future.delayed(const Duration(milliseconds: 500), powerOn);
  }

  // IWirelessEnabled implementation
  @override
  String get ssid => _ssid;

  @override
  bool get radioEnabled => _radioEnabled;

  @override
  String get securityMode => _securityMode;

  @override
  void setSsid(String newSsid) {
    _ssid = newSsid;
  }

  @override
  void setSecurityMode(String mode, String? password) {
    _securityMode = mode;
    if (mode == 'WPA2' && password != null) {
      _wpaPassword = password;
    }
  }

  @override
  void enableRadio() {
    _radioEnabled = true;
  }

  @override
  void disableRadio() {
    _radioEnabled = false;
    connectedClients.clear();
  }

  // INetworkConfigurable implementation
  @override
  String? get ipAddress => currentIpAddress;

  @override
  String? get subnetMask => null; // Simplified for WAP

  @override
  String? get defaultGateway => null; // Simplified for WAP

  @override
  void setStaticIp(String ip, String subnet, String gateway) {
    ipConfigMode = 'STATIC';
    staticIpAddress = ip;
    currentIpAddress = ip;
  }

  @override
  void enableDhcp() {
    ipConfigMode = 'DHCP';
    staticIpAddress = null;
  }

  // IConfigurable implementation
  @override
  Map<String, dynamic> get configuration => {
    'ssid': _ssid,
    'broadcastSsid': _broadcastSsid,
    'securityMode': _securityMode,
    'channel': _channel,
    'radioEnabled': _radioEnabled,
    'ipConfigMode': ipConfigMode,
  };

  @override
  void updateConfiguration(Map<String, dynamic> config) {
    if (config.containsKey('ssid')) _ssid = config['ssid'];
    if (config.containsKey('broadcastSsid')) {
      _broadcastSsid = config['broadcastSsid'];
    }
    if (config.containsKey('channel')) _channel = config['channel'];
  }

  @override
  String get capabilityName => 'Wireless Access Point';

  @override
  List<DeviceAction> get availableActions => getAvailableActions();

  @override
  List<DeviceCapability> get capabilities => [this];

  @override
  List<DeviceProperty> get properties => [
    StringProperty(id: 'name', label: 'Device Name', value: name),
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
    StatusProperty(
      id: 'uplinkState',
      label: 'Uplink',
      value: uplinkLinkState,
      color: uplinkLinkState == 'UP' ? Colors.green : Colors.orange,
    ),
    IpAddressProperty(
      id: 'ipAddress',
      label: 'IP Address',
      value: currentIpAddress ?? 'Not assigned',
      isReadOnly: true,
    ),
    BooleanProperty(
      id: 'radioEnabled',
      label: 'Radio Enabled',
      value: _radioEnabled,
    ),
    StringProperty(id: 'ssid', label: 'SSID', value: _ssid),
    BooleanProperty(
      id: 'broadcastSsid',
      label: 'Broadcast SSID',
      value: _broadcastSsid,
    ),
    SelectionProperty(
      id: 'securityMode',
      label: 'Security',
      value: _securityMode,
      options: ['OPEN', 'WPA2'],
    ),
    if (_securityMode == 'WPA2')
      StringProperty(
        id: 'wpaPassword',
        label: 'WPA Password',
        value: _wpaPassword ?? '',
        isReadOnly: true,
      ),
    SelectionProperty(
      id: 'channel',
      label: 'Channel',
      value: _channel,
      options: ['Auto', '1', '6', '11'],
    ),
    IntegerProperty(
      id: 'connectedClients',
      label: 'Connected Clients',
      value: connectedClients.length,
      isReadOnly: true,
    ),
  ];

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
        id: 'radio_toggle',
        label: _radioEnabled ? 'Disable Radio' : 'Enable Radio',
        icon: _radioEnabled ? Icons.wifi_off : Icons.wifi,
        onExecute: _radioEnabled ? disableRadio : enableRadio,
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'configure',
        label: 'Configure Wireless',
        icon: Icons.settings,
        onExecute: () {},
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'view_clients',
        label: 'View Clients',
        icon: Icons.people,
        onExecute: () {},
        isEnabled: _isPoweredOn && _radioEnabled,
      ),
    ];
  }

  void setChannel(String channel) {
    _channel = channel;
  }

  void setBroadcastSsid(bool broadcast) {
    _broadcastSsid = broadcast;
  }

  void kickClient(String macAddress) {
    connectedClients.removeWhere((c) => c.macAddress == macAddress);
  }

  void addClient(String macAddress, int signalStrength) {
    if (!connectedClients.any((c) => c.macAddress == macAddress)) {
      connectedClients.add(
        WirelessClient(macAddress: macAddress, signalStrength: signalStrength),
      );
    }
  }
}

/// Wireless Client
class WirelessClient {
  final String macAddress;
  int signalStrength; // in dBm (e.g., -50)

  WirelessClient({required this.macAddress, required this.signalStrength});
}
