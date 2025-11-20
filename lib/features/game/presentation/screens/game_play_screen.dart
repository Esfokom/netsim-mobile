import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/network_scenario.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/network_canvas.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/canvas_minimap.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/contextual_editor.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/game/presentation/providers/game_condition_checker.dart';
import 'package:netsim_mobile/features/game/presentation/widgets/game_timer.dart';
import 'package:netsim_mobile/features/game/presentation/widgets/success_screen.dart';
import 'package:netsim_mobile/features/game/presentation/widgets/game_objectives_list.dart';
import 'package:netsim_mobile/features/game/presentation/widgets/property_bottom_panel.dart';
import 'package:netsim_mobile/core/utils/canvas_lifecycle_manager.dart';
import 'package:netsim_mobile/core/utils/controller_validator.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';

class GamePlayScreen extends ConsumerStatefulWidget {
  final NetworkScenario scenario;

  const GamePlayScreen({super.key, required this.scenario});

  @override
  ConsumerState<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends ConsumerState<GamePlayScreen> {
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

      // Trigger initial condition check
      ref.read(gameConditionCheckerProvider.notifier).triggerConditionCheck();
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

  void _onGameCompleted() {
    appLogger.i('[GamePlayScreen] _onGameCompleted called');

    setState(() {
      _isGameCompleted = true;
    });

    _gameTimer?.cancel();

    appLogger.d('[GamePlayScreen] Timer cancelled, showing dialog...');

    // Ensure we're still mounted before showing dialog
    if (!mounted) {
      appLogger.w('[GamePlayScreen] Widget not mounted, cannot show dialog');
      return;
    }

    // Show success screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        appLogger.d('[GamePlayScreen] Building SuccessScreen dialog');
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

    // Listen to condition checker state changes
    ref.listen<GameConditionState>(gameConditionCheckerProvider, (
      previous,
      next,
    ) {
      // Check if game is completed and not already showing dialog
      if (!_isGameCompleted &&
          next.allConditionsPassed &&
          next.conditionResults.isNotEmpty) {
        appLogger.i(
          '[GamePlayScreen] All conditions passed! Showing success screen...',
        );
        _onGameCompleted();
      }
    });

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
        // Compact game header with controls
        Positioned(top: 0, left: 0, right: 0, child: _buildGameHeader()),

        // Minimap (adjusted position for smaller header)
        if (ControllerValidator.isValid(transformationController))
          Positioned(
            top: 90,
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
    final conditionState = ref.watch(gameConditionCheckerProvider);
    final totalConditions = widget.scenario.successConditions.length;
    final passedConditions = conditionState.passedCount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // PLAYING badge (left, isolated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle, size: 18, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Text(
                  'PLAYING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Timer (right side with better styling)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GameTimer(elapsedSeconds: _elapsedSeconds),
          ),
          const SizedBox(width: 8),
          // Info button showing condition progress
          Material(
            color: Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _showGameInfo,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$passedConditions/$totalConditions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Pause button
          IconButton(
            onPressed: _showPauseMenu,
            icon: const Icon(Icons.pause, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return PropertyBottomPanel(
      title: 'Device Properties',
      subtitle: 'Actions based on rules',
      child: const ContextualEditor(simulationMode: true),
    );
  }

  void _showGameInfo() {
    final conditionState = ref.read(gameConditionCheckerProvider);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.gamepad,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.scenario.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                widget.scenario.description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              // Objectives header
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Objectives',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Objectives list with real-time status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: GameObjectivesList(
                  conditions: widget.scenario.successConditions,
                  results: conditionState.conditionResults,
                  showStatus: true,
                ),
              ),
            ],
          ),
        ),
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
}
