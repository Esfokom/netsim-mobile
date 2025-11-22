# 📋 PHASE 3 IMPLEMENTATION PLAN - ADVANCED ROUTING & ROUTER DEVICE

**Date:** November 22, 2024  
**Status:** 🎯 **READY TO START**  
**Prerequisites:** ✅ Phase 2 Complete (Interfaces, ARP, ICMP, Switch)

---

## 🎯 PHASE 3 OBJECTIVES

Build on the successful Phase 2 implementation to add:
1. **Router Device** with multiple interfaces
2. **Cross-subnet routing** (gateway forwarding)
3. **Advanced routing table** management
4. **Multiple network segments**
5. **Router protocols** (static routing, default gateway)

---

## 📊 CURRENT STATE ANALYSIS

### ✅ **Already Implemented (Phase 2):**
```
✅ EndDevice:
   - Single interface (eth0)
   - Routing table with longest prefix match
   - ARP cache
   - Interface status management
   - Static IP configuration
   - ICMP echo request/reply
   
✅ SwitchDevice:
   - Multiple ports (3-12)
   - CAM table (MAC learning)
   - Port status management
   - Port connection/disconnection ✅ (Just fixed!)
   - Broadcasting/flooding
   - Unicast forwarding
   - VLAN support (basic)

✅ Simulation Engine:
   - Packet routing
   - Event emission
   - Packet animations
   - Timing management

✅ Canvas System:
   - Connection initialization
   - Link management
   - Device lifecycle
```

### ⏳ **Needs Implementation:**
```
⏳ RouterDevice:
   - Multiple interfaces (NOT just single eth0)
   - Per-interface IP configuration
   - Inter-subnet routing
   - Routing table with next-hop gateway
   - Packet forwarding between subnets
   - TTL decrement
   - ICMP redirect (optional)

⏳ Advanced Routing:
   - Static routes
   - Default gateway (0.0.0.0/0)
   - Route priority/metrics
   - Multiple routes to same destination
   
⏳ Network Architecture:
   - Multiple network segments
   - Gateway configuration on end devices
   - Cross-subnet communication
```

---

## 🗂️ PHASE 3 BREAKDOWN

### **PHASE 3.1 - Router Device Foundation** 🎯

#### **Goal:** Create RouterDevice with multiple interfaces

**Tasks:**
1. Create `RouterDevice` class extending `NetworkDevice`
2. Implement multiple interface support (2-4 interfaces initially)
3. Per-interface configuration:
   - IP address
   - Subnet mask
   - Interface name (eth0, eth1, eth2, etc.)
   - Status (UP/DOWN)
4. Visual representation (router icon, different color)
5. Router-specific properties panel

**Files to Create/Modify:**
- `lib/features/devices/domain/entities/router_device.dart` (CREATE)
- Update `DeviceFactory` to handle router creation
- Update canvas to support router devices

**Acceptance Criteria:**
- [ ] RouterDevice class created
- [ ] Can configure 2+ interfaces with different IPs
- [ ] Each interface has independent status
- [ ] Router appears on canvas with correct icon
- [ ] Properties panel shows all interfaces

---

### **PHASE 3.2 - Routing Table Enhancement** 🎯

#### **Goal:** Upgrade routing table to support gateways and multiple routes

**Current Routing Table:**
```dart
class RoutingEntry {
  final String destinationNetwork;
  final String subnetMask;
  final String? gateway;  // Currently only null (direct)
  final String interfaceName;
}
```

**Enhanced Routing Table:**
```dart
class RoutingEntry {
  final String destinationNetwork;
  final String subnetMask;
  final String? gateway;        // ✅ Now supports actual gateway IPs
  final String interfaceName;
  final int metric;             // NEW: Route priority
  final String routeType;       // NEW: 'direct', 'static', 'default'
  final bool isActive;          // NEW: Route status
}
```

**Tasks:**
1. Update `RoutingEntry` class with new fields
2. Implement routing table lookup with metric consideration
3. Support default route (0.0.0.0/0)
4. Add route validation
5. Update routing logic in `EndDevice` and `RouterDevice`

**Acceptance Criteria:**
- [ ] Routing table supports gateway routes
- [ ] Default gateway (0.0.0.0/0) working
- [ ] Route metrics honored (lower = better)
- [ ] Longest prefix match considers metrics

---

### **PHASE 3.3 - Packet Forwarding Logic** 🎯

#### **Goal:** Implement proper packet forwarding through routers

**Current Behavior:**
```
PC1 (192.168.1.10) → Switch → PC2 (192.168.1.11)
✅ Works - same subnet
```

**Target Behavior:**
```
PC1 (192.168.1.10) → Router (192.168.1.1 / 192.168.2.1) → PC2 (192.168.2.10)
✅ Should work - cross-subnet via router
```

**Implementation Steps:**

