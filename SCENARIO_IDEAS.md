# NetSim Mobile - Scenario Ideas

This document contains scenario ideas organized by difficulty level. Each scenario includes:
- **Title**: The scenario name
- **Description**: What the player needs to accomplish
- **Conditions**: Detailed breakdown of success conditions and how to configure them

---

## 🟢 EASY SCENARIOS

### 1. First Ping
**Title:** First Ping

**Description:** Learn the basics of network communication! Configure Computer 1 to successfully ping Computer 2 through the switch.

**Network Setup:**
- Computer 1 ↔ Switch 1 ↔ Computer 2

**Pre-configured:**
- Computer 1: IP 192.168.1.10/24
- Computer 2: IP 192.168.1.20/24
- All devices connected via switch

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Ping from Computer 1 to Computer 2 must succeed | Ping | **Check Type:** Success<br>**Source Device:** Computer 1<br>**Source Interface:** eth0<br>**Dest Device:** Computer 2<br>**Dest Interface:** eth0 |

---

### 2. Power Up the Network
**Title:** Power Up the Network

**Description:** The server is offline! Power it on to complete the objective.

**Network Setup:**
- Computer 1 ↔ Switch 1 ↔ Server 1 (powered off)

**Pre-configured:**
- Server 1 is powered OFF initially

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Server 1 must be powered on | Device Property | **Device:** Server 1<br>**Property:** Power<br>**Data Type:** String<br>**Operator:** Equals<br>**Expected Value:** ON |

---

### 3. Connect the Missing Link
**Title:** Connect the Missing Link

**Description:** Computer 2 is disconnected from the network. Connect it to the switch to restore connectivity.

**Network Setup:**
- Computer 1 ↔ Switch 1
- Computer 2 (not connected)

**Pre-configured:**
- Computer 2 has no link to switch

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Computer 2 must be connected to Switch 1 | Link Check | **Mode:** Boolean Link Status<br>**Source Device:** Computer 2<br>**Target Device:** Switch 1<br>**Expected Value:** true |

---

### 4. Set the IP Address
**Title:** Set the IP Address

**Description:** Computer 1 needs an IP address to communicate. Assign it the IP 192.168.1.100.

**Network Setup:**
- Computer 1 ↔ Switch 1 ↔ Computer 2

**Pre-configured:**
- Computer 1: No IP assigned
- Computer 2: IP 192.168.1.20/24

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Computer 1 must have IP 192.168.1.100 | Device Property | **Device:** Computer 1<br>**Property:** IP Address<br>**Data Type:** IP Address<br>**Operator:** Equals<br>**Expected Value:** 192.168.1.100 |

---

## 🟡 MEDIUM SCENARIOS

### 5. Fast Response Required
**Title:** Fast Response Required

**Description:** The network must be fast! Ensure ping response time from Computer 1 to Server 1 is less than 100ms.

**Network Setup:**
- Computer 1 ↔ Switch 1 ↔ Server 1

**Pre-configured:**
- All devices have IPs configured

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Ping response time must be less than 100ms | Ping | **Check Type:** Response Time<br>**Operator:** Less Than<br>**Threshold:** 100 (ms)<br>**Source Device:** Computer 1<br>**Source Interface:** eth0<br>**Dest Device:** Server 1<br>**Dest Interface:** eth0 |

---

### 6. Network Expansion
**Title:** Network Expansion

**Description:** Add Computer 3 to the network and ensure it can communicate with the server.

**Network Setup:**
- Computer 1 ↔ Switch 1 ↔ Server 1
- Computer 3 (available but not connected)

**Pre-configured:**
- Computer 1: IP 192.168.1.10/24
- Server 1: IP 192.168.1.1/24
- Computer 3: IP 192.168.1.30/24 (not connected)

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Computer 3 must be connected to Switch 1 | Link Check | **Mode:** Boolean Link Status<br>**Source Device:** Computer 3<br>**Target Device:** Switch 1<br>**Expected Value:** true |
| 2 | Ping from Computer 3 to Server 1 must succeed | Ping | **Check Type:** Success<br>**Source Device:** Computer 3<br>**Source Interface:** eth0<br>**Dest Device:** Server 1<br>**Dest Interface:** eth0 |

