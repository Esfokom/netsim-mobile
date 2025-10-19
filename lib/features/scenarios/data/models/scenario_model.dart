import 'dart:convert';

import 'package:netsim_mobile/features/devices/data/models/device_model.dart';
import 'package:netsim_mobile/features/scenarios/data/models/scenario_metadata.dart';

class Scenario {
  final String name;
  final String difficulty;
  final int timeLimit;
  final int score;
  final List<Device> devices;
  final Metadata metadata;

  Scenario({
    required this.name,
    required this.difficulty,
    required this.timeLimit,
    required this.score,
    required this.devices,
    required this.metadata,
  });

  factory Scenario.fromJson(Map<String, dynamic> json) => Scenario(
    name: json['name'] as String,
    difficulty: json['difficulty'] as String,
    timeLimit: (json['timeLimit'] as num).toInt(),
    score: (json['score'] as num? ?? 0).toInt(),
    devices: (json['devices'] as List<dynamic>? ?? [])
        .map((e) => Device.fromJson(e as Map<String, dynamic>))
        .toList(),
    metadata: Metadata.fromJson(json['metadata'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'difficulty': difficulty,
    'timeLimit': timeLimit,
    'score': score,
    'devices': devices.map((d) => d.toJson()).toList(),
    'metadata': metadata.toJson(),
  };

  static Scenario fromJsonString(String source) =>
      Scenario.fromJson(jsonDecode(source) as Map<String, dynamic>);

  String toJsonString({bool pretty = false}) => pretty
      ? const JsonEncoder.withIndent('  ').convert(toJson())
      : jsonEncode(toJson());

  Scenario copyWith({
    String? name,
    String? difficulty,
    int? timeLimit,
    int? score,
    List<Device>? devices,
    Metadata? metadata,
  }) => Scenario(
    name: name ?? this.name,
    difficulty: difficulty ?? this.difficulty,
    timeLimit: timeLimit ?? this.timeLimit,
    score: score ?? this.score,
    devices: devices ?? this.devices,
    metadata: metadata ?? this.metadata,
  );
}

List<Scenario> scenariosFromJsonString(String source) {
  final decoded = jsonDecode(source);
  if (decoded is List) {
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Scenario.fromJson)
        .toList();
  }
  throw FormatException('Expected a JSON array of scenarios');
}

String scenariosToJsonString(List<Scenario> scenarios, {bool pretty = false}) {
  final list = scenarios.map((s) => s.toJson()).toList();
  return pretty
      ? const JsonEncoder.withIndent('  ').convert(list)
      : jsonEncode(list);
}
