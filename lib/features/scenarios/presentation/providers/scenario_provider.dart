import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/data/models/network_scenario.dart';
import 'package:netsim_mobile/features/scenarios/data/models/scenario_condition.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/scenarios/utils/property_verification_helper.dart';
import 'package:netsim_mobile/features/canvas/data/models/device_link.dart';
import 'package:netsim_mobile/features/scenarios/data/services/scenario_storage_service.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/scenarios/data/models/device_rule.dart';

/// Mode of the scenario editor/player
enum ScenarioMode { edit, simulation }

/// State for the scenario
class ScenarioState {
  final NetworkScenario scenario;
  final ScenarioMode mode;
  final String? selectedDeviceId;
  final bool isModified;

  // Simulation-specific state
  final List<CanvasDevice>? simulationDevices;
  final List<DeviceLink>? simulationLinks;
  final Map<String, bool>? conditionResults; // Track which conditions passed

  const ScenarioState({
    required this.scenario,
    this.mode = ScenarioMode.edit,
    this.selectedDeviceId,
    this.isModified = false,
    this.simulationDevices,
    this.simulationLinks,
    this.conditionResults,
  });

  ScenarioState copyWith({
    NetworkScenario? scenario,
    ScenarioMode? mode,
    String? selectedDeviceId,
    bool? isModified,
    List<CanvasDevice>? simulationDevices,
    List<DeviceLink>? simulationLinks,
    Map<String, bool>? conditionResults,
    bool clearSelectedDevice = false,
  }) {
    return ScenarioState(
      scenario: scenario ?? this.scenario,
      mode: mode ?? this.mode,
      selectedDeviceId: clearSelectedDevice
          ? null
          : (selectedDeviceId ?? this.selectedDeviceId),
      isModified: isModified ?? this.isModified,
      simulationDevices: simulationDevices ?? this.simulationDevices,
      simulationLinks: simulationLinks ?? this.simulationLinks,
      conditionResults: conditionResults ?? this.conditionResults,
    );
  }
}

/// Notifier for managing scenario state
class ScenarioNotifier extends Notifier<ScenarioState> {
  final ScenarioStorageService _storageService = ScenarioStorageService();

  @override
  ScenarioState build() {
    // Try to load the current scenario from storage
    _loadCurrentScenario();
    return ScenarioState(scenario: NetworkScenario.empty());
  }

  /// Load current scenario from storage
  Future<void> _loadCurrentScenario() async {
    final scenario = await _storageService.loadCurrentScenario();
    if (scenario != null) {
      state = ScenarioState(scenario: scenario);
    }
  }

  /// Create a new scenario
  void createNewScenario() {
    state = ScenarioState(scenario: NetworkScenario.empty());
  }

  /// Load an existing scenario
  void loadScenario(NetworkScenario scenario) {
    state = ScenarioState(scenario: scenario);
  }

  /// Update scenario metadata
  void updateMetadata({
    String? title,
    String? description,
    ScenarioDifficulty? difficulty,
  }) {
    state = state.copyWith(
      scenario: state.scenario.copyWith(
        title: title,
        description: description,
        difficulty: difficulty,
        lastModified: DateTime.now(),
      ),
      isModified: true,
    );
  }

  /// Update player settings
  void updatePlayerSettings(PlayerSettings settings) {
    state = state.copyWith(
      scenario: state.scenario.copyWith(
        playerSettings: settings,
        lastModified: DateTime.now(),
      ),
      isModified: true,
    );
  }

  /// Add a success condition
  void addCondition(ScenarioCondition condition) {
    state = state.copyWith(
      scenario: state.scenario.copyWith(
        successConditions: [...state.scenario.successConditions, condition],
        lastModified: DateTime.now(),
      ),
      isModified: true,
    );
  }

  /// Update a condition
  void updateCondition(String conditionId, ScenarioCondition updatedCondition) {
    final updatedConditions = state.scenario.successConditions.map((c) {
      return c.id == conditionId ? updatedCondition : c;
    }).toList();

    state = state.copyWith(
      scenario: state.scenario.copyWith(
        successConditions: updatedConditions,
        lastModified: DateTime.now(),
      ),
      isModified: true,
    );
  }

  /// Remove a condition
  void removeCondition(String conditionId) {
    state = state.copyWith(
      scenario: state.scenario.copyWith(
        successConditions: state.scenario.successConditions
            .where((c) => c.id != conditionId)
            .toList(),
        lastModified: DateTime.now(),
      ),
      isModified: true,
    );
  }

  /// Add a rule to a device
  void addDeviceRule(String deviceId, DeviceRule rule) {
    final currentRules = Map<String, List<DeviceRule>>.from(
      state.scenario.deviceRules,
    );
    final deviceRules = List<DeviceRule>.from(currentRules[deviceId] ?? []);
    deviceRules.add(rule);
    currentRules[deviceId] = deviceRules;

    state = state.copyWith(
      scenario: state.scenario.copyWith(
        deviceRules: currentRules,
        lastModified: DateTime.now(),
      ),
      isModified: true,
    );
  }

