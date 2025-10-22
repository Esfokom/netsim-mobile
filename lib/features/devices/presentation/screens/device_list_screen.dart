import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/device_model.dart';
import 'package:netsim_mobile/features/scenarios/data/models/scenario_model.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/core/services/device_alert_service.dart';
import '../widgets/device_card.dart';

class DeviceListScreen extends ConsumerStatefulWidget {
  final List<Device> devices;
  final Scenario? scenario;

  const DeviceListScreen({super.key, required this.devices, this.scenario});

  @override
  ConsumerState<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends ConsumerState<DeviceListScreen> {
  int? _editingDeviceIndex;
  final Map<int, Map<String, dynamic>> _editingValues = {};
  final _alertService = DeviceAlertService();

  @override
  Widget build(BuildContext context) {
    List<Device> currentDevices = widget.devices;
    String appBarTitle = 'Devices';

    if (widget.scenario != null) {
      final scenariosAsync = ref.watch(scenarioNotifierProvider);
      currentDevices = scenariosAsync.maybeWhen(
        data: (scenarios) {
          final current = scenarios.firstWhere(
            (s) =>
                identical(s, widget.scenario) ||
                (s.name == widget.scenario!.name &&
                    s.metadata.createdAt ==
                        widget.scenario!.metadata.createdAt),
            orElse: () => widget.scenario!,
          );
          appBarTitle = current.name;
          return current.devices;
        },
        orElse: () => widget.devices,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: currentDevices.isEmpty
          ? const Center(child: Text('No devices found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: currentDevices.length,
              itemBuilder: (context, index) {
                final device = currentDevices[index];
                final isEditing = _editingDeviceIndex == index;

                return DeviceCard(
                  device: device,
                  index: index,
                  isEditing: isEditing,
                  editingValues: _editingValues[index] ?? {},
                  onToggleEdit: () => _toggleEditMode(index, device),
                  onSave: () => _saveDevice(index, device),
                  onCancel: () => _cancelEdit(index),
                  onValueChanged: (key, value) =>
                      _updateEditingValue(index, key, value),
                );
              },
            ),
    );
  }

  void _toggleEditMode(int index, Device device) {
    setState(() {
      if (_editingDeviceIndex == index) {
        _editingDeviceIndex = null;
        _editingValues.remove(index);
      } else {
        _editingDeviceIndex = index;
        // Clamp initial values to ensure they're within valid ranges
        _editingValues[index] = {
          'pingInterval': device.parameters.pingInterval.clamp(100, 10000),
          'latencyThreshold': device.parameters.latencyThreshold.clamp(0, 1000),
          'failureProbability': device.parameters.failureProbability.clamp(
            0.0,
            1.0,
          ),
          'trafficLoad': device.parameters.trafficLoad.clamp(0, 100),
          'online': device.status.online,
          'x': device.position.x,
          'y': device.position.y,
        };
      }
    });
  }

  void _cancelEdit(int index) {
    setState(() {
      _editingDeviceIndex = null;
      _editingValues.remove(index);
    });
  }

  void _updateEditingValue(int index, String key, dynamic value) {
    setState(() {
      _editingValues[index] = {..._editingValues[index] ?? {}, key: value};
    });
  }

  Future<void> _saveDevice(int index, Device device) async {
    if (widget.scenario == null) return;

    final values = _editingValues[index]!;
    final updatedDevice = device.copyWith(
      parameters: device.parameters.copyWith(
        pingInterval: values['pingInterval'] as int,
        latencyThreshold: values['latencyThreshold'] as int,
        failureProbability: values['failureProbability'] as double,
        trafficLoad: values['trafficLoad'] as int,
      ),
      status: device.status.copyWith(online: values['online'] as bool),
      position: device.position.copyWith(
        x: values['x'] as int,
        y: values['y'] as int,
      ),
    );

    final updatedDevices = List<Device>.from(widget.scenario!.devices);
    updatedDevices[index] = updatedDevice;
    final updatedScenario = widget.scenario!.copyWith(devices: updatedDevices);

    try {
      await ref
          .read(scenarioNotifierProvider.notifier)
          .updateScenario(updatedScenario);

      setState(() {
        _editingDeviceIndex = null;
        _editingValues.remove(index);
      });

      if (mounted) {
        await _alertService.analyzeDeviceChanges(
          device,
          updatedDevice,
          context,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update device: $e')));
      }
    }
  }
}