---

### 7. Subnet Configuration
**Title:** Subnet Configuration

**Description:** Configure Computer 2 with the correct subnet mask (255.255.255.0) to communicate with the network.

**Network Setup:**
- Computer 1 ↔ Switch 1 ↔ Computer 2

**Pre-configured:**
- Computer 1: IP 192.168.1.10/24
- Computer 2: IP 192.168.1.20 (wrong subnet mask 255.255.0.0)

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Computer 2 must have correct subnet mask | Device Property | **Device:** Computer 2<br>**Property:** Subnet Mask<br>**Data Type:** IP Address<br>**Operator:** Equals<br>**Expected Value:** 255.255.255.0 |
| 2 | Ping must succeed after configuration | Ping | **Check Type:** Success<br>**Source Device:** Computer 1<br>**Source Interface:** eth0<br>**Dest Device:** Computer 2<br>**Dest Interface:** eth0 |

---

### 8. ARP Resolution Check
**Title:** ARP Resolution Check

**Description:** Verify that the ping process includes ARP resolution. Send a ping that requires ARP to discover the destination MAC address.

**Network Setup:**
- Computer 1 ↔ Switch 1 ↔ Computer 2

**Pre-configured:**
- Fresh network with empty ARP caches

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Ping session must include ARP resolution | Ping | **Check Type:** Has ARP<br>**Source Device:** Computer 1<br>**Source Interface:** eth0<br>**Dest Device:** Computer 2<br>**Dest Interface:** eth0 |
| 2 | Ping must complete successfully | Ping | **Check Type:** Success<br>**Source Device:** Computer 1<br>**Source Interface:** eth0<br>**Dest Device:** Computer 2<br>**Dest Interface:** eth0 |

---

### 9. Hub Topology
**Title:** Hub Topology

**Description:** Create a hub topology where the switch connects to exactly 3 computers.

**Network Setup:**
- Switch 1 (central)
- Computer 1, Computer 2, Computer 3 (available)

**Pre-configured:**
- Switch 1 exists but no connections

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Switch 1 must have exactly 3 connections | Link Check | **Mode:** Link Count<br>**Device:** Switch 1<br>**Operator:** Equals<br>**Expected Value:** 3 |

---

### 10. Hostname Identity
**Title:** Hostname Identity

**Description:** Rename Computer 1 to "Workstation-A" for proper network identification.

**Network Setup:**
- Computer 1 ↔ Switch 1

**Pre-configured:**
- Computer 1 has default hostname

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Computer 1 hostname must be "Workstation-A" | Device Property | **Device:** Computer 1<br>**Property:** Hostname<br>**Data Type:** String<br>**Operator:** Equals<br>**Expected Value:** Workstation-A |

---

## 🔴 HARD SCENARIOS

### 11. Full Network Setup
**Title:** Full Network Setup

**Description:** Build a complete network from scratch! Connect all devices, assign IP addresses, and verify full connectivity.

**Network Setup:**
- Switch 1 (central hub)
- Computer 1, Computer 2, Server 1 (available, not connected)

**Pre-configured:**
- No connections, no IP addresses

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Computer 1 connected to Switch 1 | Link Check | **Mode:** Boolean Link Status<br>**Source Device:** Computer 1<br>**Target Device:** Switch 1<br>**Expected Value:** true |
| 2 | Computer 2 connected to Switch 1 | Link Check | **Mode:** Boolean Link Status<br>**Source Device:** Computer 2<br>**Target Device:** Switch 1<br>**Expected Value:** true |
| 3 | Server 1 connected to Switch 1 | Link Check | **Mode:** Boolean Link Status<br>**Source Device:** Server 1<br>**Target Device:** Switch 1<br>**Expected Value:** true |
| 4 | Computer 1 has valid IP | Device Property | **Device:** Computer 1<br>**Property:** IP Address<br>**Data Type:** IP Address<br>**Operator:** Not Equals<br>**Expected Value:** Not assigned |
| 5 | Computer 2 has valid IP | Device Property | **Device:** Computer 2<br>**Property:** IP Address<br>**Data Type:** IP Address<br>**Operator:** Not Equals<br>**Expected Value:** Not assigned |
| 6 | Ping Computer 1 to Server 1 | Ping | **Check Type:** Success<br>**Source Device:** Computer 1<br>**Dest Device:** Server 1 |
| 7 | Ping Computer 2 to Server 1 | Ping | **Check Type:** Success<br>**Source Device:** Computer 2<br>**Dest Device:** Server 1 |

