import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/simulation/domain/services/simulation_engine.dart';

/// Bottom sheet for ping test functionality
class PingBottomSheet extends ConsumerStatefulWidget {
  final EndDevice sourceDevice;
  final VoidCallback onClose;

  const PingBottomSheet({
    super.key,
    required this.sourceDevice,
    required this.onClose,
  });

  @override
  ConsumerState<PingBottomSheet> createState() => _PingBottomSheetState();
}

class _PingBottomSheetState extends ConsumerState<PingBottomSheet> {
  late EndDevice selectedSource;
  String? selectedTargetIp;
  bool customIpMode = false;
  String? errorText;

  @override
  void initState() {
    super.initState();
    selectedSource = widget.sourceDevice;
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider);
    final canvasNotifier = ref.read(canvasProvider.notifier);

    // Get all devices that can be pinged
    final availableTargets = canvasState.devices.where((device) {
      final networkDevice = canvasNotifier.getNetworkDevice(device.id);
      if (networkDevice is EndDevice &&
          networkDevice.currentIpAddress != null &&
          device.id != selectedSource.deviceId) {
        return true;
      }
      return false;
    }).toList();

    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: Colors.black54,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSourceSelection(canvasState, canvasNotifier),
                            const SizedBox(height: 24),
                            _buildTargetModeToggle(),
                            const SizedBox(height: 8),
                            _buildTargetSelection(
                              availableTargets,
                              canvasNotifier,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildPingButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.network_ping,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text(
            'Ping Test',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
        ],
      ),
    );
  }

  Widget _buildSourceSelection(canvasState, canvasNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Source Device',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedSource.deviceId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: canvasState.devices
              .where((device) {
                final networkDevice = canvasNotifier.getNetworkDevice(
                  device.id,
                );
                return networkDevice is EndDevice &&
                    networkDevice.currentIpAddress != null;
              })
              .map<DropdownMenuItem<String>>((device) {
                final networkDevice =
                    canvasNotifier.getNetworkDevice(device.id) as EndDevice;
                return DropdownMenuItem<String>(
                  value: device.id,
                  child: Text(
                    '${device.name} (${networkDevice.currentIpAddress})',
                  ),
                );
              })
              .toList(),
          onChanged: (deviceId) {
            if (deviceId != null) {
              final networkDevice = canvasNotifier.getNetworkDevice(deviceId);
              if (networkDevice is EndDevice) {
                setState(() => selectedSource = networkDevice);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildTargetModeToggle() {
    return Row(
      children: [
        Text(
          'Target',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () {
            setState(() {
              customIpMode = !customIpMode;
              selectedTargetIp = null;
              errorText = null;
            });
          },
          icon: Icon(customIpMode ? Icons.list : Icons.edit, size: 16),
          label: Text(
            customIpMode ? 'Select from list' : 'Enter custom IP',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetSelection(
    List<CanvasDevice> availableTargets,
    canvasNotifier,
  ) {
    if (!customIpMode) {
      if (availableTargets.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No other devices with IP addresses available',
                  style: TextStyle(color: Colors.orange.shade700),
                ),
              ),
            ],
          ),
        );
      }
      return Column(
        children: availableTargets.map((device) {
          final networkDevice =
              canvasNotifier.getNetworkDevice(device.id) as EndDevice;
          final isSelected = selectedTargetIp == networkDevice.currentIpAddress;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              leading: Icon(
                Icons.computer,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(device.name),
              subtitle: Text(networkDevice.currentIpAddress!),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => setState(() {
                selectedTargetIp = networkDevice.currentIpAddress;
                errorText = null;
              }),
            ),
          );
        }).toList(),
      );
    } else {
      return TextField(
        decoration: InputDecoration(
          labelText: 'Target IP Address',
          border: const OutlineInputBorder(),
          errorText: errorText,
          hintText: 'e.g., 192.168.1.2',
          prefixIcon: const Icon(Icons.input),
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          setState(() {
            if (value.trim().isEmpty) {
              errorText = 'IP address cannot be empty';
            } else {
              final ipRegex = RegExp(
                r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
              );
              if (!ipRegex.hasMatch(value.trim())) {
                errorText = 'Invalid IP address format';
              } else {
                errorText = null;
                selectedTargetIp = value.trim();
              }
            }
          });
        },
      );
    }
  }

  Widget _buildPingButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: selectedTargetIp != null && errorText == null
              ? () {
                  final engine = ref.read(simulationEngineProvider);
                  selectedSource.ping(selectedTargetIp!, engine);
                  widget.onClose();
                }
              : null,
          icon: const Icon(Icons.send),
          label: const Text('Ping'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}
