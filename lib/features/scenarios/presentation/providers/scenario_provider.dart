import 'package:riverpod/riverpod.dart';
import '../../data/models/scenario_model.dart';
import '../../data/sources/json_scenario_data_source.dart';

final scenarioDataSourceProvider = Provider<JsonScenarioDataSource>((ref) {
  return JsonScenarioDataSource();
});

class ScenarioNotifier extends Notifier<AsyncValue<List<Scenario>>> {
  @override
  AsyncValue<List<Scenario>> build() {
    loadScenarios();
    return const AsyncValue.loading();
  }

  Future<void> loadScenarios() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dataSource = ref.read(scenarioDataSourceProvider);
      return await dataSource.loadScenariosFromAssets();
    });
  } 

  // Update only the score of a specific scenario
  void updateScore(String scenarioId, int newScore) {
    final current = state.value ?? [];
    final updatedList = current.map((scenario) {
      if (scenario.name == scenarioId) {
        return scenario.copyWith(score: newScore);
      }
      return scenario;
    }).toList();
    state = AsyncValue.data(updatedList);
  }

  Future<void> updateScenario(Scenario scenario) async {
    final dataSource = ref.read(scenarioDataSourceProvider);
    await dataSource.updateScenario(scenario);
    await loadScenarios();
  }
}

final scenarioNotifierProvider =
    NotifierProvider<ScenarioNotifier, AsyncValue<List<Scenario>>>(() {
      return ScenarioNotifier();
    });

final scenariosProvider = FutureProvider<List<Scenario>>((ref) async {
  final dataSource = JsonScenarioDataSource();
  return await dataSource.loadScenariosFromAssets();
});
