import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/data/models/network_scenario.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/scenarios/presentation/game_view.dart';

/// Screen to display all saved scenarios
class SavedScenariosScreen extends ConsumerStatefulWidget {
  const SavedScenariosScreen({super.key});

  @override
  ConsumerState<SavedScenariosScreen> createState() =>
      _SavedScenariosScreenState();
}

class _SavedScenariosScreenState extends ConsumerState<SavedScenariosScreen> {
  List<NetworkScenario> _scenarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScenarios();
  }

  Future<void> _loadScenarios() async {
    setState(() => _isLoading = true);
    final scenarios = await ref
        .read(scenarioProvider.notifier)
        .getAllSavedScenarios();
    setState(() {
      _scenarios = scenarios;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Scenarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScenarios,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scenarios.isEmpty
          ? _buildEmptyState()
          : _buildScenarioList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GameView()),
          ).then((_) => _loadScenarios());
        },
        icon: const Icon(Icons.add),
        label: const Text('New Scenario'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Saved Scenarios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new scenario to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioList() {
    // Sort by last modified (newest first)
    _scenarios.sort((a, b) {
      final aDate = a.lastModified ?? a.createdAt;
      final bDate = b.lastModified ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _scenarios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final scenario = _scenarios[index];
        return _ScenarioCard(
          scenario: scenario,
          onTap: () => _openScenario(scenario),
          onDelete: () => _deleteScenario(scenario),
        );
      },
    );
  }

  void _openScenario(NetworkScenario scenario) async {
    // Load the scenario
    await ref
        .read(scenarioProvider.notifier)
        .loadScenarioFromStorage(scenario.scenarioID);

    if (!mounted) return;

    // Navigate to game view
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GameView()),
    ).then((_) => _loadScenarios());
  }

  void _deleteScenario(NetworkScenario scenario) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scenario'),
        content: Text('Are you sure you want to delete "${scenario.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(scenarioProvider.notifier)
          .deleteScenarioFromStorage(scenario.scenarioID);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Scenario deleted' : 'Failed to delete scenario',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadScenarios();
      }
    }
  }
}

class _ScenarioCard extends StatelessWidget {
  final NetworkScenario scenario;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ScenarioCard({
    required this.scenario,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lastModified = scenario.lastModified ?? scenario.createdAt;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Difficulty badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(
                        scenario.difficulty,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      scenario.difficulty.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getDifficultyColor(scenario.difficulty),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: onDelete,
                    color: Colors.red,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                scenario.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                scenario.description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _StatChip(
                    icon: Icons.devices,
                    label: '${scenario.initialDeviceStates.length} devices',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.check_circle_outline,
                    label: '${scenario.successConditions.length} goals',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Last modified
              Text(
                'Modified ${_formatDate(lastModified)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(ScenarioDifficulty difficulty) {
    switch (difficulty) {
      case ScenarioDifficulty.easy:
        return Colors.green;
      case ScenarioDifficulty.medium:
        return Colors.orange;
      case ScenarioDifficulty.hard:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
