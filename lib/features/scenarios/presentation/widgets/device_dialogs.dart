import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/switch_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/router_device.dart';

/// Dialog to show ARP cache for EndDevice
class ArpCacheDialog extends StatelessWidget {
  final EndDevice device;

  const ArpCacheDialog({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${device.displayName} - ARP Cache'),
      content: device.arpCache.isEmpty
          ? const Text('ARP cache is empty')
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: device.arpCache.length,
                itemBuilder: (context, index) {
                  final entry = device.arpCache[index];
                  return ListTile(
                    leading: const Icon(Icons.network_check),
                    title: Text('IP: ${entry['ip']}'),
                    subtitle: Text('MAC: ${entry['mac']}'),
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Dialog to show CAM table for SwitchDevice
class CamTableDialog extends StatelessWidget {
  final SwitchDevice device;

  const CamTableDialog({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${device.displayName} - CAM Table'),
      content: device.macAddressTable.isEmpty
          ? const Text('CAM table is empty')
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: device.macAddressTable.length,
                itemBuilder: (context, index) {
                  final entry = device.macAddressTable[index];
                  return ListTile(
                    leading: const Icon(Icons.router),
                    title: Text('MAC: ${entry['macAddress']}'),
                    subtitle: Text('Port: ${entry['portId']}'),
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Dialog to configure switch ports (read-only for now)
class PortConfigurationDialog extends ConsumerWidget {
  final SwitchDevice device;
  final Function(SwitchDevice) onUpdate;

  const PortConfigurationDialog({
    super.key,
    required this.device,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Port Configuration'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Text(
              'Total Ports: ${device.portCount}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: device.ports.length,
                itemBuilder: (context, index) {
                  final port = device.ports[index];
                  final portNumber = index + 1;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        Icons.settings_input_component,
                        color: port.isEnabled ? Colors.green : Colors.grey,
                      ),
                      title: Text('Port $portNumber'),
                      subtitle: Text(port.isEnabled ? 'Enabled' : 'Disabled'),
                      trailing: Icon(
                        port.isEnabled ? Icons.check_circle : Icons.cancel,
                        color: port.isEnabled ? Colors.green : Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Dialog to adjust port count for switch
class PortCountDialog extends StatefulWidget {
  final SwitchDevice device;
  final Function(int) onUpdate;

  const PortCountDialog({
    super.key,
    required this.device,
    required this.onUpdate,
  });

  @override
  State<PortCountDialog> createState() => _PortCountDialogState();
}

class _PortCountDialogState extends State<PortCountDialog> {
  late int portCount;

  @override
  void initState() {
    super.initState();
    portCount = widget.device.portCount;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Port Count'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Current: ${widget.device.portCount} ports'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: portCount > 3
                    ? () => setState(() => portCount--)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$portCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: portCount < 12
                    ? () => setState(() => portCount++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Range: 3-12 ports',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onUpdate(portCount);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Dialog to view router interfaces with detailed information
class RouterInterfacesDialog extends StatelessWidget {
  final RouterDevice router;

  const RouterInterfacesDialog({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${router.displayName} - Interfaces'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: router.interfaces.isEmpty
            ? const Center(child: Text('No interfaces configured'))
            : ListView.builder(
                itemCount: router.interfaces.length,
                itemBuilder: (context, index) {
                  final iface = router.interfaces.values.elementAt(index);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ExpansionTile(
                      leading: Icon(
                        Icons.settings_ethernet,
                        color: iface.isOperational ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        iface.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${iface.ipAddress}/${iface.subnetMask}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                'Status',
                                iface.status
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase(),
                              ),
                              _buildInfoRow('Link State', iface.linkState),
                              _buildInfoRow('IP Address', iface.ipAddress),
                              _buildInfoRow('Subnet Mask', iface.subnetMask),
                              _buildInfoRow('MAC Address', iface.macAddress),
                              _buildInfoRow(
                                'ARP Cache',
                                '${iface.arpCache.length} entries',
                              ),
                              _buildInfoRow(
                                'Operational',
                                iface.isOperational ? 'YES' : 'NO',
                              ),
                              if (iface.connectedLinkId != null)
                                _buildInfoRow('Connection', 'Connected'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

/// Dialog to view ARP cache for a specific router interface
class RouterArpCacheDialog extends StatelessWidget {
  final RouterDevice router;
  final String interfaceName;

  const RouterArpCacheDialog({
    super.key,
    required this.router,
    required this.interfaceName,
  });

  @override
  Widget build(BuildContext context) {
    final iface = router.interfaces[interfaceName];

    if (iface == null) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text('Interface $interfaceName not found'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('${router.displayName} - $interfaceName ARP Cache'),
      content: iface.arpCache.isEmpty
          ? const Text('ARP cache is empty')
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: iface.arpCache.length,
                itemBuilder: (context, index) {
                  final entry = iface.arpCache.entries.elementAt(index);
                  return ListTile(
                    leading: const Icon(
                      Icons.network_check,
                      color: Colors.blue,
                    ),
                    title: Text('IP: ${entry.key}'),
                    subtitle: Text('MAC: ${entry.value}'),
                  );
                },
              ),
            ),
      actions: [
        if (iface.arpCache.isNotEmpty)
          TextButton(
            onPressed: () {
              iface.arpCache.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cleared ARP cache for $interfaceName')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Cache'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Dialog to view router routing table
class RoutingTableDialog extends StatelessWidget {
  final RouterDevice router;

  const RoutingTableDialog({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final routes = router.routingTable;

    return AlertDialog(
      title: Text('${router.displayName} - Routing Table'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: routes.isEmpty
            ? const Center(child: Text('Routing table is empty'))
            : ListView.builder(
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final route = routes[index];
                  final dest = route['destinationNetwork'] ?? 'N/A';
                  final mask = route['subnetMask'] ?? 'N/A';
                  final gateway = route['gateway'] ?? 'Direct';
                  final iface = route['interfaceName'] ?? 'N/A';
                  final metric = route['metric'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        gateway == 'Direct' ? Icons.lan : Icons.arrow_forward,
                        color: gateway == 'Direct' ? Colors.green : Colors.blue,
                      ),
                      title: Text('$dest/$mask'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gateway: $gateway'),
                          Text('Interface: $iface (Metric: $metric)'),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Dialog to add static route to router
class AddStaticRouteDialog extends StatefulWidget {
  final RouterDevice router;
  final VoidCallback onRouteAdded;

  const AddStaticRouteDialog({
    super.key,
    required this.router,
    required this.onRouteAdded,
  });

  @override
  State<AddStaticRouteDialog> createState() => _AddStaticRouteDialogState();
}

class _AddStaticRouteDialogState extends State<AddStaticRouteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _destNetworkController = TextEditingController();
  final _subnetMaskController = TextEditingController();
  final _gatewayController = TextEditingController();

  @override
  void dispose() {
    _destNetworkController.dispose();
    _subnetMaskController.dispose();
    _gatewayController.dispose();
    super.dispose();
  }

  String? _validateIp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final parts = value.split('.');
    if (parts.length != 4) {
      return 'Invalid IP format';
    }
    for (var part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return 'Invalid IP octet';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Static Route'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Destination Network',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _destNetworkController,
                decoration: const InputDecoration(
                  hintText: 'e.g., 10.0.0.0',
                  border: OutlineInputBorder(),
                ),
                validator: _validateIp,
              ),
              const SizedBox(height: 16),
              const Text(
                'Subnet Mask',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subnetMaskController,
                decoration: const InputDecoration(
                  hintText: 'e.g., 255.255.255.0',
                  border: OutlineInputBorder(),
                ),
                validator: _validateIp,
              ),
              const SizedBox(height: 16),
              const Text(
                'Gateway IP',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _gatewayController,
                decoration: const InputDecoration(
                  hintText: 'e.g., 192.168.1.1',
                  border: OutlineInputBorder(),
                ),
                validator: _validateIp,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gateway must be reachable via one of the router\'s interfaces',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              try {
                widget.router.addStaticRoute(
                  _destNetworkController.text,
                  _subnetMaskController.text,
                  _gatewayController.text,
                );
                widget.onRouteAdded();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Static route added successfully'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
          child: const Text('Add Route'),
        ),
      ],
    );
  }
}

/// Dialog to configure router interface IP
class ConfigureInterfaceDialog extends StatefulWidget {
  final RouterDevice router;
  final String interfaceName;
  final VoidCallback onConfigured;

  const ConfigureInterfaceDialog({
    super.key,
    required this.router,
    required this.interfaceName,
    required this.onConfigured,
  });

  @override
  State<ConfigureInterfaceDialog> createState() =>
      _ConfigureInterfaceDialogState();
}

class _ConfigureInterfaceDialogState extends State<ConfigureInterfaceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ipController;
  late TextEditingController _maskController;

  @override
  void initState() {
    super.initState();
    final iface = widget.router.interfaces[widget.interfaceName];
    _ipController = TextEditingController(text: iface?.ipAddress ?? '');
    _maskController = TextEditingController(text: iface?.subnetMask ?? '');
  }

  @override
  void dispose() {
    _ipController.dispose();
    _maskController.dispose();
    super.dispose();
  }

  String? _validateIp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final parts = value.split('.');
    if (parts.length != 4) {
      return 'Invalid IP format';
    }
    for (var part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return 'Invalid IP octet';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Configure ${widget.interfaceName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                border: OutlineInputBorder(),
              ),
              validator: _validateIp,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maskController,
              decoration: const InputDecoration(
                labelText: 'Subnet Mask',
                border: OutlineInputBorder(),
              ),
              validator: _validateIp,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.router.setInterfaceIp(
                widget.interfaceName,
                _ipController.text,
                _maskController.text,
              );
              widget.onConfigured();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${widget.interfaceName} configured successfully',
                  ),
                ),
              );
            }
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Dialog to view EndDevice routing table and interface details
class EndDeviceNetworkInfoDialog extends StatelessWidget {
  final EndDevice device;

  const EndDeviceNetworkInfoDialog({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AlertDialog(
        title: Text('${device.displayName} - Network Info'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Interface'),
                  Tab(text: 'Routes'),
                  Tab(text: 'ARP Cache'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInterfaceTab(),
                    _buildRoutesTab(),
                    _buildArpCacheTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceTab() {
    if (device.interfaces.isEmpty) {
      return const Center(child: Text('No interfaces configured'));
    }

    final iface = device.interfaces.first;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard('Name', iface.name),
        _buildInfoCard(
          'Status',
          iface.status.toString().split('.').last.toUpperCase(),
        ),
        _buildInfoCard('MAC Address', iface.macAddress),
        _buildInfoCard('IP Address', iface.ipAddress ?? 'Not assigned'),
        _buildInfoCard('Subnet Mask', iface.subnetMask ?? 'Not assigned'),
        _buildInfoCard('Default Gateway', iface.defaultGateway ?? 'Not set'),
      ],
    );
  }

  Widget _buildRoutesTab() {
    if (device.routingTable.entries.isEmpty) {
      return const Center(child: Text('No routing entries'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: device.routingTable.entries.length,
      itemBuilder: (context, index) {
        final route = device.routingTable.entries[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.arrow_forward, color: Colors.blue),
            title: Text('${route.destinationNetwork}/${route.subnetMask}'),
            subtitle: Text(
              'Gateway: ${route.gateway ?? "Direct"}\nInterface: ${route.interfaceName}',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildArpCacheTab() {
    // For EndDevice, arpCache is at device level, not interface level
    final arpCacheList = device.arpCache;

    if (arpCacheList.isEmpty) {
      return const Center(child: Text('ARP cache is empty'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: arpCacheList.length,
      itemBuilder: (context, index) {
        final entry = arpCacheList[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.network_check, color: Colors.green),
            title: Text('IP: ${entry['ip']}'),
            subtitle: Text('MAC: ${entry['mac']}'),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Flexible(
              child: Text(
                value,
                style: TextStyle(color: Colors.grey.shade700),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
