import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/network_scenario.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/scenario_condition.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/device_rule.dart';
import 'package:netsim_mobile/features/scenarios/domain/repositories/i_scenario_repository.dart';
import 'package:netsim_mobile/features/scenarios/data/repositories/scenario_repository_impl.dart';
import 'package:netsim_mobile/features/scenarios/data/services/scenario_storage_service.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/data/models/device_link.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/scenarios/utils/property_verification_helper.dart';
import 'package:netsim_mobile/features/scenarios/utils/condition_verifiers/condition_verification_service.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';

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
  late final ConditionVerificationService _verificationService;

  @override
  ScenarioState build() {
    // Initialize verification service with ref
    _verificationService = ConditionVerificationService(ref);

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

  /// Get the permission level for a specific property or action
  PropertyPermission getPropertyPermission(
    String deviceId,
    DeviceActionType actionType, {
    String? propertyId,
  }) {
    // In edit mode, everything is editable
    if (state.mode == ScenarioMode.edit) return PropertyPermission.editable;

    final rules = getDeviceRules(deviceId);

    // Find the most specific rule for this action/property
    DeviceRule? matchingRule;

    for (final rule in rules) {
      if (rule.actionType == actionType) {
        // For editProperty actions, check if propertyId matches
        if (actionType == DeviceActionType.editProperty) {
          if (rule.propertyId == propertyId) {
            matchingRule = rule;
            break; // Exact match found
          } else if (rule.propertyId == null && matchingRule == null) {
            matchingRule = rule; // Wildcard match (applies to all properties)
          }
        } else {
          matchingRule = rule;
          break;
        }
      }
    }

    // Return the permission from the matching rule, or denied by default
    return matchingRule?.permission ?? PropertyPermission.denied;
  }

  /// Check if an action is allowed (editable) in simulation mode
  /// This is a convenience method for backward compatibility
  bool isActionAllowed(
    String deviceId,
    DeviceActionType actionType, {
    String? propertyId,
  }) {
    final permission = getPropertyPermission(
      deviceId,
      actionType,
      propertyId: propertyId,
    );
    return permission == PropertyPermission.editable;
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

  /// Check all success conditions (deprecated - use checkConditions instead)
  @Deprecated('Use checkConditions() instead')
  Future<Map<String, bool>> checkSuccessConditions(
    WidgetRef externalRef,
  ) async {
    return checkConditions();
  }

  /// Check all success conditions using instance ref
  Future<Map<String, bool>> checkConditions() async {
    // Get current canvas state with live devices and links
    final canvasState = ref.read(canvasProvider);

    appLogger.d('[ScenarioProvider] Checking success conditions...');
    appLogger.d(
      '[ScenarioProvider] Number of conditions: ${state.scenario.successConditions.length}',
    );
    appLogger.d(
      '[ScenarioProvider] Canvas devices: ${canvasState.devices.length}',
    );
    appLogger.d('[ScenarioProvider] Canvas links: ${canvasState.links.length}');

    // Use the verification service to check all conditions
    final results = _verificationService.verifyAllConditions(
      state.scenario.successConditions,
      canvasState,
    );

    // Update state with condition results
    state = state.copyWith(conditionResults: results);

    // Log detailed results
    for (final condition in state.scenario.successConditions) {
      final passed = results[condition.id] ?? false;

      appLogger.d(
        '[ScenarioProvider] Checking condition: ${condition.id} - ${condition.description}',
      );
      appLogger.d('[ScenarioProvider] Condition type: ${condition.type}');
      appLogger.d(
        '[ScenarioProvider] Condition result: ${passed ? "PASSED ✓" : "FAILED ✗"}',
      );
    }

    appLogger.d('[ScenarioProvider] All results: $results');

    // Check if all conditions are satisfied
    final allSatisfied = results.values.every((passed) => passed);
    if (allSatisfied && results.isNotEmpty) {
      appLogger.i('[ScenarioProvider] ✅ All conditions satisfied!');
    }

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
      appLogger.e('Error importing scenario', error: e);
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

  // ============================================================================
  // ENHANCED CONDITION VERIFICATION METHODS (NEW)
  // ============================================================================

  /// Check all success conditions using the new verification service
  /// This uses the enhanced verifiers for device properties, interfaces, ARP, routing, links
  void checkConditionsWithNewService() {
    final canvasState = ref.read(canvasProvider);

    appLogger.d(
      '[ScenarioProvider] Checking ${state.scenario.successConditions.length} conditions (new service)',
    );

    // Use the verification service to check all conditions
    final results = _verificationService.verifyAllConditions(
      state.scenario.successConditions,
      canvasState,
    );

    // Update state with condition results
    state = state.copyWith(conditionResults: results);

    // Log results
    results.forEach((conditionId, passed) {
      final condition = state.scenario.successConditions.firstWhere(
        (c) => c.id == conditionId,
        orElse: () => throw Exception('Condition not found'),
      );
      appLogger.d(
        '[ScenarioProvider] Condition "${condition.description}": ${passed ? "PASSED" : "FAILED"}',
      );
    });

    // Check if all conditions are satisfied
    final allSatisfied = _verificationService.areAllConditionsSatisfied(
      state.scenario.successConditions,
      canvasState,
    );

    if (allSatisfied && state.scenario.successConditions.isNotEmpty) {
      _onScenarioCompleted();
    }
  }

  /// Get verification status for a specific condition
  bool? getConditionStatus(String conditionId) {
    return state.conditionResults?[conditionId];
  }

  /// Get count of satisfied conditions
  int getSatisfiedConditionsCount() {
    if (state.conditionResults == null) return 0;
    return state.conditionResults!.values.where((v) => v).length;
  }

  /// Get count of total conditions
  int getTotalConditionsCount() {
    return state.scenario.successConditions.length;
  }

  /// Check if a specific condition is satisfied
  bool isConditionSatisfied(String conditionId) {
    return state.conditionResults?[conditionId] ?? false;
  }

  /// Get progress percentage (0-100)
  double getConditionsProgress() {
    final total = getTotalConditionsCount();
    if (total == 0) return 0.0;
    final satisfied = getSatisfiedConditionsCount();
    return (satisfied / total) * 100.0;
  }

  /// Called when all conditions are satisfied (scenario completed)
  void _onScenarioCompleted() {
    appLogger.i(
      '[ScenarioProvider] 🎉 All success conditions satisfied! Scenario completed!',
    );

    // TODO: Implement completion logic
    // - Show completion dialog
    // - Update player statistics
    // - Award points/badges
    // - Save completion record
    // - Trigger celebration animation
  }

  /// Verify a single condition (for testing or preview)
  bool verifySingleCondition(ScenarioCondition condition) {
    final canvasState = ref.read(canvasProvider);
    return _verificationService.verifyCondition(condition, canvasState);
  }

  /// Reset condition results (clear all verification status)
  void resetConditionResults() {
    state = state.copyWith(conditionResults: {});
    appLogger.d('[ScenarioProvider] Condition results reset');
  }
}

/// Provider for scenario storage service
final scenarioStorageServiceProvider = Provider<ScenarioStorageService>((ref) {
  return ScenarioStorageService();
});

/// Provider for scenario repository
final scenarioRepositoryProvider = Provider<IScenarioRepository>((ref) {
  final storageService = ref.watch(scenarioStorageServiceProvider);
  return ScenarioRepositoryImpl(storageService);
});

/// Provider for scenario state
final scenarioProvider = NotifierProvider<ScenarioNotifier, ScenarioState>(() {
  return ScenarioNotifier();
});
