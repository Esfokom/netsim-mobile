import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_interface.dart';
import 'package:netsim_mobile/features/devices/domain/entities/routing_table.dart';
import 'package:netsim_mobile/features/devices/domain/entities/arp_cache.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_capability.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_property.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/packet.dart';
import 'package:netsim_mobile/features/simulation/domain/services/simulation_engine.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';

/// End Device (PC/Workstation) - Player's main interaction point
class EndDevice extends NetworkDevice
    implements
        IPowerable,
        INetworkConfigurable,
        IConnectable,
        ITerminalAccessible {
  // Properties
  String hostname;
  final String macAddress;
  bool _isPoweredOn;
  String _linkState;

  // IP Configuration
  String ipConfigMode; // "STATIC" | "DHCP"
  String? staticIpAddress;
  String? staticSubnetMask;
  String? staticDefaultGateway;
  String? staticDnsServer1;
  String? staticDnsServer2;

  String? dhcpIpAddress;
  String? dhcpSubnetMask;
  String? dhcpDefaultGateway;
  String? dhcpDnsServer1;
  DateTime? dhcpLeaseObtained;
  DateTime? dhcpLeaseExpires;

  // Current active configuration (legacy, kept for backward compatibility)
  String? currentIpAddress;
  String? currentSubnetMask;
  String? currentDefaultGateway;
  List<String> currentDnsServers;
  List<Map<String, String>> arpCache; // Legacy format

  // NEW: Network infrastructure (PHASE 1 implementation)
  List<NetworkInterface> interfaces;
  RoutingTable routingTable;
  ArpCache arpCacheStructured;

  // Tools and state
  List<String> installedTools;
  String statusMessage;

  // Display preference
  bool showIpOnCanvas;

  // Pending pings waiting for ARP resolution
  final Map<String, int> _pendingPings = {}; // targetIp -> sequence number

  EndDevice({
    required super.deviceId,
    required super.position,
    required this.hostname,
    required this.macAddress,
    super.deviceType = 'PC',
    this.ipConfigMode = 'DHCP',
    bool isPoweredOn = true,
    String linkState = 'DOWN',
    this.installedTools = const ['ipconfig', 'ping', 'nslookup', 'traceroute'],
    this.statusMessage = 'Not connected',
    List<String>? currentDnsServers,
    List<Map<String, String>>? arpCache,
    this.showIpOnCanvas = false,
    List<NetworkInterface>? interfaces,
    RoutingTable? routingTable,
    ArpCache? arpCacheStructured,
  }) : _isPoweredOn = isPoweredOn,
       _linkState = linkState,
       currentDnsServers = currentDnsServers ?? [],
       arpCache = arpCache ?? [],
       interfaces = interfaces ?? [],
       routingTable = routingTable ?? RoutingTable(),
       arpCacheStructured = arpCacheStructured ?? ArpCache(),
       super() {
    // Initialize default interface if none provided
    if (this.interfaces.isEmpty) {
      this.interfaces.add(
        NetworkInterface(
          name: 'eth0',
          macAddress: macAddress,
          ipAddress: currentIpAddress,
          subnetMask: currentSubnetMask,
          defaultGateway: currentDefaultGateway,
          status: linkState == 'UP' ? InterfaceStatus.up : InterfaceStatus.down,
        ),
      );
    }
  }

  @override
  IconData get icon => Icons.computer;

  @override
  Color get color => Colors.purple;

  @override
  String get displayName =>
      showIpOnCanvas && currentIpAddress != null ? currentIpAddress! : hostname;

  @override
  DeviceStatus get status {
    // Simple two-state model: online when powered on, offline when powered off
    return _isPoweredOn ? DeviceStatus.online : DeviceStatus.offline;
  }

  // NEW: Network infrastructure helper methods

  /// Get the default network interface (usually eth0)
  NetworkInterface get defaultInterface {
    if (interfaces.isEmpty) {
      // Create default interface if none exists
      final iface = NetworkInterface(
        name: 'eth0',
        macAddress: macAddress,
        ipAddress: currentIpAddress,
        subnetMask: currentSubnetMask,
        defaultGateway: currentDefaultGateway,
        status: _linkState == 'UP' ? InterfaceStatus.up : InterfaceStatus.down,
      );
      interfaces.add(iface);
      return iface;
    }
    return interfaces.first;
  }

  /// Get interface by name
  NetworkInterface? getInterface(String name) {
    try {
      return interfaces.firstWhere((iface) => iface.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Sync legacy fields with new interface structure
  /// Call this when legacy fields are updated to keep them in sync
  void _syncLegacyToNew() {
    if (interfaces.isNotEmpty) {
      final iface = defaultInterface;
      iface.ipAddress = currentIpAddress;
      iface.subnetMask = currentSubnetMask;
      iface.defaultGateway = currentDefaultGateway;
      iface.status = _linkState == 'UP'
          ? InterfaceStatus.up
          : InterfaceStatus.down;
    }

    // Sync legacy ARP cache to structured cache
    for (final entry in arpCache) {
      final ip = entry['ip'];
      final mac = entry['mac'];
      if (ip != null && mac != null) {
        arpCacheStructured.addDynamic(ip, mac, defaultInterface.name);
      }
    }
  }

  /// Sync new infrastructure to legacy fields
  /// Call this when new infrastructure is updated
  void _syncNewToLegacy() {
    if (interfaces.isNotEmpty) {
      final iface = defaultInterface;
      currentIpAddress = iface.ipAddress;
      currentSubnetMask = iface.subnetMask;
      currentDefaultGateway = iface.defaultGateway;
      _linkState = iface.status == InterfaceStatus.up ? 'UP' : 'DOWN';
    }

    // Sync structured ARP to legacy format
    arpCache = arpCacheStructured.toLegacyFormat();
  }

  // IPowerable implementation
  @override
  bool get isPoweredOn => _isPoweredOn;

  @override
  void powerOn() {
    _isPoweredOn = true;
    statusMessage = _linkState == 'UP' ? 'Booting...' : 'No cable connected';
  }

  @override
  void powerOff() {
    _isPoweredOn = false;
    statusMessage = 'Powered off';
  }

  @override
  void reboot() {
    powerOff();
    Future.delayed(const Duration(milliseconds: 500), powerOn);
  }

  // INetworkConfigurable implementation
  @override
  String? get ipAddress => currentIpAddress;

  @override
  String? get subnetMask => currentSubnetMask;

  @override
  String? get defaultGateway => currentDefaultGateway;

  @override
  void setStaticIp(String ip, String subnet, String gateway) {
    ipConfigMode = 'STATIC';
    staticIpAddress = ip;
    staticSubnetMask = subnet;
    staticDefaultGateway = gateway;

    currentIpAddress = ip;
    currentSubnetMask = subnet;
    currentDefaultGateway = gateway;

    statusMessage = 'Static IP configured';
  }

  @override
  void enableDhcp() {
    ipConfigMode = 'DHCP';
    staticIpAddress = null;
    statusMessage = 'Requesting DHCP...';
    // Simulation engine will assign DHCP values
  }

  // IConnectable implementation
  @override
  String get linkState => _linkState;

  @override
  void connectCable(String targetDeviceId, int targetPort) {
    _linkState = 'UP';
    statusMessage = 'Cable connected';
  }

  @override
  void disconnectCable() {
    _linkState = 'DOWN';
    currentIpAddress = null;
    statusMessage = 'Cable disconnected';
  }

  // ITerminalAccessible implementation
  @override
  List<String> get availableCommands => installedTools;

  @override
  String runCommand(String command, List<String> args) {
    // Simulation logic will be handled by game engine
    return 'Executing $command ${args.join(' ')}...';
  }

  // Capability and Property implementations
  @override
  String get capabilityName => 'End Device';

  @override
  List<DeviceAction> get availableActions => getAvailableActions();

  @override
  List<DeviceCapability> get capabilities => [this];

  /// Whether IP address can be edited (true for EndDevice, false for Server/Router/etc)
  bool get canEditIpAddress => true;

  @override
  List<DeviceProperty> get properties => [
    StringProperty(id: 'hostname', label: 'Hostname', value: hostname),
    MacAddressProperty(
      id: 'macAddress',
      label: 'MAC Address',
      value: macAddress,
    ),
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
      id: 'linkState',
      label: 'Link',
      value: _linkState,
      color: _linkState == 'UP' ? Colors.green : Colors.orange,
    ),
    if (canEditIpAddress)
      SelectionProperty(
        id: 'ipConfigMode',
        label: 'IP Configuration',
        value: ipConfigMode,
        options: ['STATIC', 'DHCP'],
      ),
    IpAddressProperty(
      id: 'currentIp',
      label: 'IP Address',
      value: currentIpAddress ?? 'Not assigned',
      isReadOnly: !canEditIpAddress || ipConfigMode == 'DHCP',
    ),
    IpAddressProperty(
      id: 'currentSubnet',
      label: 'Subnet Mask',
      value: currentSubnetMask ?? 'Not assigned',
      isReadOnly: !canEditIpAddress || ipConfigMode == 'DHCP',
    ),
    IpAddressProperty(
      id: 'currentGateway',
      label: 'Default Gateway',
      value: currentDefaultGateway ?? 'Not assigned',
      isReadOnly: !canEditIpAddress || ipConfigMode == 'DHCP',
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
        id: 'open_terminal',
        label: 'Open Terminal',
        icon: Icons.terminal,
        onExecute: () {}, // UI will handle this
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'ip_config',
        label: 'Configure IP',
        icon: Icons.settings_ethernet,
        onExecute: () {}, // UI will handle this
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'dhcp_renew',
        label: 'Renew DHCP',
        icon: Icons.refresh,
        onExecute: enableDhcp,
        isEnabled: _isPoweredOn && ipConfigMode == 'DHCP',
      ),
      DeviceAction(
        id: 'ping_test',
        label: 'Ping Test',
        icon: Icons.network_check,
        onExecute: () {}, // UI will trigger ping dialog
        isEnabled: _isPoweredOn && currentIpAddress != null,
      ),
      DeviceAction(
        id: 'view_arp_cache',
        label: 'View ARP Cache',
        icon: Icons.table_chart,
        onExecute: () {}, // UI will trigger ARP cache dialog
        isEnabled: _isPoweredOn,
      ),
      if (_linkState == 'DOWN')
        DeviceAction(
          id: 'connect_cable',
          label: 'Connect Cable',
          icon: Icons.cable,
          onExecute: () {}, // UI will handle drag/drop
        ),
    ];
  }

  /// Handle incoming packet
  void handlePacket(Packet packet, SimulationEngine engine) {
    if (!_isPoweredOn) return;

    // Update ARP cache if we see a packet from a known IP
    if (packet.sourceIp != null && packet.sourceMac.isNotEmpty) {
      _updateArpCache(packet.sourceIp!, packet.sourceMac);
    }

    // Process packet based on type
    if (packet.destMac == macAddress || packet.destMac == 'FF:FF:FF:FF:FF:FF') {
      switch (packet.type) {
        case PacketType.arpRequest:
          _handleArpRequest(packet, engine);
          break;
        case PacketType.arpReply:
          // Already updated cache above
          // Check if there's a pending ping for this IP
          _handleArpReply(packet, engine);
          break;
        case PacketType.icmpEchoRequest:
          _handleIcmpEchoRequest(packet, engine);
          break;
        case PacketType.icmpEchoReply:
          // Handle ping reply (log success)
          appLogger.i(
            '[EndDevice] Ping reply received from ${packet.sourceIp}',
          );
          break;
        default:
          break;
      }
    }
  }

  void _updateArpCache(String ip, String mac) {
    // Check if entry exists and is different, or doesn't exist
    final existingIndex = arpCache.indexWhere((entry) => entry['ip'] == ip);
    if (existingIndex != -1) {
      if (arpCache[existingIndex]['mac'] != mac) {
        // Replace the entire entry to avoid immutability issues
        arpCache[existingIndex] = {'ip': ip, 'mac': mac};
      }
    } else {
      arpCache.add({'ip': ip, 'mac': mac});
    }
  }

  void _handleArpRequest(Packet packet, SimulationEngine engine) {
    final targetIp = packet.payload['targetIp'];
    if (targetIp == currentIpAddress) {
      appLogger.d('[EndDevice] Received ARP request for my IP: $targetIp');
      // Send ARP Reply
      final reply = Packet(
        sourceMac: macAddress,
        destMac: packet.sourceMac,
        sourceIp: currentIpAddress,
        destIp: packet.sourceIp,
        type: PacketType.arpReply,
        payload: {'targetIp': packet.sourceIp, 'targetMac': packet.sourceMac},
      );
      appLogger.d('[EndDevice] Sending ARP reply to ${packet.sourceIp}');
      engine.sendPacket(reply, deviceId);
    }
  }

  void _handleArpReply(Packet packet, SimulationEngine engine) {
    final sourceIp = packet.sourceIp;
    if (sourceIp == null) return;

    appLogger.i('[EndDevice] Received ARP reply from $sourceIp');

    // Check if we have a pending ping for this IP
    if (_pendingPings.containsKey(sourceIp)) {
      appLogger.i(
        '[EndDevice] Found pending ping for $sourceIp, sending ICMP now',
      );

      // Get MAC from ARP cache (already updated above)
      final arpEntry = arpCache.firstWhere(
        (entry) => entry['ip'] == sourceIp,
        orElse: () => {},
      );

      if (arpEntry.isNotEmpty) {
        // Send the queued ICMP Echo Request
        final sequence = _pendingPings[sourceIp] ?? 1;
        final icmpPacket = Packet(
          sourceMac: macAddress,
          destMac: arpEntry['mac']!,
          sourceIp: currentIpAddress,
          destIp: sourceIp,
          type: PacketType.icmpEchoRequest,
          payload: {'sequence': sequence, 'data': 'PingData'},
        );

        appLogger.d(
          '[EndDevice] Sending queued ICMP Echo Request to $sourceIp',
        );
        engine.sendPacket(icmpPacket, deviceId);

        // Remove from pending queue
        _pendingPings.remove(sourceIp);
      }
    }
  }

  void _handleIcmpEchoRequest(Packet packet, SimulationEngine engine) {
    if (packet.destIp == currentIpAddress) {
      // Send Echo Reply
      final reply = Packet(
        sourceMac: macAddress,
        destMac: packet.sourceMac,
        sourceIp: currentIpAddress,
        destIp: packet.sourceIp,
        type: PacketType.icmpEchoReply,
        payload: packet.payload,
      );
      engine.sendPacket(reply, deviceId);
    }
  }

  /// Initiate a ping
  void ping(String targetIp, SimulationEngine engine) {
    if (!_isPoweredOn || currentIpAddress == null) return;

    appLogger.i(
      '[EndDevice] Initiating ping to $targetIp from $hostname ($currentIpAddress)',
    );

    // Check ARP cache
    final arpEntry = arpCache.firstWhere(
      (entry) => entry['ip'] == targetIp,
      orElse: () => {},
    );

    if (arpEntry.isNotEmpty) {
      // MAC address known, send ICMP Echo Request directly
      appLogger.d('[EndDevice] MAC found in ARP cache, sending ICMP directly');
      final packet = Packet(
        sourceMac: macAddress,
        destMac: arpEntry['mac']!,
        sourceIp: currentIpAddress,
        destIp: targetIp,
        type: PacketType.icmpEchoRequest,
        payload: {'sequence': 1, 'data': 'PingData'},
      );
      engine.sendPacket(packet, deviceId);
    } else {
      // MAC address unknown, send ARP Request first
      appLogger.i(
        '[EndDevice] MAC not in cache, sending ARP request for $targetIp',
      );

      // Queue this ping to be sent after ARP reply is received
      _pendingPings[targetIp] = 1; // sequence number

      final arpPacket = Packet(
        sourceMac: macAddress,
        destMac: 'FF:FF:FF:FF:FF:FF', // Broadcast
        sourceIp: currentIpAddress,
        destIp: targetIp,
        type: PacketType.arpRequest,
        payload: {
          'targetIp': targetIp,
          'senderIp': currentIpAddress,
          'senderMac': macAddress,
        },
      );
      engine.sendPacket(arpPacket, deviceId);
      appLogger.d(
        '[EndDevice] ARP request sent, ping queued for after resolution',
      );
    }
  }
}
