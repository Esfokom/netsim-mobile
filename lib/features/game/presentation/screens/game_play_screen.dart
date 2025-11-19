import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/network_scenario.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/network_canvas.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/canvas_minimap.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/contextual_editor.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/game/presentation/widgets/game_timer.dart';
import 'package:netsim_mobile/features/game/presentation/widgets/success_screen.dart';
import 'package:netsim_mobile/features/game/presentation/widgets/game_objectives_list.dart';
import 'package:netsim_mobile/features/game/presentation/widgets/property_bottom_panel.dart';
import 'package:netsim_mobile/core/utils/canvas_lifecycle_manager.dart';
import 'package:netsim_mobile/core/utils/controller_validator.dart';

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

      // Restore canvas state using lifecycle manager
      CanvasLifecycleManager.restoreCanvasFromScenario(
        ref,
        widget.scenario.initialDeviceStates,
        widget.scenario.initialLinks,
      );

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
        if (ControllerValidator.isValid(transformationController))
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
          _buildHeaderRow(),
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

  Widget _buildHeaderRow() {
    return Row(
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
      child: GameObjectivesList(conditions: widget.scenario.successConditions),
    );
  }

  Widget _buildBottomPanel() {
    return PropertyBottomPanel(
      title: 'Device Properties',
      subtitle: 'Actions based on rules',
      child: const ContextualEditor(simulationMode: true),
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
}
