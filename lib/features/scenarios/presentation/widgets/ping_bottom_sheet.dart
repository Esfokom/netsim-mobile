import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/router_device.dart';
import 'package:netsim_mobile/features/simulation/domain/services/simulation_engine.dart';

/// Compact bottom sheet for ping test functionality (200px height)
/// Supports both EndDevice and RouterDevice as source/destination
class CompactPingBottomSheet extends ConsumerStatefulWidget {
  const CompactPingBottomSheet({super.key});

  @override
  ConsumerState<CompactPingBottomSheet> createState() =>
      _CompactPingBottomSheetState();
}

class _CompactPingBottomSheetState
    extends ConsumerState<CompactPingBottomSheet> {
  String? selectedSourceId;
  String? selectedSourceIp;
  String? selectedDestId;
  String? selectedDestIp;
  bool isCustomDestIp = false;
  final TextEditingController _customIpController = TextEditingController();

  @override
  void dispose() {
    _customIpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPingEnabled =
        selectedSourceId != null &&
        selectedSourceIp != null &&
        (selectedDestIp != null || _customIpController.text.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Source Device Indicator
          Expanded(
            child: _buildDeviceIndicator(
              label: 'Source',
              deviceId: selectedSourceId,
              deviceIp: selectedSourceIp,
              onTap: () => _showDeviceSelectionDialog(context, isSource: true),
            ),
          ),
          const SizedBox(width: 12),
          // Arrow Icon
          Icon(
            Icons.arrow_forward,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          // Destination Device Indicator
          Expanded(
            child: _buildDeviceIndicator(
              label: 'Destination',
              deviceId: selectedDestId,
              deviceIp: selectedDestIp ?? _customIpController.text,
              onTap: () => _showDeviceSelectionDialog(context, isSource: false),
            ),
          ),
          const SizedBox(width: 12),
          // Ping Button
          ElevatedButton.icon(
            onPressed: isPingEnabled ? _executePing : null,
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Ping'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceIndicator({
    required String label,
    required String? deviceId,
    required String? deviceIp,
    required VoidCallback onTap,
  }) {
    final canvasState = ref.watch(canvasProvider);

    CanvasDevice? device;
    if (deviceId != null) {
      try {
        device = canvasState.devices.firstWhere((d) => d.id == deviceId);
      } catch (e) {
        // Device not found
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: deviceId != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
          color: deviceId != null
              ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            if (device != null) ...[
              Text(
                device.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (deviceIp != null && deviceIp.isNotEmpty)
                Text(
                  deviceIp,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ] else
              Text(
                'Tap to select',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeviceSelectionDialog(
    BuildContext context, {
    required bool isSource,
  }) async {
    final canvasState = ref.read(canvasProvider);
    final canvasNotifier = ref.read(canvasProvider.notifier);

    // Get available devices with IP addresses
    final availableDevices = <Map<String, dynamic>>[];

    for (final device in canvasState.devices) {
      final networkDevice = canvasNotifier.getNetworkDevice(device.id);

      // Skip source device when selecting destination
      if (!isSource && device.id == selectedSourceId) continue;

      String? ipAddress;

      if (networkDevice is EndDevice &&
          networkDevice.currentIpAddress != null) {
        ipAddress = networkDevice.currentIpAddress;
      } else if (networkDevice is RouterDevice) {
        // Auto-select first operational interface with IP
        ipAddress = _getFirstOperationalIp(networkDevice);
      }

      if (ipAddress != null && ipAddress.isNotEmpty) {
        availableDevices.add({
          'id': device.id,
          'name': device.name,
          'ip': ipAddress,
        });
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => _DeviceSelectionDialog(
        title: isSource ? 'Select Source Device' : 'Select Destination Device',
        devices: availableDevices,
        selectedId: isSource ? selectedSourceId : selectedDestId,
        showCustomIpOption: !isSource,
        onDeviceSelected: (deviceId, deviceIp) {
          setState(() {
            if (isSource) {
              selectedSourceId = deviceId;
              selectedSourceIp = deviceIp;
            } else {
              selectedDestId = deviceId;
              selectedDestIp = deviceIp;
              isCustomDestIp = false;
              _customIpController.clear();
            }
          });
        },
        onCustomIp: !isSource
            ? () {
                Navigator.of(ctx).pop();
                _showCustomIpDialog(context);
              }
            : null,
        onClear: () {
          setState(() {
            if (isSource) {
              selectedSourceId = null;
              selectedSourceIp = null;
            } else {
              selectedDestId = null;
              selectedDestIp = null;
              isCustomDestIp = false;
              _customIpController.clear();
            }
          });
        },
      ),
    );
  }

  String? _getFirstOperationalIp(RouterDevice router) {
    for (final iface in router.interfaces.values) {
      if (iface.isOperational && iface.ipAddress.isNotEmpty) {
        return iface.ipAddress;
      }
    }
    return null;
  }

  Future<void> _showCustomIpDialog(BuildContext context) async {
    final controller = TextEditingController(text: _customIpController.text);
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Enter Custom IP Address'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'IP Address',
              hintText: 'e.g., 192.168.1.100',
              errorText: errorText,
              prefixIcon: const Icon(Icons.language),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              setDialogState(() {
                if (value.trim().isEmpty) {
                  errorText = null;
                } else {
                  final ipRegex = RegExp(
                    r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
                  );
                  if (!ipRegex.hasMatch(value.trim())) {
                    errorText = 'Invalid IP format';
                  } else {
                    final parts = value.split('.');
                    if (parts.any((p) => int.parse(p) > 255)) {
                      errorText = 'Octets must be 0-255';
                    } else {
                      errorText = null;
                    }
                  }
                }
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: errorText == null && controller.text.trim().isNotEmpty
                  ? () {
                      setState(() {
                        _customIpController.text = controller.text.trim();
                        selectedDestId = null;
                        selectedDestIp = controller.text.trim();
                        isCustomDestIp = true;
                      });
                      Navigator.of(ctx).pop();
                    }
                  : null,
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _executePing() {
    final canvasNotifier = ref.read(canvasProvider.notifier);
    final engine = ref.read(simulationEngineProvider);

    if (selectedSourceId == null || selectedSourceIp == null) return;

    final targetIp = isCustomDestIp
        ? _customIpController.text.trim()
        : selectedDestIp;
    if (targetIp == null || targetIp.isEmpty) return;

    final sourceDevice = canvasNotifier.getNetworkDevice(selectedSourceId!);

    if (sourceDevice is EndDevice) {
      sourceDevice.ping(targetIp, engine);
    } else if (sourceDevice is RouterDevice) {
      // Router ping functionality uses first operational interface
      sourceDevice.ping(targetIp, engine);
    }
  }
}

// Device Selection Dialog Widget
class _DeviceSelectionDialog extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> devices;
  final String? selectedId;
  final bool showCustomIpOption;
  final Function(String deviceId, String deviceIp) onDeviceSelected;
  final VoidCallback? onCustomIp;
  final VoidCallback onClear;

  const _DeviceSelectionDialog({
    required this.title,
    required this.devices,
    required this.selectedId,
    required this.showCustomIpOption,
    required this.onDeviceSelected,
    this.onCustomIp,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: devices.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No devices with IP addresses available',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  ...devices.map((device) {
                    final isSelected = device['id'] == selectedId;
                    return ListTile(
                      leading: Icon(
                        Icons.computer,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(device['name']),
                      subtitle: Text(device['ip']),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      selected: isSelected,
                      onTap: () {
                        onDeviceSelected(device['id'], device['ip']);
                        Navigator.of(context).pop();
                      },
                    );
                  }),
                  if (showCustomIpOption && onCustomIp != null) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Custom IP Address'),
                      subtitle: const Text('Enter a custom IP address'),
                      onTap: onCustomIp,
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        if (selectedId != null)
          TextButton.icon(
            onPressed: () {
              onClear();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
