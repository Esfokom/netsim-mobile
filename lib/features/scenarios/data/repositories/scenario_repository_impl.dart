import 'dart:convert';
import 'package:netsim_mobile/features/scenarios/domain/entities/network_scenario.dart';
import 'package:netsim_mobile/features/scenarios/domain/repositories/i_scenario_repository.dart';
import 'package:netsim_mobile/features/scenarios/data/services/scenario_storage_service.dart';

/// Implementation of the scenario repository interface
/// Uses ScenarioStorageService for actual persistence
class ScenarioRepositoryImpl implements IScenarioRepository {
  final ScenarioStorageService _storageService;

  ScenarioRepositoryImpl(this._storageService);

  @override
  Future<List<NetworkScenario>> listScenarios() async {
    try {
      return await _storageService.getAllScenarios();
    } catch (e) {
      print('Error listing scenarios: $e');
      return [];
    }
  }

  @override
  Future<NetworkScenario?> loadScenario(String scenarioId) async {
    try {
      return await _storageService.getScenario(scenarioId);
    } catch (e) {
      print('Error loading scenario: $e');
      return null;
    }
  }

  @override
  Future<void> saveScenario(NetworkScenario scenario) async {
    try {
      final success = await _storageService.saveScenario(scenario);
      if (!success) {
        throw Exception('Failed to save scenario');
      }
    } catch (e) {
      print('Error saving scenario: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteScenario(String scenarioId) async {
    try {
      final success = await _storageService.deleteScenario(scenarioId);
      if (!success) {
        throw Exception('Failed to delete scenario');
      }
    } catch (e) {
      print('Error deleting scenario: $e');
      rethrow;
    }
  }

  @override
  Future<bool> scenarioExists(String scenarioId) async {
    try {
      final scenario = await _storageService.getScenario(scenarioId);
      return scenario != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> exportScenario(NetworkScenario scenario) async {
    try {
      return jsonEncode(scenario.toJson());
    } catch (e) {
      print('Error exporting scenario: $e');
      rethrow;
    }
  }

  @override
  Future<NetworkScenario> importScenario(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return NetworkScenario.fromJson(json);
    } catch (e) {
      print('Error importing scenario: $e');
      rethrow;
    }
  }
}
