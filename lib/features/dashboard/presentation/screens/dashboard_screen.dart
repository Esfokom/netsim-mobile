import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/core/widgets/theme_toggle_button.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the AsyncValue<List<Scenario>> from ScenarioNotifier
    final scenariosAsync = ref.watch(scenarioNotifierProvider);

    // Get notifier for refresh or updates
    final scenarioNotifier = ref.read(scenarioNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Network Dashboard"),
        actions: const [ThemeToggleButton()],
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await scenarioNotifier.loadScenarios();
        },
        child: scenariosAsync.when(
          data: (scenarios) {
            print("Dashboard scenarios data: ${scenarios.length}");
            final score = scenarios.isNotEmpty ? scenarios.first.score : 0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Display the current score
                  ShadCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Score",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Your Score: $score",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Status Overview",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ShadCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Icon(Icons.power_off,
                                  color: Colors.red, size: 30),
                              SizedBox(height: 8),
                              Text(
                                "Devices Offline",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "2",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ShadCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Icon(Icons.speed,
                                  color: Colors.orange, size: 30),
                              SizedBox(height: 8),
                              Text(
                                "High Latency",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "1",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ShadCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Performance",
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text("Session Time: 17:40"),
                        Text(
                          "Status: Needs Improvement",
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              "Error loading scenarios: $error",
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