---

### 12. Troubleshoot the Network
**Title:** Troubleshoot the Network

**Description:** Something is wrong! The server is unreachable. Find and fix the issue. (Hint: Check power states and connections)

**Network Setup:**
- Computer 1 ↔ Switch 1 ↔ Server 1

**Pre-configured (with issues):**
- Server 1: Powered OFF
- OR missing link between Switch and Server

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Server 1 must be powered on | Device Property | **Device:** Server 1<br>**Property:** Power<br>**Data Type:** String<br>**Operator:** Equals<br>**Expected Value:** ON |
| 2 | Server 1 must be connected | Link Check | **Mode:** Boolean Link Status<br>**Source Device:** Server 1<br>**Target Device:** Switch 1<br>**Expected Value:** true |
| 3 | Ping must succeed | Ping | **Check Type:** Success<br>**Source Device:** Computer 1<br>**Dest Device:** Server 1 |

---

### 13. Multi-Path Verification
**Title:** Multi-Path Verification

**Description:** Set up a network where Computer 1 can ping both Computer 2 and Server 1 successfully.

**Network Setup:**
- Computer 1 ↔ Switch 1 ↔ Computer 2
-                    ↔ Server 1

**Pre-configured:**
- All IPs configured

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Ping from Computer 1 to Computer 2 | Ping | **Check Type:** Success<br>**Source Device:** Computer 1<br>**Dest Device:** Computer 2 |
| 2 | Ping from Computer 1 to Server 1 | Ping | **Check Type:** Success<br>**Source Device:** Computer 1<br>**Dest Device:** Server 1 |
| 3 | Ping from Computer 2 to Server 1 | Ping | **Check Type:** Success<br>**Source Device:** Computer 2<br>**Dest Device:** Server 1 |

---

### 14. Network Timeout Challenge
**Title:** Network Timeout Challenge

**Description:** Intentionally cause a ping timeout by misconfiguring the network, then fix it.

**Network Setup:**
- Computer 1 ↔ Switch 1 ↔ Computer 2

**Pre-configured:**
- Computer 1: IP 192.168.1.10/24
- Computer 2: IP 10.0.0.20/24 (different subnet - will timeout)

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Computer 2 IP must be in same subnet | Device Property | **Device:** Computer 2<br>**Property:** IP Address<br>**Data Type:** IP Address<br>**Operator:** Contains<br>**Expected Value:** 192.168.1 |
| 2 | Ping must not timeout | Ping | **Check Type:** Success<br>**Source Device:** Computer 1<br>**Dest Device:** Computer 2 |

---

### 15. ICMP Echo Verification
**Title:** ICMP Echo Verification

**Description:** Verify that a complete ICMP echo request/reply cycle occurs during the ping.

**Network Setup:**
- Computer 1 ↔ Switch 1 ↔ Server 1

**Pre-configured:**
- All devices configured

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Ping must contain ICMP packets | Ping | **Check Type:** Has ICMP<br>**Source Device:** Computer 1<br>**Dest Device:** Server 1 |
| 2 | Ping must succeed | Ping | **Check Type:** Success<br>**Source Device:** Computer 1<br>**Dest Device:** Server 1 |

---

## 🟣 EXPERT SCENARIOS

### 16. Performance Benchmark
**Title:** Performance Benchmark

**Description:** Ensure the network meets performance requirements: all pings must complete in under 50ms.

**Network Setup:**
- Computer 1 ↔ Switch 1 ↔ Computer 2
-                    ↔ Server 1

