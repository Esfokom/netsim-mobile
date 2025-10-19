import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/scenario_model.dart';

class PersistentScenarios {
  static const _fileName = 'scenarios.json';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    print("PersistentScenarios directory: ${dir.path}");
    
    return File('${dir.path}/$_fileName');
  }

  static Future<List<Scenario>?> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      final contents = await f.readAsString();
      final decoded = jsonDecode(contents);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Scenario.fromJson)
            .toList();
      }
      return null;
    } catch (e) {
      // ignore read errors
      return null;
    }
  }

  static Future<bool> save(List<Scenario> scenarios) async {
    try {
      final f = await _file();
      final encoded = jsonEncode(scenarios.map((s) => s.toJson()).toList());
      await f.writeAsString(encoded);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete the persistent scenarios file. Returns true if deletion succeeded
  // or the file did not exist.
  static Future<bool> delete() async {
    try {
      final f = await _file();
      if (await f.exists()) await f.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
