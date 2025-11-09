// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:netsim_mobile/features/scenarios/data/models/scenario_model.dart';
// import 'package:netsim_mobile/features/scenarios/presentation/widgets/scenario_edit_dialog.dart';
// import '../providers/scenario_provider.dart';
// import '../widgets/difficulty_header_card.dart';
// import '../widgets/stats_grid.dart';
// import '../widgets/scenario_info_card.dart';
// import '../widgets/devices_overview_card.dart';
//
// class ScenarioViewScreen extends ConsumerWidget {
//   final Scenario scenario;
//
//   const ScenarioViewScreen({super.key, required this.scenario});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final scenariosAsync = ref.watch(scenarioNotifierProvider);
//
//     return scenariosAsync.when(
//       data: (scenarios) {
//         final current = scenarios.firstWhere(
//           (s) =>
//               identical(s, scenario) ||
//               (s.name == scenario.name &&
//                   s.metadata.createdAt == scenario.metadata.createdAt),
//           orElse: () => scenario,
//         );
//
//         return Scaffold(
//           appBar: AppBar(
//             scrolledUnderElevation: 0,
//             title: Text(
//               current.name,
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//             centerTitle: true,
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.edit),
//                 onPressed: () {
//                   ScenarioEditDialog().showEditDialog(context, current);
//                 },
//               ),
//             ],
//           ),
//           body: SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 DifficultyHeaderCard(difficulty: current.difficulty),
//                 const SizedBox(height: 20),
//                 ScenarioInfoCard(
//                   name: current.name,
//                   description: current.metadata.description,
//                 ),
//
//                 const SizedBox(height: 20),
//                 StatsGrid(
//                   timeLimit: current.timeLimit,
//                   deviceCount: current.devices.length,
//                   createdAt: current.metadata.createdAt,
//                   createdBy: current.metadata.createdBy,
//                 ),
//                 const SizedBox(height: 20),
//                 // DescriptionCard(description: current.metadata.description),
//                 //
//                 // const SizedBox(height: 20),
//                 DevicesOverviewCard(scenario: current),
//               ],
//             ),
//           ),
//         );
//       },
//       loading: () => Scaffold(
//         appBar: AppBar(title: Text(scenario.name)),
//         body: const Center(child: CircularProgressIndicator()),
//       ),
//       error: (error, stack) => Scaffold(
//         appBar: AppBar(title: Text(scenario.name)),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, size: 48, color: Colors.red),
//               const SizedBox(height: 16),
//               Text('Error loading scenarios: $error'),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   ref.read(scenarioNotifierProvider.notifier).loadScenarios();
//                 },
//                 child: const Text('Retry'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