**Pre-configured:**
- All devices configured

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Ping to Computer 2 under 50ms | Ping | **Check Type:** Response Time<br>**Operator:** Less Than<br>**Threshold:** 50<br>**Source Device:** Computer 1<br>**Dest Device:** Computer 2 |
| 2 | Ping to Server 1 under 50ms | Ping | **Check Type:** Response Time<br>**Operator:** Less Than<br>**Threshold:** 50<br>**Source Device:** Computer 1<br>**Dest Device:** Server 1 |

---

### 17. Enterprise Network
**Title:** Enterprise Network

**Description:** Build an enterprise network with proper segmentation: 2 switches, each with 2 computers, connected to a central server.

**Network Setup:**
- Switch 1 ↔ Server 1 ↔ Switch 2
- Computer 1, Computer 2 → Switch 1
- Computer 3, Computer 4 → Switch 2

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1 | Switch 1 has 3 connections | Link Check | **Mode:** Link Count<br>**Device:** Switch 1<br>**Operator:** Equals<br>**Expected Value:** 3 |
| 2 | Switch 2 has 3 connections | Link Check | **Mode:** Link Count<br>**Device:** Switch 2<br>**Operator:** Equals<br>**Expected Value:** 3 |
| 3 | Computer 1 can ping Server | Ping | **Check Type:** Success<br>**Source Device:** Computer 1<br>**Dest Device:** Server 1 |
| 4 | Computer 3 can ping Server | Ping | **Check Type:** Success<br>**Source Device:** Computer 3<br>**Dest Device:** Server 1 |
| 5 | Cross-segment ping (C1 to C3) | Ping | **Check Type:** Success<br>**Source Device:** Computer 1<br>**Dest Device:** Computer 3 |

---

### 18. Complete Infrastructure
**Title:** Complete Infrastructure

**Description:** Deploy a complete network infrastructure with all devices online, properly connected, and fully communicating.

**Network Setup:**
- 1 Server (central)
- 2 Switches
- 4 Computers

**Success Conditions:**

| # | Description | Condition Type | Configuration |
|---|-------------|----------------|---------------|
| 1-6 | All devices powered on | Device Property | **Property:** Power, **Operator:** Equals, **Value:** ON |
| 7-12 | All connections verified | Link Check | **Mode:** Boolean Link Status |
| 13-16 | All computers ping server | Ping | **Check Type:** Success |
| 17-20 | All pings under 100ms | Ping | **Check Type:** Response Time, **Operator:** Less Than, **Threshold:** 100 |

---

## Condition Type Quick Reference

### Ping Condition
| Check Type | Description | Additional Fields |
|------------|-------------|-------------------|
| Success | Ping completed successfully (ICMP echo reply received) | Source/Dest device + interface |
| Timeout | Ping timed out | Source/Dest device + interface |
| Has ARP | Ping included ARP resolution | Source/Dest device + interface |
| Has ICMP | Ping included ICMP packets | Source/Dest device + interface |
| Response Time | Ping response time check | Operator (>/< ), Threshold (ms) |

### Device Property Condition
| Property | Data Type | Example Values |
|----------|-----------|----------------|
| Power | String | "ON", "OFF" |
| Hostname | String | "Server-1", "PC-01" |
| IP Address | IP Address | "192.168.1.100" |
| Subnet Mask | IP Address | "255.255.255.0" |
| Default Gateway | IP Address | "192.168.1.1" |
| IP Configuration | String | "STATIC", "DHCP" |

### Link Check Condition
| Mode | Description | Fields |
|------|-------------|--------|
| Boolean Link Status | Check if two devices are connected | Source Device, Target Device, Expected (true/false) |
| Link Count | Check number of connections | Device, Operator, Expected Count |

---

## Tips for Creating Scenarios

1. **Start Simple**: Begin with single-condition scenarios to teach concepts
2. **Progressive Difficulty**: Add more conditions as difficulty increases
3. **Real-World Relevance**: Model scenarios after real troubleshooting situations
4. **Clear Objectives**: Write descriptions that clearly state what needs to be done
5. **Measurable Success**: Each condition should be clearly verifiable
6. **Multiple Solutions**: When possible, allow different valid solutions

