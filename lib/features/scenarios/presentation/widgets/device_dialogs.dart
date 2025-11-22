import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/switch_device.dart';

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
