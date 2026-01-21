import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/network_scenario.dart';
import 'package:netsim_mobile/features/game/presentation/providers/game_provider.dart';
import 'package:netsim_mobile/features/game/presentation/widgets/scenario_card.dart';
import 'package:netsim_mobile/features/game/presentation/screens/game_play_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load scenarios when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).loadScenarios();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Mode'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.stars), text: 'Challenges'),
            Tab(icon: Icon(Icons.save), text: 'Saved Scenarios'),
          ],
        ),
      ),
      body: gameState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPreconfiguredScenarios(gameState.preconfiguredScenarios),
                _buildSavedScenarios(gameState.savedScenarios),
              ],
            ),
    );
  }

  Widget _buildPreconfiguredScenarios(List<NetworkScenario> scenarios) {
    if (scenarios.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No challenges available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scenarios.length,
      itemBuilder: (context, index) {
        final scenario = scenarios[index];
        return ScenarioCard(
          scenario: scenario,
          onTap: () => _playScenario(scenario),
          isPreconfigured: true,
        );
      },
    );
  }

  Widget _buildSavedScenarios(List<NetworkScenario> scenarios) {
    if (scenarios.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No saved scenarios',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Create scenarios in the Scenario Editor',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scenarios.length,
      itemBuilder: (context, index) {
        final scenario = scenarios[index];
        return ScenarioCard(
          scenario: scenario,
          onTap: () => _playScenario(scenario),
          isPreconfigured: false,
        );
      },
    );
  }

  void _playScenario(NetworkScenario scenario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GamePlayScreen(scenario: scenario),
      ),
    );
  }
}
