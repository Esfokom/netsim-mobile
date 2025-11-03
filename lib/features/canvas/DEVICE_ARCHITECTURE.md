# Network Device Architecture

## Overview

This document describes the scalable, decoupled device architecture for the Network Simulator. The architecture follows **Clean Architecture** principles with clear separation of concerns and uses the **Composition Pattern** to make devices highly extensible.

## Architecture Principles

### 1. **Decoupling Through Interfaces**
- Devices are NOT defined by inheritance hierarchies
- Devices are defined by their **capabilities** (what they can do)
- Each capability is an interface that provides specific functionality

### 2. **Composition Over Inheritance**
- Devices implement multiple capability interfaces
- New capabilities can be added without modifying existing code
- Devices can share capabilities (e.g., IPowerable is used by all devices)

### 3. **Separation of Concerns**
- **Domain Layer**: Pure business logic, no UI dependencies
- **Presentation Layer**: UI components that consume domain entities
- **Data Layer**: Legacy canvas models for backward compatibility

## Folder Structure

```
lib/features/canvas/
├── domain/
│   ├── entities/               # Concrete device implementations
│   │   ├── network_device.dart       # Base abstract class
│   │   ├── end_device.dart           # PC/Workstation
│   │   ├── server_device.dart        # Server (extends EndDevice)
│   │   ├── switch_device.dart        # Layer 2 Switch
│   │   ├── router_device.dart        # Layer 3 Router
│   │   ├── firewall_device.dart      # Dedicated Firewall
│   │   └── wireless_access_point.dart # WAP
│   └── interfaces/             # Capability interfaces
│       ├── device_capability.dart    # All capability interfaces
│       └── device_property.dart      # Property system
├── data/
│   └── models/                 # Legacy models (for backward compat)
└── presentation/
    └── widgets/
        └── device_details_panel.dart # UI for device interaction
```

## Device Capabilities

### Core Capabilities

#### **IPowerable**
All devices that can be powered on/off.
```dart
- bool isPoweredOn
- void powerOn()
- void powerOff()
- void reboot()
```

#### **INetworkConfigurable**
Devices that need IP configuration (PCs, Servers, WAPs, etc.).
```dart
- String? ipAddress
- String? subnetMask
- String? defaultGateway
- void setStaticIp(String ip, String subnet, String gateway)
- void enableDhcp()
```

#### **IConnectable**
Devices that can have cables connected/disconnected.
```dart
- String linkState // "UP" | "DOWN"
- void connectCable(String targetDeviceId, int targetPort)
- void disconnectCable()
```

#### **ITerminalAccessible**
Devices that provide CLI/terminal access.
```dart
- List<String> availableCommands
- String runCommand(String command, List<String> args)
```

#### **IConfigurable**
Devices with advanced configuration panels.
```dart
- Map<String, dynamic> configuration
- void updateConfiguration(Map<String, dynamic> config)
```

### Specialized Capabilities

#### **IServiceHost**
For servers and routers that host services (DHCP, DNS, Web, etc.).
```dart
- List<String> runningServices
- void startService(String serviceName)
- void stopService(String serviceName)
- void configureService(String serviceName, Map<String, dynamic> config)
```

#### **IRoutable**
For routers - manages routing tables.
```dart
- List<Map<String, dynamic>> routingTable
- void addStaticRoute(String destination, String mask, String gateway)
- void removeStaticRoute(String destination)
```

#### **ISwitchable**
For switches - manages MAC address tables and VLANs.
```dart
- List<Map<String, dynamic>> macAddressTable
- void clearMacAddressTable()
- void createVlan(int vlanId, String name)
- void assignPortToVlan(int portId, int vlanId)
```

#### **IFirewallEnabled**
For firewalls - manages security rules.
```dart
- String defaultPolicy // "ALLOW" | "DENY"
- List<Map<String, dynamic>> firewallRules
- void addRule(Map<String, dynamic> rule)
- void removeRule(String ruleId)
- void setDefaultPolicy(String policy)
```

#### **IWirelessEnabled**
For wireless access points.
```dart
- String ssid
- bool radioEnabled
- String securityMode
- void setSsid(String newSsid)
- void setSecurityMode(String mode, String? password)
- void enableRadio() / disableRadio()
```

## Device Entities

### Device 1: End Device (PC/Workstation)

**Capabilities**: `IPowerable`, `INetworkConfigurable`, `IConnectable`, `ITerminalAccessible`

**Key Properties**:
- hostname, macAddress, deviceId
- IP configuration (static or DHCP)
- Power state, link state
- Installed tools (ping, ipconfig, nslookup, traceroute)
- ARP cache

**Key Actions**:
- Power on/off
- Open terminal
- Configure IP (static/DHCP)
- Renew DHCP lease
- Run network tools

---

### Device 2: Server

**Capabilities**: All of End Device + `IServiceHost`

**Additional Properties**:
- Running services (DHCP, DNS, WEB)
- Service configurations

**Additional Actions**:
- Start/stop services
- Configure service parameters

**Service Types**:
1. **DHCP Service**: Pool configuration, lease management
2. **DNS Service**: Zone file, A records, CNAME records
3. **WEB Service**: Port, status message

