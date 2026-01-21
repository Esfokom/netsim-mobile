import 'package:netsim_mobile/features/scenarios/domain/entities/network_scenario.dart';

/// Repository interface for scenario persistence operations
/// This follows the dependency inversion principle - domain defines the contract,
/// data layer implements it
abstract class IScenarioRepository {
  /// Load all available scenarios
  Future<List<NetworkScenario>> listScenarios();

  /// Load a specific scenario by ID
  Future<NetworkScenario?> loadScenario(String scenarioId);

  /// Save a scenario (create or update)
  Future<void> saveScenario(NetworkScenario scenario);

  /// Delete a scenario
  Future<void> deleteScenario(String scenarioId);

  /// Check if a scenario exists
  Future<bool> scenarioExists(String scenarioId);

  /// Export scenario to JSON string
  Future<String> exportScenario(NetworkScenario scenario);

  /// Import scenario from JSON string
  Future<NetworkScenario> importScenario(String jsonString);
}