1. **Router Packet Handling:**
   ```dart
   void handlePacket(Packet packet, String incomingInterface, SimulationEngine engine) {
     // 1. Check if packet is for router itself
     if (isPacketForMe(packet.destinationIp)) {
       handleLocalPacket(packet);
       return;
     }
     
     // 2. Decrement TTL
     packet.ttl--;
     if (packet.ttl <= 0) {
       sendIcmpTimeExceeded(packet);
       return;
     }
     
     // 3. Look up route
     final route = routingTable.findRoute(packet.destinationIp);
     if (route == null) {
       sendIcmpDestUnreachable(packet);
       return;
     }
     
     // 4. Determine next hop
     final nextHopIp = route.gateway ?? packet.destinationIp;
     final outputInterface = getInterface(route.interfaceName);
     
     // 5. Resolve next-hop MAC (or ARP)
     final nextHopMac = outputInterface.arpCache[nextHopIp];
     if (nextHopMac == null) {
       sendArpRequest(nextHopIp, outputInterface);
       queuePacket(packet);
       return;
     }
     
     // 6. Forward packet
     forwardPacket(packet, outputInterface, nextHopMac, engine);
   }
   ```

2. **ARP on Each Interface:**
   - Each interface has its own ARP cache
   - ARP requests sent on specific interfaces
   - ARP replies update correct interface cache

3. **Packet TTL Management:**
   - Initialize TTL to 64 in `Packet` class
   - Decrement at each router hop
   - Send ICMP Time Exceeded if TTL hits 0

**Acceptance Criteria:**
- [ ] Router forwards packets between subnets
- [ ] TTL decremented at each hop
- [ ] ARP works per-interface
- [ ] ICMP errors sent appropriately

---

### **PHASE 3.4 - End Device Gateway Configuration** 🎯

#### **Goal:** Allow end devices to use a gateway for remote networks

**Current State:**
```dart
// EndDevice routing table only has direct routes
routingTable.add(RoutingEntry(
  destinationNetwork: '192.168.1.0',
  subnetMask: '255.255.255.0',
  gateway: null,  // Always null!
  interfaceName: 'eth0',
));
```

**Target State:**
```dart
// EndDevice can have default gateway
routingTable.addAll([
  // Direct route
  RoutingEntry(
    destinationNetwork: '192.168.1.0',
    subnetMask: '255.255.255.0',
    gateway: null,
    interfaceName: 'eth0',
    routeType: 'direct',
  ),
  // Default gateway
  RoutingEntry(
    destinationNetwork: '0.0.0.0',
    subnetMask: '0.0.0.0',
    gateway: '192.168.1.1',  // Router!
    interfaceName: 'eth0',
    routeType: 'default',
  ),
]);
```

**Implementation:**
1. Add "Default Gateway" field to EndDevice properties
2. Auto-create default route when gateway is set
3. Update routing logic to use gateway for remote destinations
4. UI for setting gateway in device properties

**Acceptance Criteria:**
- [ ] Can configure default gateway on PC
- [ ] Default route (0.0.0.0/0) created automatically
- [ ] Packets to remote subnets use gateway
- [ ] ARP resolves gateway MAC, not destination MAC

---

### **PHASE 3.5 - Multi-Subnet Topology Testing** 🎯

#### **Goal:** Test complete cross-subnet communication

**Test Topology:**
```
[PC1]           [Router]           [PC2]
192.168.1.10 ←→ 192.168.1.1 | 192.168.2.1 ←→ 192.168.2.10
                   eth0     |    eth1
                 
                 Switch1         Switch2
```

**Test Scenarios:**

1. **Direct Communication (Same Subnet):**
   - PC1 → PC2 (both on 192.168.1.0/24)
   - Should work without router

2. **Gateway Communication (Cross-Subnet):**
   - PC1 (192.168.1.10) → PC2 (192.168.2.10)
   - Must go through router

3. **Return Path:**
   - PC2 → PC1 (reply must route back)

4. **ARP on Each Segment:**
   - PC1 ARPs for router (192.168.1.1)
   - Router ARPs for PC2 on eth1 (192.168.2.10)

**Acceptance Criteria:**
- [ ] Same-subnet ping works (Phase 2 test)
- [ ] Cross-subnet ping works
- [ ] Packet animation shows path through router
- [ ] ARP happens on each network segment
- [ ] MAC addresses rewritten at router

---

## 📝 DETAILED IMPLEMENTATION TASKS

### **Task 3.1.1: Create RouterDevice Class**

**File:** `lib/features/devices/domain/entities/router_device.dart`