---

### Device 3: Switch (Layer 2)

**Capabilities**: `IPowerable`, `ISwitchable`, `IConfigurable`

**Key Properties**:
- Port count, port states
- MAC address table
- VLAN database (if managed)
- Port-to-VLAN assignments

**Key Actions**:
- Power on/off/reboot
- Clear MAC address table
- Create/delete VLANs
- Assign ports to VLANs

---

### Device 4: Router (Layer 3)

**Capabilities**: `IPowerable`, `IRoutable`, `IServiceHost`, `IConfigurable`

**Key Properties**:
- Interfaces (LAN, WAN, etc.)
- Routing table
- NAT enabled/disabled
- DHCP service enabled/disabled
- Firewall enabled/disabled

**Key Actions**:
- Power on/off/reboot
- Configure interfaces
- Add/remove static routes
- Enable/disable NAT
- Enable/disable services

---

### Device 5: Firewall

**Capabilities**: `IPowerable`, `IFirewallEnabled`, `IConfigurable`

**Key Properties**:
- Interfaces (INSIDE, OUTSIDE)
- Default policy (ALLOW/DENY)
- Firewall rules (ordered list)
- Traffic log

**Key Actions**:
- Power on/off/reboot
- Add/edit/delete rules
- Move rules up/down (order matters!)
- Enable/disable rules
- Set default policy
- View traffic log

---

### Device 6: Wireless Access Point (WAP)

**Capabilities**: `IPowerable`, `IWirelessEnabled`, `INetworkConfigurable`, `IConfigurable`

**Key Properties**:
- SSID, broadcast SSID
- Security mode (OPEN, WPA2)
- WPA password
- Channel (Auto, 1, 6, 11)
- Radio enabled/disabled
- Connected clients
- Uplink state

**Key Actions**:
- Power on/off/reboot
- Configure SSID/security
- Enable/disable radio
- Set channel
- View connected clients
- Kick client

## Property System

Properties are self-describing and can render their own UI widgets.

### Property Types

1. **StringProperty**: Simple text fields
2. **IpAddressProperty**: IP address inputs with validation
3. **MacAddressProperty**: Read-only MAC addresses
4. **BooleanProperty**: Switch/toggle inputs
5. **SelectionProperty**: Dropdown selections
6. **StatusProperty**: Colored status indicators
7. **IntegerProperty**: Number inputs with optional min/max

### Example

```dart
IpAddressProperty(
  id: 'currentIp',
  label: 'IP Address',
  value: '192.168.1.10',
  isReadOnly: false, // Can be edited
)
```

## Actions System

Actions are executable operations that appear in the device context menu and details panel.

```dart
DeviceAction(
  id: 'power_toggle',
  label: 'Power Off',
  icon: Icons.power_settings_new,
  onExecute: () => device.powerOff(),
  isEnabled: true,
)
```

## Usage in Game View

When a device is clicked:

```dart
// Show device details panel
showModalBottomSheet(
  context: context,
  builder: (context) => DeviceDetailsPanel(
    device: selectedDevice, // NetworkDevice instance
    onClose: () => Navigator.pop(context),
  ),
);
```

The panel automatically displays:
- **Device header** with icon, name, type, and status
- **Properties section** with all device properties
- **Actions section** with executable actions as chips
- **Capabilities section** showing what the device can do

## Benefits of This Architecture

### 1. **Scalability**
- Add new device types by implementing existing interfaces
- Add new capabilities without touching existing devices
- Properties and actions are self-contained

### 2. **Maintainability**
- Each capability is defined once, used by multiple devices
- Clear separation between business logic and UI
- Easy to test individual capabilities

### 3. **Flexibility**
- Devices can gain/lose capabilities at runtime
- Custom property types can be added
- UI automatically adapts to device capabilities

### 4. **Reusability**
- Capability interfaces can be shared across device types
- Property system works for any device
- Action system is device-agnostic

## Example: Adding a New Device Type

```dart
class LoadBalancer extends NetworkDevice
    implements IPowerable, IRoutable, IConfigurable {
  
  // Implement required properties
  @override
  List<DeviceProperty> get properties => [...];
  
  // Implement capability methods
  @override
  void powerOn() { ... }
  
  @override
  List<Map<String, dynamic>> get routingTable => [...];
  
  // Define available actions
  @override
  List<DeviceAction> getAvailableActions() => [...];
}
```

That's it! The UI automatically knows how to display and interact with this new device.

## Migration Path

The old `CanvasDevice` model still exists for backward compatibility. Over time:

1. **Phase 1**: New devices use `NetworkDevice` architecture ✅
2. **Phase 2**: Update `CanvasProvider` to work with `NetworkDevice`
3. **Phase 3**: Migrate existing canvas widgets
4. **Phase 4**: Deprecate old `CanvasDevice` model

## Next Steps

- [ ] Integrate `NetworkDevice` with `CanvasProvider`
- [ ] Update `CanvasDeviceWidget` to use `DeviceDetailsPanel`
- [ ] Add device factory for creating devices from palette
- [ ] Implement simulation engine to handle device interactions
- [ ] Add save/load functionality for device configurations

