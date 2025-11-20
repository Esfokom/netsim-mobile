import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';

/// State for game condition checking
class GameConditionState {
  final Map<String, bool> conditionResults;
  final bool isChecking;
  final DateTime? lastCheckTime;

  const GameConditionState({
    this.conditionResults = const {},
    this.isChecking = false,
    this.lastCheckTime,
  });

  GameConditionState copyWith({
    Map<String, bool>? conditionResults,
    bool? isChecking,
    DateTime? lastCheckTime,
  }) {
    return GameConditionState(
      conditionResults: conditionResults ?? this.conditionResults,
      isChecking: isChecking ?? this.isChecking,
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
    );
  }

  bool get allConditionsPassed {
    if (conditionResults.isEmpty) return false;
    return conditionResults.values.every((passed) => passed);
  }

  int get passedCount => conditionResults.values.where((p) => p).length;
  int get totalCount => conditionResults.length;
}

/// Notifier for game condition checking with debouncing
class GameConditionChecker extends Notifier<GameConditionState> {
  Timer? _debounceTimer;

  static const Duration _debounceDuration = Duration(milliseconds: 200);

  @override
  GameConditionState build() {
    // Clean up timer when provider is disposed
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _debounceTimer = null;
    });

    return const GameConditionState();
  }

  /// Trigger a debounced condition check
  /// Only checks if in simulation mode, otherwise returns immediately
  void triggerConditionCheck() {
    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Start a new debounce timer
    _debounceTimer = Timer(_debounceDuration, () {
      _performConditionCheck();
    });
  }

  /// Force an immediate condition check (bypasses debounce)
  Future<void> forceCheck() async {
    _debounceTimer?.cancel();
    await _performConditionCheck();
  }

  /// Internal method to perform the actual condition check
  Future<void> _performConditionCheck() async {
    // Only skip condition checks in edit mode
    // Allow checks in simulation mode (scenario editor testing AND game play)
    final scenarioState = ref.read(scenarioProvider);
    if (scenarioState.mode == ScenarioMode.edit) {
      appLogger.d('[GameConditionChecker] In edit mode, skipping check');
      return;
    }

    // Don't check if already checking
    if (state.isChecking) {
      appLogger.d('[GameConditionChecker] Already checking, skipping');
      return;
    }

    appLogger.d('[GameConditionChecker] Starting condition check...');

    // Mark as checking
    state = state.copyWith(isChecking: true);

    try {
      // Perform the actual condition check
      final results = await ref
          .read(scenarioProvider.notifier)
          .checkConditions();

      // Update state with results
      state = state.copyWith(
        conditionResults: results,
        isChecking: false,
        lastCheckTime: DateTime.now(),
      );

      appLogger.d(
        '[GameConditionChecker] Check complete: ${state.passedCount}/${state.totalCount} passed',
      );

      if (state.allConditionsPassed && results.isNotEmpty) {
        appLogger.i('[GameConditionChecker] All conditions passed!');
      }
    } catch (e, stackTrace) {
      appLogger.e(
        '[GameConditionChecker] Error during condition check',
        error: e,
        stackTrace: stackTrace,
      );

      // Reset checking state on error
      state = state.copyWith(isChecking: false);
    }
  }

  /// Clear all condition results (when exiting simulation mode)
  void clearResults() {
    _debounceTimer?.cancel();
    state = const GameConditionState();
    appLogger.d('[GameConditionChecker] Results cleared');
  }

  /// Reset and trigger a fresh check
  void resetAndCheck() {
    state = const GameConditionState();
    triggerConditionCheck();
  }
}

/// Provider for game condition checking
final gameConditionCheckerProvider =
    NotifierProvider<GameConditionChecker, GameConditionState>(() {
      return GameConditionChecker();
    });