```dart
class RouterDevice extends NetworkDevice implements IRoutable, IPowerable {
  String name;
  bool _isPoweredOn;
  
  // Multiple interfaces (key = interface name)
  final Map<String, RouterInterface> interfaces;
  
  // Routing table (shared across all interfaces)
  final List<RoutingEntry> routingTable;
  
  RouterDevice({
    required super.deviceId,
    required super.position,
    String? name,
    bool isPoweredOn = true,
    int interfaceCount = 2,
  }) : name = name ?? deviceId,
       _isPoweredOn = isPoweredOn,
       interfaces = {},
       routingTable = [],
       super(deviceType: 'Router') {
    // Initialize interfaces
    for (int i = 0; i < interfaceCount; i++) {
      final ifName = 'eth$i';
      interfaces[ifName] = RouterInterface(
        name: ifName,
        status: InterfaceStatus.down,
      );
    }
  }
  
  // ... implementation
}

class RouterInterface {
  final String name;
  String? ipAddress;
  String? subnetMask;
  InterfaceStatus status;
  String linkState; // 'UP' or 'DOWN'
  final Map<String, String> arpCache; // IP → MAC
  
  RouterInterface({
    required this.name,
    this.ipAddress,
    this.subnetMask,
    this.status = InterfaceStatus.down,
    this.linkState = 'DOWN',
  }) : arpCache = {};
  
  bool get isOperational => 
    linkState == 'UP' && 
    status == InterfaceStatus.up && 
    ipAddress != null;
}
```

---

### **Task 3.2.1: Update Packet Class with TTL**

**File:** `lib/features/simulation/domain/entities/packet.dart`

```dart
class Packet {
  // ...existing fields...
  int ttl;  // NEW: Time To Live
  
  Packet({
    // ...existing parameters...
    this.ttl = 64,  // Default TTL
  });
  
  // Add method to decrement TTL
  void decrementTtl() {
    if (ttl > 0) ttl--;
  }
}
```

---

### **Task 3.3.1: Implement Router Forwarding Logic**

**Location:** `RouterDevice.handlePacket()`

**Pseudocode:**
```
1. Receive packet on interface X
2. Check if destination IP is router's IP on any interface
   - If yes: process locally (ICMP reply, etc.)
   - If no: continue to step 3
3. Decrement TTL
   - If TTL == 0: send ICMP Time Exceeded
4. Look up destination in routing table
   - If no route: send ICMP Destination Unreachable
5. Determine output interface from route
6. Determine next-hop IP:
   - If gateway != null: next-hop = gateway
   - Else: next-hop = destination IP
7. Look up next-hop MAC in output interface's ARP cache
   - If not found: send ARP request, queue packet
8. Rewrite Ethernet frame:
   - Source MAC = output interface MAC
   - Dest MAC = next-hop MAC
9. Forward packet on output interface
```

---

## 🧪 TESTING STRATEGY

### **Phase 3 Tests:**

**Test 1: Router Creation** ⏳
- Create router with 2 interfaces
- Configure IP on each interface
- Verify interfaces operational

**Test 2: Static Route** ⏳
- Add static route to router
- Verify route in table
- Check longest prefix match

**Test 3: Cross-Subnet Ping** ⏳
- PC1 (subnet A) → Router → PC2 (subnet B)
- Verify ARP on both segments
- Verify packet forwarded
- Verify reply returns

**Test 4: Default Gateway** ⏳
- PC configured with default gateway
- Ping remote host
- Verify uses gateway

**Test 5: TTL Decrement** ⏳
- Send packet through multiple routers
- Verify TTL decrements
- Verify ICMP Time Exceeded when TTL = 0

---

## 📈 IMPLEMENTATION ORDER

```
Week 1:
  ✅ Fix switch port disconnection (DONE!)
  ⏳ Phase 3.1: RouterDevice foundation
  ⏳ Phase 3.2: Routing table enhancement

Week 2:
  ⏳ Phase 3.3: Packet forwarding logic
  ⏳ Phase 3.4: End device gateway config

Week 3:
  ⏳ Phase 3.5: Testing & refinement
  ⏳ Documentation updates
```

---

## ✅ SUCCESS CRITERIA

**Phase 3 Complete When:**
- [ ] RouterDevice fully implemented
- [ ] Multiple interfaces per router
- [ ] Cross-subnet routing works
- [ ] Default gateway functional
- [ ] TTL management working
- [ ] ARP per-interface
- [ ] All Phase 3 tests passing
- [ ] Documentation complete

---

## 🎯 PHASE 4 PREVIEW (Future)

**After Phase 3:**
- Dynamic routing protocols (RIP, OSPF basic)
- NAT/PAT (Network Address Translation)
- Firewall rules
- ACLs (Access Control Lists)
- Load balancing
- Redundancy (HSRP/VRRP)

---

**Prepared by:** AI Assistant  
**Date:** November 22, 2024  
**Status:** 🎯 **Ready to Start After Port Disconnect Fix**  

**Next Action:** Begin Phase 3.1 - RouterDevice Foundation

