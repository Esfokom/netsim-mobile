import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/network_scenario.dart';

/// Service for persisting and loading scenarios
class ScenarioStorageService {
  static const String _scenariosKey = 'saved_scenarios';
  static const String _currentScenarioKey = 'current_scenario';

  /// Save a scenario to storage
  Future<bool> saveScenario(NetworkScenario scenario) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing scenarios
      final scenarios = await getAllScenarios();

      // Update or add the scenario
      final index = scenarios.indexWhere(
        (s) => s.scenarioID == scenario.scenarioID,
      );
      if (index >= 0) {
        scenarios[index] = scenario;
      } else {
        scenarios.add(scenario);
      }

      // Save back to storage
      final jsonList = scenarios.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      return await prefs.setString(_scenariosKey, jsonString);
    } catch (e) {
      print('Error saving scenario: $e');
      return false;
    }
  }

  /// Load all scenarios from storage
  Future<List<NetworkScenario>> getAllScenarios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_scenariosKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => NetworkScenario.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading scenarios: $e');
      return [];
    }
  }

  /// Get a specific scenario by ID
  Future<NetworkScenario?> getScenario(String scenarioID) async {
    final scenarios = await getAllScenarios();
    try {
      return scenarios.firstWhere((s) => s.scenarioID == scenarioID);
    } catch (e) {
      return null;
    }
  }

  /// Delete a scenario
  Future<bool> deleteScenario(String scenarioID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scenarios = await getAllScenarios();

      scenarios.removeWhere((s) => s.scenarioID == scenarioID);

      final jsonList = scenarios.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      return await prefs.setString(_scenariosKey, jsonString);
    } catch (e) {
      print('Error deleting scenario: $e');
      return false;
    }
  }

  /// Save current scenario (auto-save)
  Future<bool> saveCurrentScenario(NetworkScenario scenario) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(scenario.toJson());
      return await prefs.setString(_currentScenarioKey, jsonString);
    } catch (e) {
      print('Error saving current scenario: $e');
      return false;
    }
  }

  /// Load current scenario (auto-save)
  Future<NetworkScenario?> loadCurrentScenario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_currentScenarioKey);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      return NetworkScenario.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error loading current scenario: $e');
      return null;
    }
  }

  /// Clear current scenario
  Future<bool> clearCurrentScenario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_currentScenarioKey);
    } catch (e) {
      print('Error clearing current scenario: $e');
      return false;
    }
  }

  /// Export scenario to JSON string
  String exportToJson(NetworkScenario scenario) {
    return const JsonEncoder.withIndent('  ').convert(scenario.toJson());
  }

  /// Import scenario from JSON string
  NetworkScenario? importFromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return NetworkScenario.fromJson(json);
    } catch (e) {
      print('Error importing scenario: $e');
      return null;
    }
  }

  /// Get scenario count
  Future<int> getScenarioCount() async {
    final scenarios = await getAllScenarios();
    return scenarios.length;
  }

  /// Clear all scenarios (for testing/reset)
  Future<bool> clearAllScenarios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_scenariosKey);
    } catch (e) {
      print('Error clearing all scenarios: $e');
      return false;
    }
  }
}
