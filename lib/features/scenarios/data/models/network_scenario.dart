import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/data/models/device_link.dart';
import 'package:netsim_mobile/features/scenarios/data/models/scenario_condition.dart';
import 'package:netsim_mobile/features/scenarios/data/models/device_rule.dart';

/// Difficulty levels for scenarios
enum ScenarioDifficulty { easy, medium, hard }

extension ScenarioDifficultyExtension on ScenarioDifficulty {
  String get displayName {
    switch (this) {
      case ScenarioDifficulty.easy:
        return 'Easy';
      case ScenarioDifficulty.medium:
        return 'Medium';
      case ScenarioDifficulty.hard:
        return 'Hard';
    }
  }
}

/// Player settings for a scenario
@immutable
class PlayerSettings {
  final List<String> availableTools;
  final List<String> editableDevices; // Empty means all are editable

  const PlayerSettings({
    this.availableTools = const ['ping', 'ipconfig', 'nslookup'],
    this.editableDevices = const [],
  });

  PlayerSettings copyWith({
    List<String>? availableTools,
    List<String>? editableDevices,
  }) {
    return PlayerSettings(
      availableTools: availableTools ?? this.availableTools,
      editableDevices: editableDevices ?? this.editableDevices,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'availableTools': availableTools,
      'editableDevices': editableDevices,
    };
  }

  factory PlayerSettings.fromJson(Map<String, dynamic> json) {
    return PlayerSettings(
      availableTools:
          (json['availableTools'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['ping', 'ipconfig', 'nslookup'],
      editableDevices:
          (json['editableDevices'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Represents a complete network scenario
@immutable
class NetworkScenario {
  final String scenarioID;
  final String title;
  final String description;
  final ScenarioDifficulty difficulty;
  final List<CanvasDevice> initialDeviceStates;
  final List<DeviceLink> initialLinks;
  final PlayerSettings playerSettings;
  final List<ScenarioCondition> successConditions;
  final Map<String, List<DeviceRule>> deviceRules; // Map of deviceId to rules
  final DateTime createdAt;
  final DateTime? lastModified;

  const NetworkScenario({
    required this.scenarioID,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.initialDeviceStates,
    required this.initialLinks,
    required this.playerSettings,
    required this.successConditions,
    this.deviceRules = const {},
    required this.createdAt,
    this.lastModified,
  });

  NetworkScenario copyWith({
    String? scenarioID,
    String? title,
    String? description,
    ScenarioDifficulty? difficulty,
    List<CanvasDevice>? initialDeviceStates,
    List<DeviceLink>? initialLinks,
    PlayerSettings? playerSettings,
    List<ScenarioCondition>? successConditions,
    Map<String, List<DeviceRule>>? deviceRules,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return NetworkScenario(
      scenarioID: scenarioID ?? this.scenarioID,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      initialDeviceStates: initialDeviceStates ?? this.initialDeviceStates,
      initialLinks: initialLinks ?? this.initialLinks,
      playerSettings: playerSettings ?? this.playerSettings,
      successConditions: successConditions ?? this.successConditions,
      deviceRules: deviceRules ?? this.deviceRules,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scenarioID': scenarioID,
      'title': title,
      'description': description,
      'difficulty': difficulty.name,
      'initialDeviceStates': initialDeviceStates
          .map(
            (device) => {
              'id': device.id,
              'name': device.name,
              'type': device.type.name,
              'position': {'x': device.position.dx, 'y': device.position.dy},
              'status': device.status.name,
            },
          )
          .toList(),
      'initialLinks': initialLinks
          .map(
            (link) => {
              'id': link.id,
              'fromDeviceId': link.fromDeviceId,
              'toDeviceId': link.toDeviceId,
              'type': link.type.name,
            },
          )
          .toList(),
      'playerSettings': playerSettings.toJson(),
      'successConditions': successConditions
          .map((condition) => condition.toJson())
          .toList(),
      'deviceRules': deviceRules.map(
        (deviceId, rules) =>
            MapEntry(deviceId, rules.map((rule) => rule.toJson()).toList()),
      ),
      'createdAt': createdAt.toIso8601String(),
      if (lastModified != null) 'lastModified': lastModified!.toIso8601String(),
    };
  }

  factory NetworkScenario.fromJson(Map<String, dynamic> json) {
    return NetworkScenario(
      scenarioID: json['scenarioID'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: ScenarioDifficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => ScenarioDifficulty.medium,
      ),
      initialDeviceStates: (json['initialDeviceStates'] as List<dynamic>).map((
        deviceJson,
      ) {
        final positionMap = deviceJson['position'] as Map<String, dynamic>;
        return CanvasDevice(
          id: deviceJson['id'] as String,
          name: deviceJson['name'] as String,
          type: DeviceType.values.firstWhere(
            (t) => t.name == deviceJson['type'],
          ),
          position: Offset(
            (positionMap['x'] as num).toDouble(),
            (positionMap['y'] as num).toDouble(),
          ),
          status: DeviceStatus.values.firstWhere(
            (s) => s.name == deviceJson['status'],
            orElse: () => DeviceStatus.online,
          ),
        );
      }).toList(),
      initialLinks: (json['initialLinks'] as List<dynamic>)
          .map(
            (linkJson) => DeviceLink(
              id: linkJson['id'] as String,
              fromDeviceId: linkJson['fromDeviceId'] as String,
              toDeviceId: linkJson['toDeviceId'] as String,
              type: linkJson['type'] != null
                  ? LinkType.values.firstWhere(
                      (t) => t.name == linkJson['type'],
                      orElse: () => LinkType.ethernet,
                    )
                  : LinkType.ethernet,
            ),
          )
          .toList(),
      playerSettings: PlayerSettings.fromJson(
        json['playerSettings'] as Map<String, dynamic>,
      ),
      successConditions: (json['successConditions'] as List<dynamic>)
          .map(
            (conditionJson) => ScenarioCondition.fromJson(
              conditionJson as Map<String, dynamic>,
            ),
          )
          .toList(),
      deviceRules:
          (json['deviceRules'] as Map<String, dynamic>?)?.map(
            (deviceId, rulesJson) => MapEntry(
              deviceId,
              (rulesJson as List<dynamic>)
                  .map(
                    (ruleJson) =>
                        DeviceRule.fromJson(ruleJson as Map<String, dynamic>),
                  )
                  .toList(),
            ),
          ) ??
          {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }

  /// Create a new empty scenario
  factory NetworkScenario.empty() {
    return NetworkScenario(
      scenarioID: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Scenario',
      description: 'Describe the scenario objective here...',
      difficulty: ScenarioDifficulty.easy,
      initialDeviceStates: const [],
      initialLinks: const [],
      playerSettings: const PlayerSettings(),
      successConditions: const [],
      createdAt: DateTime.now(),
    );
  }
}
