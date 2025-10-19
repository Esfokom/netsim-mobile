// scenario/presentation/scenario_list_screen.dart
import 'package:flutter/material.dart';
import 'package:netsim_mobile/core/widgets/theme_toggle_button.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scenario_provider.dart';
import '../widgets/difficulty_tag.dart';
import 'scenario_view.dart';


class ScenarioListScreen extends ConsumerWidget {
  const ScenarioListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenariosAsync = ref.watch(scenarioNotifierProvider);
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scenarios"),
        centerTitle: true,
        actions: [ThemeToggleButton()],
      ),
      body: scenariosAsync.when(
        data: (scenarios) => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: scenarios.length,
          itemBuilder: (context, index) {
            final scenario = scenarios[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ScenarioViewScreen(scenario: scenario),
                    ),
                  );
                },
                child: ShadCard(
                  width: double.infinity,
                  title: Text(scenario.name, style: theme.textTheme.h4),
                  description: Text(
                    scenario.metadata.description,
                    style: theme.textTheme.muted,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DifficultyTag(difficulty: scenario.difficulty),
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading scenarios: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(scenarioNotifierProvider.notifier).loadScenarios();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
