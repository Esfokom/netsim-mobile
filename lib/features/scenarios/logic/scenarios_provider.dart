// import 'package:riverpod/legacy.dart';
// import '../data/sources/mock_scenarios.dart';
// import '../data/models/scenario_model.dart';
// import '../data/sources/persistent_scenarios.dart';
//
// class ScenariosNotifier extends StateNotifier<List<Scenario>> {
//   ScenariosNotifier() : super(List<Scenario>.from(MockScenarios.scenarios)) {
//     _loadFromDisk();
//   }
//
//   Future<void> _loadFromDisk() async {
//     final fromDisk = await PersistentScenarios.load();
//
//     if (fromDisk != null && fromDisk.isNotEmpty) {
//       state = fromDisk;
//     } else {
//       // Persist default mock data for first-time users
//       try {
//         await PersistentScenarios.save(state);
//       } catch (_) {}
//     }
//   }
//
//   Future<void> refresh() async {
//     await _loadFromDisk();
//   }
//
//   void setAll(List<Scenario> list) {
//     state = List<Scenario>.from(list);
//   }
//
//   void resetToMock() {
//     try {
//       state = List<Scenario>.from(MockScenarios.scenarios);
//       PersistentScenarios.save(state);
//     } catch (_) {}
//   }
//
//   void updateScenario(Scenario oldScenario, Scenario newScenario) {
//     final idx = state.indexWhere((s) =>
//         identical(s, oldScenario) ||
//         (s.name == oldScenario.name &&
//             s.metadata.createdAt == oldScenario.metadata.createdAt));
//     if (idx != -1) {
//       final next = [...state];
//       next[idx] = newScenario;
//       state = next;
//
//       try {
//         final msIdx = MockScenarios.scenarios.indexWhere((s) =>
//             identical(s, oldScenario) ||
//             (s.name == oldScenario.name &&
//                 s.metadata.createdAt == oldScenario.metadata.createdAt));
//         if (msIdx != -1) MockScenarios.scenarios[msIdx] = newScenario;
//       } catch (_) {}
//
//       // persist changes
//       PersistentScenarios.save(state);
//     }
//   }
//
//   // Current scenario helper (for dashboard)
//   Scenario? get currentScenario => state.isNotEmpty ? state.first : null;
//
//   // Current score (read-only)
//   int get currentScore => currentScenario?.score ?? 0;
//
//   // Update score for current scenario
//   void updateScore(int newScore) {
//     if (state.isEmpty) return;
//
//     final updatedScenario = currentScenario!.copyWith(score: newScore);
//     final next = [...state];
//     next[0] = updatedScenario; // update the first scenario (active one)
//     state = next;
//
//     // Persist both memory and disk
//     try {
//       PersistentScenarios.save(state);
//     } catch (e) {
//       print("Error saving score: $e");
//     }
//   }
// }
//
// final scenariosProvider =
//     StateNotifierProvider<ScenariosNotifier, List<Scenario>>((ref) {
//   return ScenariosNotifier();
// });
//