  /// Remove a rule from a device
  void removeDeviceRule(String deviceId, String ruleId) {
    final currentRules = Map<String, List<DeviceRule>>.from(
      state.scenario.deviceRules,
    );
    final deviceRules = currentRules[deviceId];
    if (deviceRules != null) {
      currentRules[deviceId] = deviceRules
          .where((r) => r.id != ruleId)
          .toList();
      if (currentRules[deviceId]!.isEmpty) {
        currentRules.remove(deviceId);
      }
    }

    state = state.copyWith(
      scenario: state.scenario.copyWith(
        deviceRules: currentRules,
        lastModified: DateTime.now(),
      ),
      isModified: true,
    );
  }

  /// Get rules for a specific device
  List<DeviceRule> getDeviceRules(String deviceId) {
    return state.scenario.deviceRules[deviceId] ?? [];
  }

  /// Check if an action is allowed in simulation mode
  bool isActionAllowed(
    String deviceId,
    DeviceActionType actionType, {
    String? propertyId,
  }) {
    if (state.mode != ScenarioMode.simulation) return true;

    final rules = getDeviceRules(deviceId);
    if (rules.isEmpty) {
      // No rules means no actions allowed by default
      return false;
    }

    // Check for deny rules first
    final hasDenyRule = rules.any(
      (rule) =>
          rule.type == RuleType.deny &&
          rule.actionType == actionType &&
          (actionType != DeviceActionType.editProperty ||
              rule.propertyId == propertyId),
    );

    if (hasDenyRule) return false;

    // Check for allow rules
    final hasAllowRule = rules.any(
      (rule) =>
          rule.type == RuleType.allow &&
          rule.actionType == actionType &&
          (actionType != DeviceActionType.editProperty ||
              rule.propertyId == propertyId ||
              rule.propertyId == null),
    );

    return hasAllowRule;
  }

  /// Select a device for editing
  void selectDevice(String? deviceId) {
    state = state.copyWith(
      selectedDeviceId: deviceId,
      clearSelectedDevice: deviceId == null,
    );
  }

  /// Snapshot current canvas state to scenario
  void snapshotCanvasState(List<CanvasDevice> devices, List<DeviceLink> links) {
    state = state.copyWith(
      scenario: state.scenario.copyWith(
        initialDeviceStates: devices,
        initialLinks: links,
        lastModified: DateTime.now(),
      ),
      isModified: true,
    );
  }

  /// Switch to simulation mode
  void enterSimulationMode() {
    // Create copies of the initial state for simulation
    final simulationDevices = state.scenario.initialDeviceStates
        .map((device) => device.copyWith())
        .toList();
    final simulationLinks = List<DeviceLink>.from(state.scenario.initialLinks);

    state = state.copyWith(
      mode: ScenarioMode.simulation,
      simulationDevices: simulationDevices,
      simulationLinks: simulationLinks,
      conditionResults: {},
    );
  }

  /// Switch back to edit mode
  void exitSimulationMode() {
    state = state.copyWith(
      mode: ScenarioMode.edit,
      simulationDevices: null,
      simulationLinks: null,
      conditionResults: null,
    );
  }

  /// Update simulation device state (during simulation)
  void updateSimulationDevice(CanvasDevice updatedDevice) {
    if (state.simulationDevices == null) return;

    final updatedDevices = state.simulationDevices!.map((device) {
      return device.id == updatedDevice.id ? updatedDevice : device;
    }).toList();

    state = state.copyWith(simulationDevices: updatedDevices);
  }

