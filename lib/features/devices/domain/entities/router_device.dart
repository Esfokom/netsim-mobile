import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/routing_table.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_capability.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_property.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/packet.dart';
import 'package:netsim_mobile/features/simulation/domain/services/simulation_engine.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';

/// Layer 3 Router - Connects different networks via routing
/// Implements full Phase 3 requirements:
/// - Multiple interfaces with independent ARP caches
/// - Packet forwarding between subnets
/// - TTL management
/// - Route lookup with longest prefix match
/// - Interface lifecycle management
class RouterDevice extends NetworkDevice
    implements IPowerable, IRoutable, IConfigurable, IServiceHost {
  String name;
  bool _isPoweredOn;

  /// Multiple interfaces (key = interface name, e.g., "eth0", "eth1")
  final Map<String, RouterInterface> interfaces;

  /// Routing table (shared across all interfaces)
  final RoutingTable _routingTable;

  bool natEnabled;
  bool dhcpServiceEnabled;
  bool firewallEnabled;
  bool showIpOnCanvas;

  RouterDevice({
    required super.deviceId,
    required super.position,
    String? name,
    bool isPoweredOn = true,
    Map<String, RouterInterface>? interfaces,
    this.natEnabled = false,
    this.dhcpServiceEnabled = false,
    this.firewallEnabled = false,
    this.showIpOnCanvas = false,
  }) : name = name ?? deviceId,
       _isPoweredOn = isPoweredOn,
       interfaces = interfaces ?? _createDefaultInterfaces(),
       _routingTable = RoutingTable(),
       super(deviceType: 'Router') {
    _initializeRoutingTable();
  }

  /// Create default 2 interfaces (eth0 LAN, eth1 WAN)
  static Map<String, RouterInterface> _createDefaultInterfaces() {
    return {
      'eth0': RouterInterface(
        name: 'eth0',
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.255.0',
        macAddress: _generateMac(),
        status: InterfaceStatus.down,
        linkState: 'DOWN',
      ),
      'eth1': RouterInterface(
        name: 'eth1',
        ipAddress: '10.0.0.1',
        subnetMask: '255.255.255.0',
        macAddress: _generateMac(),
        status: InterfaceStatus.down,
        linkState: 'DOWN',
      ),
    };
  }

  static String _generateMac() {
    final random = DateTime.now().microsecondsSinceEpoch;
    return '00:00:${(random & 0xFF).toRadixString(16).padLeft(2, '0')}:'
        '${((random >> 8) & 0xFF).toRadixString(16).padLeft(2, '0')}:'
        '${((random >> 16) & 0xFF).toRadixString(16).padLeft(2, '0')}:'
        '${((random >> 24) & 0xFF).toRadixString(16).padLeft(2, '0')}';
  }

  void _initializeRoutingTable() {
    // Add directly connected routes for each interface
    for (var iface in interfaces.values) {
      if (iface.ipAddress.isNotEmpty && iface.subnetMask.isNotEmpty) {
        final networkAddr = _calculateNetworkAddress(
          iface.ipAddress,
          iface.subnetMask,
        );

        _routingTable.addDirectlyConnectedRoute(
          network: networkAddr,
          subnetMask: iface.subnetMask,
          interfaceName: iface.name,
        );

        appLogger.d(
          '[Router $name] Added connected route: $networkAddr/${iface.subnetMask} via ${iface.name}',
        );
      }
    }
  }

  String _calculateNetworkAddress(String ip, String mask) {
    try {
      final ipParts = ip.split('.').map(int.parse).toList();
      final maskParts = mask.split('.').map(int.parse).toList();

      if (ipParts.length != 4 || maskParts.length != 4) {
        return '0.0.0.0';
      }

      final networkParts = <int>[];
      for (int i = 0; i < 4; i++) {
        networkParts.add(ipParts[i] & maskParts[i]);
      }

      return networkParts.join('.');
    } catch (e) {
      appLogger.e('[Router $name] Error calculating network address', error: e);
      return '0.0.0.0';
    }
  }

  @override
  IconData get icon => Icons.router;

  @override
  Color get color => Colors.blue;

  @override
  String get displayName => showIpOnCanvas && interfaces.isNotEmpty
      ? interfaces.values.first.ipAddress
      : name;

  // IRoutable implementation - routing table getter
  @override
  List<Map<String, dynamic>> get routingTable =>
      _routingTable.entries.map((r) => r.toJson()).toList();

  @override
  DeviceStatus get status {
    // Simple two-state model: online when powered on, offline when powered off
    return _isPoweredOn ? DeviceStatus.online : DeviceStatus.offline;
  }

  // IPowerable implementation
  @override
  bool get isPoweredOn => _isPoweredOn;

  @override
  void powerOn() => _isPoweredOn = true;

  @override
  void powerOff() {
    _isPoweredOn = false;
    for (var iface in interfaces.values) {
      iface.status = InterfaceStatus.down;
      iface.linkState = 'DOWN';
    }
  }

  @override
  void reboot() {
    powerOff();
    Future.delayed(const Duration(milliseconds: 500), () {
      powerOn();
      for (var iface in interfaces.values) {
        if (iface.connectedLinkId != null) {
          iface.status = InterfaceStatus.up;
          iface.linkState = 'UP';
        }
      }
    });
  }

  @override
  void addStaticRoute(String destination, String mask, String gateway) {
    final interfaceName = _findInterfaceForGateway(gateway);

    _routingTable.addRoute(
      RoutingEntry(
        destinationNetwork: destination,
        subnetMask: mask,
        gateway: gateway,
        interfaceName: interfaceName,
        metric: 1, // Static routes have metric 1
      ),
    );

    appLogger.d(
      '[Router $name] Added static route: $destination/$mask via $gateway on $interfaceName',
    );
  }

  @override
  void removeStaticRoute(String destination) {
    final toRemove = _routingTable.entries
        .where((e) => e.destinationNetwork == destination && e.gateway != null)
        .toList();

    for (var entry in toRemove) {
      _routingTable.removeRoute(entry.destinationNetwork, entry.subnetMask);
      appLogger.d('[Router $name] Removed static route: $destination');
    }
  }

  String _findInterfaceForGateway(String gateway) {
    // Find which interface can reach this gateway (same subnet)
    for (var iface in interfaces.values) {
      if (_isInSameSubnet(gateway, iface.ipAddress, iface.subnetMask)) {
        return iface.name;
      }
    }
    // Default to first interface if no match
    return interfaces.values.first.name;
  }

  bool _isInSameSubnet(String ip1, String ip2, String mask) {
    try {
      final ip1Parts = ip1.split('.').map(int.parse).toList();
      final ip2Parts = ip2.split('.').map(int.parse).toList();
      final maskParts = mask.split('.').map(int.parse).toList();

      for (int i = 0; i < 4; i++) {
        if ((ip1Parts[i] & maskParts[i]) != (ip2Parts[i] & maskParts[i])) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // IServiceHost implementation
  @override
  List<String> get runningServices {
    List<String> services = [];
    if (dhcpServiceEnabled) services.add('DHCP');
    if (firewallEnabled) services.add('Firewall');
    if (natEnabled) services.add('NAT');
    return services;
  }

  @override
  void startService(String serviceName) {
    switch (serviceName.toUpperCase()) {
      case 'DHCP':
        dhcpServiceEnabled = true;
        break;
      case 'FIREWALL':
        firewallEnabled = true;
        break;
      case 'NAT':
        natEnabled = true;
        break;
    }
  }

  @override
  void stopService(String serviceName) {
    switch (serviceName.toUpperCase()) {
      case 'DHCP':
        dhcpServiceEnabled = false;
        break;
      case 'FIREWALL':
        firewallEnabled = false;
        break;
      case 'NAT':
        natEnabled = false;
        break;
    }
  }

  @override
  void configureService(String serviceName, Map<String, dynamic> config) {
    // Configuration will be handled by specific service panels
  }

  // IConfigurable implementation
  @override
  Map<String, dynamic> get configuration => {
    'interfaces': interfaces.values.map((i) => i.toMap()).toList(),
    'routingTable': routingTable,
    'natEnabled': natEnabled,
    'dhcpServiceEnabled': dhcpServiceEnabled,
    'firewallEnabled': firewallEnabled,
  };

  @override
  void updateConfiguration(Map<String, dynamic> config) {
    if (config.containsKey('natEnabled')) {
      natEnabled = config['natEnabled'];
    }
  }

  @override
  String get capabilityName => 'Layer 3 Router';

  @override
  List<DeviceAction> get availableActions => getAvailableActions();

  @override
  List<DeviceCapability> get capabilities => [this];

  @override
  List<DeviceProperty> get properties {
    final List<DeviceProperty> props = [
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
      IntegerProperty(
        id: 'interfaceCount',
        label: 'Interfaces',
        value: interfaces.length,
        isReadOnly: true,
      ),
      IntegerProperty(
        id: 'routeCount',
        label: 'Routes',
        value: _routingTable.entries.length,
        isReadOnly: true,
      ),
    ];

    // Add IP addresses for each interface (read-only)
    for (var iface in interfaces.values) {
      props.add(
        IpAddressProperty(
          id: 'ip_${iface.name}',
          label: '${iface.name} IP',
          value: iface.ipAddress,
          isReadOnly: true,
        ),
      );
    }

    props.addAll([
      BooleanProperty(
        id: 'natEnabled',
        label: 'NAT Enabled',
        value: natEnabled,
      ),
      BooleanProperty(
        id: 'dhcpEnabled',
        label: 'DHCP Service',
        value: dhcpServiceEnabled,
      ),
      BooleanProperty(
        id: 'firewallEnabled',
        label: 'Firewall',
        value: firewallEnabled,
      ),
    ]);

    return props;
  }

  @override
  List<DeviceAction> getAvailableActions() {
    return [
      // Power Management
      DeviceAction(
        id: 'power_toggle',
        label: _isPoweredOn ? 'Power Off' : 'Power On',
        icon: Icons.power_settings_new,
        onExecute: _isPoweredOn ? powerOff : powerOn,
      ),
      DeviceAction(
        id: 'reboot',
        label: 'Reboot Router',
        icon: Icons.restart_alt,
        onExecute: reboot,
        isEnabled: _isPoweredOn,
      ),

      // Interface Management
      DeviceAction(
        id: 'view_interfaces',
        label: 'View Interfaces',
        icon: Icons.settings_ethernet,
        onExecute: () {}, // UI will handle this
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'configure_interface',
        label: 'Configure Interface',
        icon: Icons.edit_road,
        onExecute: () {}, // UI will handle this
        isEnabled: _isPoweredOn,
      ),

      // Routing
      DeviceAction(
        id: 'view_routing_table',
        label: 'View Routing Table',
        icon: Icons.table_chart,
        onExecute: () {}, // UI will handle this
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'add_static_route',
        label: 'Add Static Route',
        icon: Icons.add_road,
        onExecute: () {}, // UI will handle this
        isEnabled: _isPoweredOn,
      ),

      // ARP Cache
      DeviceAction(
        id: 'view_arp_eth0',
        label: 'View eth0 ARP Cache',
        icon: Icons.list_alt,
        onExecute: () {}, // UI will handle this
        isEnabled: _isPoweredOn && interfaces.containsKey('eth0'),
      ),
      DeviceAction(
        id: 'view_arp_eth1',
        label: 'View eth1 ARP Cache',
        icon: Icons.list_alt,
        onExecute: () {}, // UI will handle this
        isEnabled: _isPoweredOn && interfaces.containsKey('eth1'),
      ),

      // Services
      DeviceAction(
        id: 'nat_toggle',
        label: natEnabled ? 'Disable NAT' : 'Enable NAT',
        icon: Icons.swap_horiz,
        onExecute: () => natEnabled ? stopService('NAT') : startService('NAT'),
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'dhcp_toggle',
        label: dhcpServiceEnabled ? 'Disable DHCP' : 'Enable DHCP',
        icon: Icons.dns,
        onExecute: () =>
            dhcpServiceEnabled ? stopService('DHCP') : startService('DHCP'),
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'firewall_toggle',
        label: firewallEnabled ? 'Disable Firewall' : 'Enable Firewall',
        icon: Icons.security,
        onExecute: () => firewallEnabled
            ? stopService('FIREWALL')
            : startService('FIREWALL'),
        isEnabled: _isPoweredOn,
      ),
    ];
  }

  /// Set IP address for an interface
  void setInterfaceIp(String interfaceName, String ip, String subnet) {
    final iface = interfaces[interfaceName];
    if (iface == null) {
      appLogger.w('[Router $name] Interface $interfaceName not found');
      return;
    }

    iface.ipAddress = ip;
    iface.subnetMask = subnet;

    // Rebuild routing table
    _routingTable.clear();
    _initializeRoutingTable();

    appLogger.d('[Router $name] Set $interfaceName IP to $ip/$subnet');
  }

  /// Set interface operational status
  void setInterfaceStatus(String interfaceName, InterfaceStatus status) {
    final iface = interfaces[interfaceName];
    if (iface == null) {
      appLogger.w('[Router $name] Interface $interfaceName not found');
      return;
    }

    iface.status = status;
    appLogger.d('[Router $name] Set $interfaceName status to $status');
  }

  /// Connect a cable to an interface (brings interface UP)
  void connectCable(String interfaceName) {
    final iface = interfaces[interfaceName];
    if (iface == null) {
      appLogger.w('[Router $name] Interface $interfaceName not found');
      return;
    }

    iface.linkState = 'UP';
    iface.status = InterfaceStatus.up;

    appLogger.d(
      '[Router $name] Interface $interfaceName cable connected, bringing UP',
    );
  }

  /// Disconnect cable from an interface (brings interface DOWN)
  void disconnectCable(String interfaceName) {
    final iface = interfaces[interfaceName];
    if (iface == null) {
      appLogger.w('[Router $name] Interface $interfaceName not found');
      return;
    }

    iface.linkState = 'DOWN';
    iface.status = InterfaceStatus.down;
    iface.arpCache.clear();

    appLogger.d(
      '[Router $name] Interface $interfaceName cable disconnected, bringing DOWN',
    );
  }

  /// Get interface by name
  RouterInterface? getInterface(String interfaceName) {
    return interfaces[interfaceName];
  }

  /// Check if packet is destined for this router
  bool isPacketForMe(String destIp) {
    return interfaces.values.any((iface) => iface.ipAddress == destIp);
  }

  /// Handle incoming packet on a specific interface
  /// This is the core Phase 3 packet forwarding logic
  void handlePacket(
    Packet packet,
    String incomingInterfaceName,
    SimulationEngine engine,
  ) {
    if (!_isPoweredOn) {
      appLogger.d('[Router $name] Router is powered off, dropping packet');
      return;
    }

    final incomingInterface = interfaces[incomingInterfaceName];
    if (incomingInterface == null || !incomingInterface.isOperational) {
      appLogger.w(
        '[Router $name] Incoming interface $incomingInterfaceName not operational',
      );
      return;
    }

    appLogger.d(
      '[Router $name] Received ${packet.type} packet on $incomingInterfaceName: ${packet.sourceIp} → ${packet.destIp}',
    );

    // Handle ARP requests specially - they may need Proxy ARP
    if (packet.type == PacketType.arpRequest) {
      _handleArpRequest(packet, incomingInterface, engine);
      return;
    }

    // Check if packet is for this router
    if (isPacketForMe(packet.destIp ?? '')) {
      _handleLocalPacket(packet, incomingInterface, engine);
      return;
    }

    // Forward packet
    _forwardPacket(packet, incomingInterface, engine);
  }

  /// Handle packet destined for the router itself
  void _handleLocalPacket(
    Packet packet,
    RouterInterface incomingInterface,
    SimulationEngine engine,
  ) {
    appLogger.d(
      '[Router $name] Packet is for me (${incomingInterface.ipAddress}), processing locally',
    );

    // Handle different packet types
    switch (packet.type) {
      case PacketType.arpRequest:
        _handleArpRequest(packet, incomingInterface, engine);
        break;
      case PacketType.icmpEchoRequest:
        _handleIcmpEchoRequest(packet, incomingInterface, engine);
        break;
      default:
        appLogger.d(
          '[Router $name] Unsupported packet type for local processing: ${packet.type}',
        );
    }
  }

  /// Forward packet to next hop
  void _forwardPacket(
    Packet packet,
    RouterInterface incomingInterface,
    SimulationEngine engine,
  ) {
    // Decrement TTL
    final newTtl = packet.ttl - 1;
    if (newTtl <= 0) {
      appLogger.w('[Router $name] TTL expired, dropping packet');
      // TODO: Send ICMP Time Exceeded
      return;
    }

    final destIp = packet.destIp ?? '';

    appLogger.d(
      '[Router $name] Forwarding packet (TTL: $newTtl): ${packet.sourceIp} → $destIp',
    );

    // Look up route
    final route = _routingTable.longestPrefixMatch(destIp);
    if (route == null) {
      appLogger.w('[Router $name] No route to $destIp, dropping packet');
      // TODO: Send ICMP Destination Unreachable
      return;
    }

    appLogger.d(
      '[Router $name] Found route: ${route.destinationNetwork}/${route.subnetMask} via ${route.gateway ?? "direct"} on ${route.interfaceName}',
    );

    // Get output interface
    final outputInterface = interfaces[route.interfaceName];
    if (outputInterface == null || !outputInterface.isOperational) {
      appLogger.w(
        '[Router $name] Output interface ${route.interfaceName} not operational',
      );
      return;
    }

    // Determine next-hop IP
    final nextHopIp = route.gateway ?? destIp;
    appLogger.d('[Router $name] Next hop: $nextHopIp');

    // Look up next-hop MAC in output interface's ARP cache
    final nextHopMac = outputInterface.arpCache[nextHopIp];
    if (nextHopMac == null) {
      appLogger.d(
        '[Router $name] No ARP entry for $nextHopIp, need ARP resolution',
      );
      // TODO: Queue packet and send ARP request
      return;
    }

    // Create new packet with decremented TTL and rewritten MAC addresses
    final forwardedPacket = packet.copyWith(
      ttl: newTtl,
      sourceMac: outputInterface.macAddress,
      destMac: nextHopMac,
    );

    appLogger.d(
      '[Router $name] Forwarding packet out ${outputInterface.name}: ${outputInterface.macAddress} → $nextHopMac',
    );

    // Send packet out the output interface
    engine.sendPacket(forwardedPacket, deviceId);
  }

  /// Handle ARP request received on an interface
  /// Implements Proxy ARP - responds to ARP requests for IPs the router can reach
  void _handleArpRequest(
    Packet packet,
    RouterInterface incomingInterface,
    SimulationEngine engine,
  ) {
    final requestedIp = packet.destIp ?? '';
    appLogger.d(
      '[Router $name] Received ARP request for $requestedIp on ${incomingInterface.name}',
    );

    // Check if the requested IP is for this interface
    if (requestedIp == incomingInterface.ipAddress) {
      // ARP request is for the router itself
      appLogger.d(
        '[Router $name] ARP request is for this interface, sending reply',
      );

      final replyPacket = Packet(
        type: PacketType.arpReply,
        sourceIp: incomingInterface.ipAddress,
        destIp: packet.sourceIp,
        sourceMac: incomingInterface.macAddress,
        destMac: packet.sourceMac,
        ttl: 64,
      );

      engine.sendPacket(replyPacket, deviceId);

      // Learn the requester's MAC
      if (packet.sourceIp != null) {
        incomingInterface.arpCache[packet.sourceIp!] = packet.sourceMac;
      }
      return;
    }

    // Check if we can route to the requested IP (Proxy ARP)
    final route = _routingTable.longestPrefixMatch(requestedIp);
    if (route != null) {
      appLogger.d(
        '[Router $name] Performing Proxy ARP for $requestedIp (route exists via ${route.interfaceName})',
      );

      // Send ARP reply with THIS router interface's MAC
      // This makes the requester think the router IS the destination
      // The router will then forward packets appropriately
      final replyPacket = Packet(
        type: PacketType.arpReply,
        sourceIp: requestedIp, // Pretend to be the requested IP
        destIp: packet.sourceIp,
        sourceMac: incomingInterface.macAddress, // But give router's MAC
        destMac: packet.sourceMac,
        ttl: 64,
      );

      appLogger.d(
        '[Router $name] Sending Proxy ARP reply: telling ${packet.sourceIp} that $requestedIp is at ${incomingInterface.macAddress}',
      );
      engine.sendPacket(replyPacket, deviceId);

      // Learn the requester's MAC
      if (packet.sourceIp != null) {
        incomingInterface.arpCache[packet.sourceIp!] = packet.sourceMac;
        appLogger.d(
          '[Router $name] Learned ${packet.sourceIp} -> ${packet.sourceMac} on ${incomingInterface.name}',
        );
      }
    } else {
      appLogger.w(
        '[Router $name] Cannot proxy ARP for $requestedIp - no route exists',
      );
    }
  }

  /// Handle ICMP echo request (ping) received on an interface
  void _handleIcmpEchoRequest(
    Packet packet,
    RouterInterface incomingInterface,
    SimulationEngine engine,
  ) {
    appLogger.d(
      '[Router $name] Received ICMP echo request from ${packet.sourceIp} on ${incomingInterface.name}',
    );

    // Send ICMP echo reply
    final replyPacket = Packet(
      type: PacketType.icmpEchoReply,
      sourceIp: incomingInterface.ipAddress,
      destIp: packet.sourceIp,
      sourceMac: incomingInterface.macAddress,
      destMac: packet.sourceMac,
      ttl: 64,
    );

    appLogger.d('[Router $name] Sending ICMP echo reply to ${packet.sourceIp}');
    engine.sendPacket(replyPacket, deviceId);
  }

  /// Initiate a ping from the router to a target IP
  void ping(String targetIp, SimulationEngine engine) {
    if (!_isPoweredOn) {
      appLogger.w('[Router $name] Cannot ping - router is powered off');
      return;
    }

    // Find first operational interface to use as source
    RouterInterface? sourceInterface;
    for (final iface in interfaces.values) {
      if (iface.isOperational && iface.ipAddress.isNotEmpty) {
        sourceInterface = iface;
        break;
      }
    }

    if (sourceInterface == null) {
      appLogger.w('[Router $name] Cannot ping - no operational interfaces');
      return;
    }

    appLogger.d(
      '[Router $name] Initiating ping from ${sourceInterface.name} (${sourceInterface.ipAddress}) to $targetIp',
    );

    // Register ping session start for telemetry (before any ARP/ICMP)
    engine.telemetryService?.registerPingSessionStart(
      deviceId,
      sourceInterface.ipAddress,
      targetIp,
      timeoutMs: 5000, // Router default timeout: 5 seconds
    );

    // Look up route to target
    final route = _routingTable.longestPrefixMatch(targetIp);
    if (route == null) {
      appLogger.w('[Router $name] Cannot ping $targetIp - no route');
      return;
    }

    // Determine next hop
    final nextHopIp = route.gateway ?? targetIp;
    final outputInterface = interfaces[route.interfaceName];

    if (outputInterface == null || !outputInterface.isOperational) {
      appLogger.w('[Router $name] Output interface not operational');
      return;
    }

    // Check ARP cache for next hop
    final nextHopMac = outputInterface.arpCache[nextHopIp];
    if (nextHopMac == null) {
      appLogger.d(
        '[Router $name] No ARP entry for $nextHopIp, need ARP resolution first',
      );
      // TODO: Queue ping and send ARP request
      return;
    }

    // Create ICMP Echo Request packet
    final packet = Packet(
      type: PacketType.icmpEchoRequest,
      sourceIp: sourceInterface.ipAddress,
      destIp: targetIp,
      sourceMac: outputInterface.macAddress,
      destMac: nextHopMac,
      ttl: 64,
    );

    appLogger.d('[Router $name] Sending ICMP Echo Request to $targetIp');
    engine.sendPacket(packet, deviceId);
  }
}

/// Router Interface with lifecycle management
/// Each interface has its own ARP cache and can be independently configured
class RouterInterface {
  /// Interface name (e.g., "eth0", "eth1")
  final String name;

  /// IP address assigned to this interface
  String ipAddress;

  /// Subnet mask
  String subnetMask;

  /// MAC address (unique per interface)
  final String macAddress;

  /// Interface administrative status (UP/DOWN)
  InterfaceStatus status;

  /// Link state - physical connection status
  String linkState; // "UP" | "DOWN"

  /// ARP cache for this interface (IP → MAC)
  final Map<String, String> arpCache;

  /// Connected link ID (if cable is connected)
  String? connectedLinkId;

  RouterInterface({
    required this.name,
    required this.ipAddress,
    required this.subnetMask,
    required this.macAddress,
    this.status = InterfaceStatus.down,
    this.linkState = 'DOWN',
    this.connectedLinkId,
  }) : arpCache = {};

  /// Is interface operational? (both administratively UP and physically connected)
  bool get isOperational =>
      linkState == 'UP' && status == InterfaceStatus.up && ipAddress.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'name': name,
    'ipAddress': ipAddress,
    'subnetMask': subnetMask,
    'macAddress': macAddress,
    'status': status.toString(),
    'linkState': linkState,
    'connectedLinkId': connectedLinkId,
    'arpCacheSize': arpCache.length,
  };

  factory RouterInterface.fromMap(Map<String, dynamic> map) {
    return RouterInterface(
      name: map['name'] as String,
      ipAddress: map['ipAddress'] as String,
      subnetMask: map['subnetMask'] as String,
      macAddress: map['macAddress'] as String,
      status: _parseInterfaceStatus(map['status'] as String?),
      linkState: map['linkState'] as String? ?? 'DOWN',
      connectedLinkId: map['connectedLinkId'] as String?,
    );
  }

  static InterfaceStatus _parseInterfaceStatus(String? status) {
    if (status == null) return InterfaceStatus.down;

    switch (status) {
      case 'InterfaceStatus.up':
        return InterfaceStatus.up;
      case 'InterfaceStatus.down':
        return InterfaceStatus.down;
      default:
        return InterfaceStatus.down;
    }
  }
}

/// Interface status enumeration
enum InterfaceStatus { up, down }
