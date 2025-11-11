import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/data/models/network_scenario.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/network_canvas.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/canvas_minimap.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/contextual_editor.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/game/presentation/widgets/game_timer.dart';
import 'package:netsim_mobile/features/game/presentation/widgets/success_screen.dart';

class GamePlayScreen extends ConsumerStatefulWidget {
  final NetworkScenario scenario;

  const GamePlayScreen({super.key, required this.scenario});

  @override
  ConsumerState<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends ConsumerState<GamePlayScreen> {
  Timer? _conditionCheckTimer;
  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  bool _isGameCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    _conditionCheckTimer?.cancel();
    _gameTimer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load the scenario into the scenario provider
      ref.read(scenarioProvider.notifier).loadScenario(widget.scenario);

      // Clear canvas and restore initial state
      ref.read(canvasProvider.notifier).clearCanvas();

      // Restore devices
      for (final device in widget.scenario.initialDeviceStates) {
        ref.read(canvasProvider.notifier).addDevice(device);
      }

      // Restore links
      for (final link in widget.scenario.initialLinks) {
        ref.read(canvasProvider.notifier).addLink(link);
      }

      // Enter simulation mode
      ref.read(scenarioProvider.notifier).enterSimulationMode();

      // Start the game timer
      _startGameTimer();

      // Start automatic condition checking
      _startConditionChecking();
    });
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isGameCompleted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _startConditionChecking() {
    // Check conditions every 2 seconds
    _conditionCheckTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      if (_isGameCompleted) return;

      final results = await ref
          .read(scenarioProvider.notifier)
          .checkSuccessConditions(ref);

      print('[GamePlayScreen] Condition check results: $results');

      // Only check if we have conditions
      if (results.isNotEmpty) {
        final allPassed = results.values.every((passed) => passed);
        print('[GamePlayScreen] All conditions passed: $allPassed');

        if (allPassed) {
          print('[GamePlayScreen] Game completed! Showing success screen...');
          _onGameCompleted();
        }
      }
    });
  }

  void _onGameCompleted() {
    print('[GamePlayScreen] _onGameCompleted called');

    setState(() {
      _isGameCompleted = true;
    });

    _conditionCheckTimer?.cancel();
    _gameTimer?.cancel();

    print('[GamePlayScreen] Timers cancelled, showing dialog...');

    // Ensure we're still mounted before showing dialog
    if (!mounted) {
      print('[GamePlayScreen] Widget not mounted, cannot show dialog');
      return;
    }

    // Show success screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        print('[GamePlayScreen] Building SuccessScreen dialog');
        return SuccessScreen(
          scenario: widget.scenario,
          completionTime: _elapsedSeconds,
          onContinue: () {
            Navigator.of(context).pop(); // Close success dialog
            Navigator.of(context).pop(); // Return to game screen
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transformationController = ref.watch(
      canvasTransformationControllerProvider,
    );

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            // Canvas (full screen background)
            const NetworkCanvas(),

            // Game UI overlay
            _buildGameUI(transformationController),
          ],
        ),
      ),
    );
  }

  Widget _buildGameUI(TransformationController? transformationController) {
    return Stack(
      children: [
        // Game header with timer and scenario info
        Positioned(top: 0, left: 0, right: 0, child: _buildGameHeader()),

        // Minimap
        if (_isControllerValid(transformationController))
          Positioned(
            top: 180,
            right: 16,
            child: CanvasMinimap(
              transformationController: transformationController!,
              canvasSize: const Size(2000, 2000),
            ),
          ),

        // Bottom panel with device properties
        Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),
      ],
    );
  }

  Widget _buildGameHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'PLAYING',
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
              GameTimer(elapsedSeconds: _elapsedSeconds),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _showPauseMenu,
                icon: const Icon(Icons.pause),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.scenario.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.scenario.description,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          _buildObjectivesList(),
        ],
      ),
    );
  }

  Widget _buildObjectivesList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              Text(
                'Objectives',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.scenario.successConditions.map(
            (condition) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.radio_button_unchecked,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      condition.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    'Actions based on rules',
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
    );
  }

  void _showPauseMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Paused'),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Resume'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close pause dialog
              Navigator.pop(context); // Return to game screen
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }

  bool _isControllerValid(TransformationController? controller) {
    if (controller == null) return false;
    try {
      controller.value;
      return true;
    } catch (e) {
      return false;
    }
  }
}