  /// Check all success conditions
  Future<Map<String, bool>> checkSuccessConditions(WidgetRef ref) async {
    final results = <String, bool>{};

    print('[ScenarioProvider] Checking success conditions...');
    print(
      '[ScenarioProvider] Number of conditions: ${state.scenario.successConditions.length}',
    );
    print(
      '[ScenarioProvider] Simulation devices: ${state.simulationDevices?.length}',
    );

    for (final condition in state.scenario.successConditions) {
      bool passed = false;

      print(
        '[ScenarioProvider] Checking condition: ${condition.id} - ${condition.description}',
      );
      print('[ScenarioProvider] Condition type: ${condition.type}');

      if (condition.type == ConditionType.connectivity) {
        print(
          '[ScenarioProvider] Connectivity check - protocol: ${condition.protocol}',
        );

        // Check for link/cable connectivity
        if (condition.protocol == ConnectivityProtocol.link) {
          print(
            '[ScenarioProvider] Link check - source: ${condition.sourceDeviceID}, target: ${condition.targetDeviceID}',
          );

          // Check if both source and target device IDs are provided
          if (condition.sourceDeviceID != null &&
              condition.targetDeviceID != null) {
            // Check if a link exists between the two devices
            final links = state.simulationLinks;
            if (links != null) {
              // Check if there's a link connecting these two devices (in either direction)
              final linkExists = links.any(
                (link) =>
                    (link.fromDeviceId == condition.sourceDeviceID &&
                        link.toDeviceId == condition.targetDeviceID) ||
                    (link.fromDeviceId == condition.targetDeviceID &&
                        link.toDeviceId == condition.sourceDeviceID),
              );

              passed = linkExists;
              print('[ScenarioProvider] Link exists: $linkExists');
            } else {
              print('[ScenarioProvider] No simulation links available');
              passed = false;
            }
          } else {
            print(
              '[ScenarioProvider] Missing source or target device ID for link check',
            );
            passed = false;
          }
        } else {
          // TODO: Implement other connectivity checks (ping, http, dnsLookup)
          print(
            '[ScenarioProvider] Other connectivity protocols not yet implemented',
          );
          passed = false;
        }
      } else if (condition.type == ConditionType.propertyCheck) {
        print(
          '[ScenarioProvider] Property check - target device: ${condition.targetDeviceID}',
        );
        print(
          '[ScenarioProvider] Property: ${condition.property}, Expected: ${condition.expectedValue}',
        );

        // Check if a device property matches expected value
        if (state.simulationDevices != null &&
            condition.targetDeviceID != null &&
            condition.property != null &&
            condition.expectedValue != null &&
            condition.operator != null &&
            condition.propertyDataType != null) {
          // Find the device
          CanvasDevice? device;
          try {
            device = state.simulationDevices!.firstWhere(
              (d) => d.id == condition.targetDeviceID,
            );
            print('[ScenarioProvider] Found simulation device: ${device.name}');
          } catch (e) {
            // Device not found, condition fails
            device = null;
            print(
              '[ScenarioProvider] Device not found in simulationDevices: $e',
            );
          }

          if (device != null) {
            // Get the network device to access its properties
            final canvasNotifier = ref.read(canvasProvider.notifier);
            final networkDevice = canvasNotifier.getNetworkDevice(device.id);

            print(
              '[ScenarioProvider] Network device: ${networkDevice != null ? "found" : "not found"}',
            );

            if (networkDevice != null) {
              print(
                '[ScenarioProvider] Network device properties: ${networkDevice.properties.map((p) => p.label).join(", ")}',
              );

              // Find the property by label
              final property = networkDevice.properties
                  .where((p) => p.label == condition.property)
                  .firstOrNull;

              print('[ScenarioProvider] Property found: ${property != null}');
              if (property != null) {
                print('[ScenarioProvider] Property value: ${property.value}');

                // Use the robust verification helper
                passed = verifyPropertyCondition(
                  property: property,
                  operator: condition.operator!,
                  expectedValue: condition.expectedValue!,
                  dataType: condition.propertyDataType!,
                );

                print('[ScenarioProvider] Verification result: $passed');
              }
            }
          }
        } else {
          print(
            '[ScenarioProvider] Missing required fields for property check',
          );
          print('  - simulationDevices: ${state.simulationDevices != null}');
          print('  - targetDeviceID: ${condition.targetDeviceID != null}');
          print('  - property: ${condition.property != null}');
          print('  - expectedValue: ${condition.expectedValue != null}');
          print('  - operator: ${condition.operator != null}');
          print('  - propertyDataType: ${condition.propertyDataType != null}');
        }
      }

      results[condition.id] = passed;
      print('[ScenarioProvider] Condition ${condition.id} result: $passed');
    }

    print('[ScenarioProvider] All results: $results');
    state = state.copyWith(conditionResults: results);
    return results;
  }

  /// Save scenario to JSON
  Map<String, dynamic> exportToJson() {
    return state.scenario.toJson();
  }

  /// Load scenario from JSON
  void importFromJson(Map<String, dynamic> json) {
    try {
      final scenario = NetworkScenario.fromJson(json);
      state = ScenarioState(scenario: scenario);
    } catch (e) {
      print('Error importing scenario: $e');
    }
  }

  /// Persist scenario to storage
  Future<bool> persistScenario() async {
    final success = await _storageService.saveScenario(state.scenario);
    if (success) {
      // Also save as current scenario
      await _storageService.saveCurrentScenario(state.scenario);
    }
    return success;
  }

  /// Load a specific scenario from storage
  Future<void> loadScenarioFromStorage(String scenarioID) async {
    final scenario = await _storageService.getScenario(scenarioID);
    if (scenario != null) {
      state = ScenarioState(scenario: scenario);
    }
  }

  /// Get all saved scenarios
  Future<List<NetworkScenario>> getAllSavedScenarios() async {
    return await _storageService.getAllScenarios();
  }

  /// Delete a scenario from storage
  Future<bool> deleteScenarioFromStorage(String scenarioID) async {
    return await _storageService.deleteScenario(scenarioID);
  }

  /// Auto-save current scenario
  Future<void> autoSave() async {
    await _storageService.saveCurrentScenario(state.scenario);
  }

  /// Reset scenario state to empty initial state
  void resetToEmpty() {
    state = ScenarioState(scenario: NetworkScenario.empty());
  }
}

/// Provider for scenario state
final scenarioProvider = NotifierProvider<ScenarioNotifier, ScenarioState>(() {
  return ScenarioNotifier();
});
