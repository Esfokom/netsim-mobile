import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/network_canvas.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/canvas_minimap.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/device_palette.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/scenario_bottom_panel.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/contextual_editor.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/conditions_editor.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';

class GameView extends ConsumerStatefulWidget {
  const GameView({super.key});

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView> {
  @override
  void initState() {
    super.initState();
    // Initialize a new scenario when the game view opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scenarioProvider.notifier).createNewScenario();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transformationController = ref.watch(
      canvasTransformationControllerProvider,
    );
    final scenarioState = ref.watch(scenarioProvider);
    final canvasState = ref.watch(canvasProvider);

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            // Canvas (full screen background)
            const NetworkCanvas(),

            // Mode-specific UI
            if (scenarioState.mode == ScenarioMode.edit)
              _buildEditModeUI(transformationController, canvasState)
            else
              _buildSimulationModeUI(transformationController),
          ],
        ),
      ),
    );
  }

  Widget _buildEditModeUI(
    TransformationController? transformationController,
    CanvasState canvasState,
  ) {
    return Stack(
      children: [
        // Dashboard at the top (floating)
        Positioned(top: 0, left: 0, right: 0, child: _buildEditModeHeader()),

        // Minimap below dashboard at the top-right
        if (transformationController != null)
          Positioned(
            top: 130, // Below the dashboard
            right: 16,
            child: CanvasMinimap(
              transformationController: transformationController,
              canvasSize: const Size(2000, 2000),
            ),
          ),

        // Bottom panel with tabs (devices, properties, conditions)
        ScenarioBottomPanel(
          devicesContent: const DevicePalette(),
          propertiesContent: const ContextualEditor(),
          conditionsContent: const ConditionsEditor(),
        ),
      ],
    );
  }

  Widget _buildEditModeHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () {
          _showEditModeDetails();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'EDIT MODE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.expand_more,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final scenario = ref.watch(scenarioProvider).scenario;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scenario.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditModeDetails() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'EDIT MODE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, _) {
                  final scenario = ref.watch(scenarioProvider).scenario;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              scenario.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scenario.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Difficulty: ${scenario.difficulty.name.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _saveScenario();
                    },
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _exportScenario();
                    },
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Export JSON'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _runSimulation();
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Run Simulation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Save the context for later use
                      final navigator = Navigator.of(context);

                      // Close details dialog first
                      navigator.pop();

                      final shouldExit = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Exit Game View'),
                          content: const Text(
                            'Are you sure you want to exit? Any unsaved changes will be lost.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Exit'),
                            ),
                          ],
                        ),
                      );

                      if (shouldExit == true && mounted) {
                        navigator.pop(); // Exit game view
                      }
                    },
                    icon: const Icon(Icons.exit_to_app, size: 18),
                    label: const Text('Exit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationModeUI(
    TransformationController? transformationController,
  ) {
    return Stack(
      children: [
        // Simulation header
        Positioned(top: 0, left: 0, right: 0, child: _buildSimulationHeader()),

        // Minimap
        if (transformationController != null)
          Positioned(
            top: 150,
            right: 16,
            child: CanvasMinimap(
              transformationController: transformationController,
              canvasSize: const Size(2000, 2000),
            ),
          ),

        // Bottom panel with contextual editor (properties only)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Tab bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Device Properties',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          'Read-only based on rules',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Properties content
                const Expanded(child: ContextualEditor(simulationMode: true)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.play_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'SIMULATION MODE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _exitSimulation,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Back to Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final scenario = ref.watch(scenarioProvider).scenario;
                return Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scenario.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scenario.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    ElevatedButton.icon(
                      onPressed: _checkSolution,
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Run'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _runSimulation() {
    final canvasState = ref.read(canvasProvider);

    // Snapshot current canvas state
    ref
        .read(scenarioProvider.notifier)
        .snapshotCanvasState(canvasState.devices, canvasState.links);

    // Enter simulation mode
    ref.read(scenarioProvider.notifier).enterSimulationMode();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulation started! Try to complete the objectives.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exitSimulation() {
    ref.read(scenarioProvider.notifier).exitSimulationMode();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Returned to edit mode')));
  }

  Future<void> _checkSolution() async {
    final results = await ref
        .read(scenarioProvider.notifier)
        .checkSuccessConditions(ref);

    final allPassed = results.values.every((passed) => passed);
    final passedCount = results.values.where((passed) => passed).length;
    final totalCount = results.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              allPassed ? Icons.check_circle : Icons.error,
              color: allPassed ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(allPassed ? 'Success!' : 'Not Quite Yet'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              allPassed
                  ? 'Congratulations! You\'ve completed all objectives!'
                  : 'You\'ve completed $passedCount out of $totalCount conditions.',
            ),
            const SizedBox(height: 16),
            ...results.entries.map((entry) {
              final condition = ref
                  .read(scenarioProvider)
                  .scenario
                  .successConditions
                  .firstWhere((c) => c.id == entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      entry.value ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: entry.value ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        condition.description,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _saveScenario() async {
    final canvasState = ref.read(canvasProvider);

    // Snapshot current canvas state before saving
    ref
        .read(scenarioProvider.notifier)
        .snapshotCanvasState(canvasState.devices, canvasState.links);

    // Persist to storage
    final success = await ref.read(scenarioProvider.notifier).persistScenario();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Scenario saved successfully!' : 'Failed to save scenario',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _exportScenario() {
    final json = ref.read(scenarioProvider.notifier).exportToJson();
    final prettyJson = const JsonEncoder.withIndent('  ').convert(json);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scenario JSON'),
        content: SingleChildScrollView(
          child: SelectableText(
            prettyJson,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
