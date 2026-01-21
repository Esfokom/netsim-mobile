import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:netsim_mobile/features/scenarios/domain/entities/network_scenario.dart';
import 'package:netsim_mobile/features/scenarios/data/services/scenario_storage_service.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';

/// Game state for managing scenario lists and game progress
class GameState {
  final List<NetworkScenario> preconfiguredScenarios;
  final List<NetworkScenario> savedScenarios;
  final bool isLoading;
  final String? error;

  const GameState({
    this.preconfiguredScenarios = const [],
    this.savedScenarios = const [],
    this.isLoading = false,
    this.error,
  });

  GameState copyWith({
    List<NetworkScenario>? preconfiguredScenarios,
    List<NetworkScenario>? savedScenarios,
    bool? isLoading,
    String? error,
  }) {
    return GameState(
      preconfiguredScenarios:
          preconfiguredScenarios ?? this.preconfiguredScenarios,
      savedScenarios: savedScenarios ?? this.savedScenarios,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Game state notifier
class GameNotifier extends Notifier<GameState> {
  final ScenarioStorageService _storageService = ScenarioStorageService();

  @override
  GameState build() {
    return const GameState();
  }

  /// Load all scenarios from assets and storage
  Future<void> loadScenarios() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load preconfigured scenarios from assets
      final preconfiguredScenarios = await _loadPreconfiguredScenarios();

      // Load saved scenarios from storage
      final savedScenarios = await _storageService.getAllScenarios();

      state = state.copyWith(
        preconfiguredScenarios: preconfiguredScenarios,
        savedScenarios: savedScenarios,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load scenarios: $e',
      );
    }
  }

  /// Load preconfigured scenarios from assets/data/scenarios
  Future<List<NetworkScenario>> _loadPreconfiguredScenarios() async {
    final List<NetworkScenario> scenarios = [];

    try {
      // Load manifest file to get list of available scenarios
      final manifestString = await rootBundle.loadString(
        'assets/data/scenarios/manifest.json',
      );
      final scenarioFiles = (json.decode(manifestString) as List<dynamic>)
          .cast<String>();

      for (final fileName in scenarioFiles) {
        try {
          final jsonString = await rootBundle.loadString(
            'assets/data/scenarios/$fileName',
          );
          final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
          final scenario = NetworkScenario.fromJson(jsonMap);
          scenarios.add(scenario);
        } catch (e) {
          appLogger.w('Failed to load scenario $fileName', error: e);
          // Continue loading other scenarios even if one fails
        }
      }
    } catch (e) {
      appLogger.e('Error loading preconfigured scenarios', error: e);
    }

    return scenarios;
  }

  /// Refresh scenarios (useful after creating new ones)
  Future<void> refreshScenarios() async {
    await loadScenarios();
  }
}

/// Provider for game state
final gameProvider = NotifierProvider<GameNotifier, GameState>(() {
  return GameNotifier();
});
