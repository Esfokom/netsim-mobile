import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle, AssetManifest;
import 'package:netsim_mobile/features/scenarios/data/models/scenario_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JsonScenarioDataSource {
  Future<List<String>> getScenarioPaths() async {
    final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(
      rootBundle,
    );
    final List<String> scenarioPaths = assetManifest
        .listAssets()
        .where((key) => key.startsWith('assets/data/scenarios/'))
        .toList();
    return scenarioPaths;
  }

  Future<List<Scenario>> loadScenariosFromAssets() async {
    try {
      final scenarioPaths = await getScenarioPaths();
      if (scenarioPaths.isEmpty) {
        print("Warning: No scenario files found in assets/data/scenarios/");
        return [];
      }

      final List<Scenario> scenarios = [];
      for (final path in scenarioPaths) {
        final jsonString = await rootBundle.loadString(path);
        final scenario = Scenario.fromJsonString(jsonString);

        // Try to read updated version from storage (file on mobile, SharedPreferences on web)
        final updatedScenario = await readScenarioFromStorage(scenario.name);
        scenarios.add(updatedScenario ?? scenario);
      }

      return scenarios;
    } catch (e) {
      print("Error loading scenarios from assets: $e");
      return [];
    }
  }

  String _sanitizeName(String scenarioName) {
    return scenarioName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
  }

  // Platform-agnostic storage methods

  Future<void> writeScenarioToStorage(Scenario scenario) async {
    try {
      if (kIsWeb) {
        await _writeScenarioToWeb(scenario);
      } else {
        await _writeScenarioToFile(scenario);
      }
    } catch (e) {
      print("Error writing scenario '${scenario.name}' to storage: $e");
      rethrow;
    }
  }

  Future<Scenario?> readScenarioFromStorage(String scenarioName) async {
    try {
      if (kIsWeb) {
        return await _readScenarioFromWeb(scenarioName);
      } else {
        return await _readScenarioFromFile(scenarioName);
      }
    } catch (e) {
      print("Error reading scenario '$scenarioName' from storage: $e");
      return null;
    }
  }

  Future<bool> updateScenario(Scenario scenario) async {
    try {
      await writeScenarioToStorage(scenario);
      return true;
    } catch (e) {
      print("Error updating scenario '${scenario.name}': $e");
      return false;
    }
  }

  Future<bool> deleteScenario(String scenarioName) async {
    try {
      if (kIsWeb) {
        return await _deleteScenarioFromWeb(scenarioName);
      } else {
        return await _deleteScenarioFromFile(scenarioName);
      }
    } catch (e) {
      print("Error deleting scenario '$scenarioName': $e");
      return false;
    }
  }

  // Web-specific methods using SharedPreferences

  String _getStorageKey(String scenarioName) {
    return 'scenario_${_sanitizeName(scenarioName)}';
  }

  Future<void> _writeScenarioToWeb(Scenario scenario) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getStorageKey(scenario.name);
    final jsonString = scenario.toJsonString(pretty: true);
    await prefs.setString(key, jsonString);
  }

  Future<Scenario?> _readScenarioFromWeb(String scenarioName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getStorageKey(scenarioName);
    final jsonString = prefs.getString(key);

    if (jsonString == null) {
      return null;
    }

    return Scenario.fromJsonString(jsonString);
  }

  Future<bool> _deleteScenarioFromWeb(String scenarioName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getStorageKey(scenarioName);
    return await prefs.remove(key);
  }

  // Mobile/Desktop-specific methods using file system

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localFile(String scenarioName) async {
    final path = await _localPath;
    final sanitizedName = _sanitizeName(scenarioName);
    return File('$path/scenarios/$sanitizedName.json');
  }

  Future<void> _ensureDirectoryExists() async {
    final path = await _localPath;
    final directory = Directory('$path/scenarios');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  Future<void> _writeScenarioToFile(Scenario scenario) async {
    await _ensureDirectoryExists();
    final file = await _localFile(scenario.name);
    final jsonString = scenario.toJsonString(pretty: true);
    await file.writeAsString(jsonString);
  }

  Future<Scenario?> _readScenarioFromFile(String scenarioName) async {
    final file = await _localFile(scenarioName);
    if (!await file.exists()) {
      return null;
    }
    final contents = await file.readAsString();
    return Scenario.fromJsonString(contents);
  }

  Future<bool> _deleteScenarioFromFile(String scenarioName) async {
    final file = await _localFile(scenarioName);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }
}
