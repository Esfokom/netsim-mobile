import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/devices/data/models/device_model.dart';
import 'package:netsim_mobile/features/scenarios/data/models/scenario_model.dart';
import 'package:netsim_mobile/features/scenarios/logic/scenarios_provider.dart'
    as scenarios_provider_import;
import 'package:netsim_mobile/core/services/device_alert_service.dart';

class DeviceEditDialog {
  Future<void> showEditDialog(
    BuildContext parentContext,
    Device current, {
    Scenario? parentScenario,
    int? deviceIndex,
  }) async {
    await showDialog<void>(
      context: parentContext,
      barrierDismissible: false,
      builder: (context) => _DeviceEditDialogContent(
        parentContext: parentContext,
        device: current,
        parentScenario: parentScenario,
        deviceIndex: deviceIndex,
      ),
    );
  }
}

class _DeviceEditDialogContent extends StatefulWidget {
  final BuildContext parentContext;
  final Device device;
  final Scenario? parentScenario;
  final int? deviceIndex;
  const _DeviceEditDialogContent({
    required this.parentContext,
    required this.device,
    this.parentScenario,
    this.deviceIndex,
  });

  @override
  State<_DeviceEditDialogContent> createState() =>
      _DeviceEditDialogContentState();
}

class _DeviceEditDialogContentState extends State<_DeviceEditDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _alertService = DeviceAlertService();

  late final TextEditingController xController;
  late final TextEditingController yController;

  late final TextEditingController pingController;
  late final TextEditingController latencyThresholdController;
  late final TextEditingController failureProbController;
  late final TextEditingController trafficLoadController;

  late final TextEditingController latencyController;
  late bool online;

  @override
  void initState() {
    super.initState();
    final d = widget.device;
    xController = TextEditingController(text: d.position.x.toString());
    yController = TextEditingController(text: d.position.y.toString());

    pingController = TextEditingController(
      text: d.parameters.pingInterval.toString(),
    );
    latencyThresholdController = TextEditingController(
      text: d.parameters.latencyThreshold.toString(),
    );
    failureProbController = TextEditingController(
      text: d.parameters.failureProbability.toString(),
    );
    trafficLoadController = TextEditingController(
      text: d.parameters.trafficLoad.toString(),
    );

    latencyController = TextEditingController(
      text: d.status.latency.toString(),
    );
    online = d.status.online;
  }

  @override
  void dispose() {
    xController.dispose();
    yController.dispose();
    pingController.dispose();
    latencyThresholdController.dispose();
    failureProbController.dispose();
    trafficLoadController.dispose();
    latencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.device;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Edit Device: ${current.type}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: xController,
                      decoration: const InputDecoration(
                        labelText: 'Position X',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter X';
                        if (int.tryParse(v.trim()) == null)
                          return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: yController,
                      decoration: const InputDecoration(
                        labelText: 'Position Y',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter Y';
                        if (int.tryParse(v.trim()) == null)
                          return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: pingController,
                decoration: const InputDecoration(
                  labelText: 'Ping Interval (ms)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Enter ping interval';
                  if (int.tryParse(v.trim()) == null) return 'Invalid number';
                  return null;
                },
              ),
              TextFormField(
                controller: latencyThresholdController,
                decoration: const InputDecoration(
                  labelText: 'Latency Threshold (ms)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Enter latency threshold';
                  if (int.tryParse(v.trim()) == null) return 'Invalid number';
                  return null;
                },
              ),
              TextFormField(
                controller: failureProbController,
                decoration: const InputDecoration(
                  labelText: 'Failure Probability (0.0 - 1.0)',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Enter failure probability';
                  final d = double.tryParse(v.trim());
                  if (d == null || d < 0 || d > 1)
                    return 'Enter between 0 and 1';
                  return null;
                },
              ),
              TextFormField(
                controller: trafficLoadController,
                decoration: const InputDecoration(labelText: 'Traffic Load'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Enter traffic load';
                  if (int.tryParse(v.trim()) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Online'),
                  const SizedBox(width: 8),
                  StatefulBuilder(
                    builder: (ctx, setState) {
                      return Switch(
                        activeThumbColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                        value: online,
                        onChanged: (v) => setState(() => online = v),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: latencyController,
                      decoration: const InputDecoration(
                        labelText: 'Latency (ms)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Enter latency';
                        if (int.tryParse(v.trim()) == null)
                          return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final newX = int.parse(xController.text.trim());
            final newY = int.parse(yController.text.trim());

            final newPing = int.parse(pingController.text.trim());
            final newLatencyThreshold = int.parse(
              latencyThresholdController.text.trim(),
            );
            final newFailureProb = double.parse(
              failureProbController.text.trim(),
            );
            final newTrafficLoad = int.parse(trafficLoadController.text.trim());

            final newLatency = int.parse(latencyController.text.trim());

            final updatedDevice = current.copyWith(
              position: current.position.copyWith(x: newX, y: newY),
              parameters: current.parameters.copyWith(
                pingInterval: newPing,
                latencyThreshold: newLatencyThreshold,
                failureProbability: newFailureProb,
                trafficLoad: newTrafficLoad,
              ),
              status: current.status.copyWith(
                online: online,
                latency: newLatency,
                lastChecked: DateTime.now(),
              ),
            );

            debugPrint('💾 [DeviceEditDialog] Save button pressed');
            debugPrint(
              '💾 [DeviceEditDialog] Old device: ${current.type} (${current.id})',
            );
            debugPrint(
              '💾 [DeviceEditDialog] New device: ${updatedDevice.type} (${updatedDevice.id})',
            );
            debugPrint(
              '💾 [DeviceEditDialog] Old online: ${current.status.online}, New: ${updatedDevice.status.online}',
            );
            debugPrint(
              '💾 [DeviceEditDialog] Old latencyThreshold: ${current.parameters.latencyThreshold}, New: ${updatedDevice.parameters.latencyThreshold}',
            );
            debugPrint(
              '💾 [DeviceEditDialog] Old pingInterval: ${current.parameters.pingInterval}, New: ${updatedDevice.parameters.pingInterval}',
            );
            debugPrint(
              '💾 [DeviceEditDialog] Old failureProbability: ${current.parameters.failureProbability}, New: ${updatedDevice.parameters.failureProbability}',
            );
            debugPrint(
              '💾 [DeviceEditDialog] Old trafficLoad: ${current.parameters.trafficLoad}, New: ${updatedDevice.parameters.trafficLoad}',
            );

            // Close dialog first
            debugPrint('💾 [DeviceEditDialog] Closing dialog');
            Navigator.of(context).pop();
            debugPrint('💾 [DeviceEditDialog] Dialog closed');

            // Analyze changes and trigger alerts
            debugPrint('💾 [DeviceEditDialog] Calling analyzeDeviceChanges');
            debugPrint(
              '💾 [DeviceEditDialog] Parent context type: ${widget.parentContext.runtimeType}',
            );
            debugPrint(
              '💾 [DeviceEditDialog] Parent context mounted: ${widget.parentContext.mounted}',
            );

            await _alertService.analyzeDeviceChanges(
              current,
              updatedDevice,
              widget.parentContext,
            );

            debugPrint('💾 [DeviceEditDialog] analyzeDeviceChanges completed');

            // Update the device in the scenario
            try {
              final container = ProviderScope.containerOf(widget.parentContext);
              final notifier = container.read(
                scenarios_provider_import.scenariosProvider.notifier,
              );
              final scenarios = container.read(
                scenarios_provider_import.scenariosProvider,
              );

              if (widget.parentScenario != null) {
                final ownerIdx = scenarios.indexWhere(
                  (s) =>
                      s.name == widget.parentScenario!.name &&
                      s.metadata.createdAt ==
                          widget.parentScenario!.metadata.createdAt,
                );
                if (ownerIdx != -1) {
                  final owner = scenarios[ownerIdx];
                  final devices = [...owner.devices];
                  final devIdx = devices.indexWhere((d) => d.id == current.id);
                  if (devIdx != -1) {
                    devices[devIdx] = updatedDevice;
                    final updatedScenario = owner.copyWith(devices: devices);
                    notifier.updateScenario(owner, updatedScenario);
                    debugPrint(
                      '💾 [DeviceEditDialog] Scenario updated via parentScenario',
                    );
                  }
                }
              } else {
                // find scenario that contains this device by id
                final ownerIdx = scenarios.indexWhere(
                  (s) => s.devices.any((d) => d.id == current.id),
                );
                if (ownerIdx != -1) {
                  final owner = scenarios[ownerIdx];
                  final devices = [...owner.devices];
                  final devIdx = devices.indexWhere((d) => d.id == current.id);
                  if (devIdx != -1) {
                    devices[devIdx] = updatedDevice;
                    final updatedScenario = owner.copyWith(devices: devices);
                    notifier.updateScenario(owner, updatedScenario);
                    debugPrint(
                      '💾 [DeviceEditDialog] Scenario updated via device search',
                    );
                  }
                }
              }
            } catch (e) {
              debugPrint('❌ [DeviceEditDialog] Error updating scenario: $e');
            }
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
