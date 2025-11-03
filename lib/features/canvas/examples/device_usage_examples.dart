import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/server_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/switch_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/router_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/firewall_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/wireless_access_point.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/server_device.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/device_details_panel.dart';

/// Example: How to create and use the new network devices

class DeviceExamples {
  /// Create an End Device (PC)
  static EndDevice createPC() {
    return EndDevice(
      deviceId: 'PC-001',
      position: const Offset(100, 100),
      hostname: 'Workstation-01',
      macAddress: '00:1A:2B:3C:4D:5E',
      ipConfigMode: 'STATIC',
    );
  }

  /// Create a Server with DHCP and DNS services
  static ServerDevice createServer() {
    final server = ServerDevice(
      deviceId: 'SRV-001',
      position: const Offset(200, 100),
      hostname: 'Main-Server',
      macAddress: '00:1A:2B:3C:4D:5F',
    );

    // Add DHCP service
    server.addService(
      'DHCP',
      DhcpServiceConfig(
        poolStart: '192.168.1.100',
        poolEnd: '192.168.1.200',
        defaultGateway: '192.168.1.1',
        dnsServer: '192.168.1.100',
        isRunning: true,
      ),
    );

    // Add DNS service
    final dnsService = DnsServiceConfig(isRunning: true);
    dnsService.addRecord('google.com', 'A', '8.8.8.8');
    dnsService.addRecord('internal-app.com', 'A', '192.168.1.100');
    server.addService('DNS', dnsService);

    return server;
  }

  /// Create a managed Switch with VLANs
  static SwitchDevice createSwitch() {
    final switch_ = SwitchDevice(
      deviceId: 'SW-001',
      position: const Offset(300, 100),
      portCount: 24,
      isManaged: true,
    );

    // Create VLANs
    switch_.createVlan(10, 'Guest-Network');
    switch_.createVlan(20, 'Office-Network');

    // Assign ports to VLANs
    switch_.assignPortToVlan(1, 10); // Port 1 to Guest
    switch_.assignPortToVlan(2, 20); // Port 2 to Office

    return switch_;
  }

  /// Create a Router with static routes
  static RouterDevice createRouter() {
    final router = RouterDevice(
      deviceId: 'RTR-001',
      position: const Offset(400, 100),
      natEnabled: true,
      dhcpServiceEnabled: false,
    );

    // Add a static route
    router.addStaticRoute('10.0.0.0', '255.0.0.0', '192.168.1.254');

    return router;
  }

  /// Create a Firewall with rules
  static FirewallDevice createFirewall() {
    final firewall = FirewallDevice(
      deviceId: 'FW-001',
      position: const Offset(500, 100),
      defaultPolicy: 'DENY',
    );

    // Add firewall rules
    firewall.addRule({
      'ruleId': '1',
      'name': 'Allow Web Traffic',
      'sourceIp': 'any',
      'destIp': '192.168.1.100',
      'destPort': 80,
      'protocol': 'TCP',
      'action': 'ALLOW',
      'enabled': true,
    });

    firewall.addRule({
      'ruleId': '2',
      'name': 'Block Ping',
      'sourceIp': 'any',
      'destIp': 'any',
      'destPort': null,
      'protocol': 'ICMP',
      'action': 'DENY',
      'enabled': true,
    });

    return firewall;
  }

  /// Create a Wireless Access Point
  static WirelessAccessPoint createWAP() {
    final wap = WirelessAccessPoint(
      deviceId: 'WAP-001',
      position: const Offset(600, 100),
      ssid: 'Office-WiFi',
      securityMode: 'WPA2',
      wpaPassword: 'SecurePassword123',
      channel: '6',
    );

    return wap;
  }

  /// Example: Show device details panel
  static void showDeviceDetails(BuildContext context, EndDevice device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: DeviceDetailsPanel(
          device: device,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  /// Example: Interact with device capabilities
  static void interactWithDevice() {
    final pc = createPC();

    // Power management
    pc.powerOff();
    print('PC is powered ${pc.isPoweredOn ? "ON" : "OFF"}');

    pc.powerOn();
    print('PC is powered ${pc.isPoweredOn ? "ON" : "OFF"}');

    // Network configuration
    pc.setStaticIp('192.168.1.50', '255.255.255.0', '192.168.1.1');
    print('PC IP: ${pc.currentIpAddress}');

    // Switch to DHCP
    pc.enableDhcp();
    print('PC is now in ${pc.ipConfigMode} mode');

    // Get device properties
    for (var property in pc.properties) {
      print('${property.label}: ${property.value}');
    }

    // Get available actions
    for (var action in pc.getAvailableActions()) {
      print(
        'Action: ${action.label} (${action.isEnabled ? "enabled" : "disabled"})',
      );
    }
  }

  /// Example: Working with Server services
  static void manageServerServices() {
    final server = createServer();

    // Start/stop services
    server.startService('DHCP');
    print('Running services: ${server.runningServices}');

    server.stopService('DNS');
    print('Running services: ${server.runningServices}');

    // Configure DHCP
    server.configureService('DHCP', {
      'poolStart': '192.168.1.150',
      'poolEnd': '192.168.1.250',
    });
  }

  /// Example: Working with Switch MAC table
  static void manageSwitchTable() {
    final switch_ = createSwitch();

    // Simulate learning MAC addresses
    switch_.learnMacAddress('00:1A:2B:3C:4D:5E', 1);
    switch_.learnMacAddress('00:1A:2B:3C:4D:5F', 2);

    print('MAC Table entries: ${switch_.macAddressTable.length}');

    // Clear MAC table
    switch_.clearMacAddressTable();
    print('MAC Table after clear: ${switch_.macAddressTable.length}');
  }

  /// Example: Working with Router routing table
  static void manageRouterRoutes() {
    final router = createRouter();

    print('Initial routes: ${router.routingTable.length}');

    // Add static routes
    router.addStaticRoute('172.16.0.0', '255.255.0.0', '192.168.1.254');

    print('Routes after adding: ${router.routingTable.length}');

    // Remove a route
    router.removeStaticRoute('172.16.0.0');

    print('Routes after removing: ${router.routingTable.length}');

    // Enable NAT
    router.startService('NAT');
    print('NAT enabled: ${router.natEnabled}');
  }

  /// Example: Working with Firewall rules
  static void manageFirewallRules() {
    final firewall = createFirewall();

    print('Initial rules: ${firewall.firewallRules.length}');

    // Add a new rule
    firewall.addRule({
      'ruleId': '3',
      'name': 'Allow SSH',
      'sourceIp': '192.168.1.0/24',
      'destIp': '192.168.1.100',
      'destPort': 22,
      'protocol': 'TCP',
      'action': 'ALLOW',
      'enabled': true,
    });

    print('Rules after adding: ${firewall.firewallRules.length}');

    // Move rule up (order matters!)
    firewall.moveRuleUp('3');

    // Disable a rule
    firewall.disableRule('2');

    // Change default policy
    firewall.setDefaultPolicy('ALLOW');
    print('Default policy: ${firewall.defaultPolicy}');
  }

  /// Example: Working with WAP clients
  static void manageWAPClients() {
    final wap = createWAP();

    // Simulate clients connecting
    wap.addClient('AA:BB:CC:DD:EE:01', -45);
    wap.addClient('AA:BB:CC:DD:EE:02', -60);

    print('Connected clients: ${wap.connectedClients.length}');

    // Kick a client
    wap.kickClient('AA:BB:CC:DD:EE:01');

    print('Clients after kick: ${wap.connectedClients.length}');

    // Change SSID
    wap.setSsid('New-Office-WiFi');
    print('New SSID: ${wap.ssid}');

    // Disable radio
    wap.disableRadio();
    print('Radio enabled: ${wap.radioEnabled}');
  }
}
