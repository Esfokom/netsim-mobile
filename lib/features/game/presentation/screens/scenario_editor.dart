import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/tomorrow.dart';
import 'package:flutter_highlight/themes/tomorrow-night.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/network_canvas.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/canvas_minimap.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/devices/presentation/widgets/device_palette.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/contextual_editor.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/conditions_editor.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/scenario_properties_editor.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/ping_bottom_sheet.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/game/presentation/providers/game_condition_checker.dart';
import 'package:netsim_mobile/features/game/presentation/widgets/mode_header_widget.dart';
import 'package:netsim_mobile/core/utils/canvas_lifecycle_manager.dart';
import 'package:netsim_mobile/core/utils/controller_validator.dart';

class ScenarioEditor extends ConsumerStatefulWidget {
  final String? scenarioId; // Optional scenario ID to load

  const ScenarioEditor({super.key, this.scenarioId});

  @override
  ConsumerState<ScenarioEditor> createState() => _ScenarioEditorState();
}

/// Enum for different bottom panel types
enum BottomPanelType {
  addDevice,
  deviceProperties,
  scenarioProperties,
  conditionsEditor,
  pingTest,
}

class _ScenarioEditorState extends ConsumerState<ScenarioEditor> {
  // Save notifier references for safe disposal
  CanvasNotifier? _canvasNotifier;
  ScenarioNotifier? _scenarioNotifier;
  CanvasTransformationNotifier? _transformationNotifier;

  // FAB and panel state
  bool _showBottomPanel = false;
  bool _showSpeedDial = false;
  BottomPanelType? _currentPanelType;

  @override
  void initState() {
    super.initState();

    // Save notifier references for safe disposal
    _canvasNotifier = ref.read(canvasProvider.notifier);
    _scenarioNotifier = ref.read(scenarioProvider.notifier);
    _transformationNotifier = ref.read(
      canvasTransformationControllerProvider.notifier,
    );

    // Initialize scenario using lifecycle manager
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await CanvasLifecycleManager.initializeFromScenario(
        ref,
        widget.scenarioId,
      );
    });
  }

  @override
  void dispose() {
    // Perform cleanup when widget is disposed using saved references
    _performCleanupSafely();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transformationController = ref.watch(
      canvasTransformationControllerProvider,
    );
    final scenarioState = ref.watch(scenarioProvider);
    final canvasState = ref.watch(canvasProvider);

    // Listen for mode changes and close panels
    ref.listen<ScenarioState>(scenarioProvider, (previous, next) {
      if (previous?.mode != next.mode) {
        // Close any open panels when mode changes
        if (_showBottomPanel) {
          _closePanel();
        }
        if (_showSpeedDial) {
          setState(() {
            _showSpeedDial = false;
          });
        }
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
        if (ControllerValidator.isValid(transformationController))
          Positioned(
            top: 130, // Below the dashboard
            right: 16,
            child: CanvasMinimap(
              transformationController: transformationController!,
              canvasSize: const Size(2000, 2000),
            ),
          ),

        // Conditional bottom panel
        if (_showBottomPanel && _currentPanelType != null)
          Positioned(bottom: 0, left: 0, right: 0, child: _buildCurrentPanel()),

        // FAB (hidden when panel is open)
        if (!_showBottomPanel) _buildFloatingActionButton(),
      ],
    );
  }

  Widget _buildEditModeHeader() {
    final scenario = ref.watch(scenarioProvider).scenario;
    return ModeHeaderWidget(
      mode: HeaderMode.edit,
      title: scenario.title,
      description: scenario.description,
      isCollapsible: true,
      onTap: _showEditModeDetails,
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
                        // Cleanup all state before exiting
                        _performCleanup();
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
        if (ControllerValidator.isValid(transformationController))
          Positioned(
            top: 150,
            right: 16,
            child: CanvasMinimap(
              transformationController: transformationController!,
              canvasSize: const Size(2000, 2000),
            ),
          ),

        // Conditional bottom panel
        if (_showBottomPanel &&
            _currentPanelType == BottomPanelType.deviceProperties)
          Positioned(bottom: 0, left: 0, right: 0, child: _buildCurrentPanel()),

        // FAB (hidden when panel is open)
        if (!_showBottomPanel) _buildFloatingActionButton(),
      ],
    );
  }

  Widget _buildSimulationHeader() {
    final scenario = ref.watch(scenarioProvider).scenario;
    return ModeHeaderWidget(
      mode: HeaderMode.simulation,
      title: scenario.title,
      description: scenario.description,
      actions: [
        TextButton.icon(
          onPressed: _exitSimulation,
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Back to Edit'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _checkSolution,
          icon: const Icon(Icons.check_circle, size: 16),
          label: const Text('Run'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
        ),
      ],
    );
  }

  void _runSimulation() {
    // Snapshot current canvas state using lifecycle manager
    CanvasLifecycleManager.snapshotCurrentState(ref);

    // Initialize network devices from canvas devices (CRITICAL for condition checking)
    ref.read(canvasProvider.notifier).initializeNetworkDevicesFromCanvas();

    // Enter simulation mode
    ref.read(scenarioProvider.notifier).enterSimulationMode();

    // PHASE 2 FIX: Initialize all device connections from links
    ref.read(canvasProvider.notifier).initializeAllConnections();

    // Trigger initial condition check
    ref.read(gameConditionCheckerProvider.notifier).triggerConditionCheck();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulation started! Try to complete the objectives.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exitSimulation() {
    // Exit simulation mode first
    ref.read(scenarioProvider.notifier).exitSimulationMode();

    // Clear condition check results when exiting simulation
    ref.read(gameConditionCheckerProvider.notifier).clearResults();

    // Clear network devices cache to force re-initialization next time
    ref.read(canvasProvider.notifier).clearNetworkDevicesCache();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Returned to edit mode')));
  }

  Future<void> _checkSolution() async {
    final results = await ref.read(scenarioProvider.notifier).checkConditions();

    final allPassed = results.values.every((passed) => passed);
    final passedCount = results.values.where((passed) => passed).length;
    final totalCount = results.length;

    if (!mounted) return;

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
    // Snapshot current canvas state before saving using lifecycle manager
    CanvasLifecycleManager.snapshotCurrentState(ref);

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
    // Take a snapshot of current canvas state before exporting using lifecycle manager
    CanvasLifecycleManager.snapshotCurrentState(ref);

    final json = ref.read(scenarioProvider.notifier).exportToJson();
    final prettyJson = const JsonEncoder.withIndent('  ').convert(json);
    const name = 'json';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scenario JSON'),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : const Color(0xff1d1f21),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header bar with language name and copy button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.inverseSurface.withAlpha(30),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.inverseSurface.withAlpha(200),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: prettyJson));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied to clipboard'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.clipboard),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                // Horizontally scrollable highlight view
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    dragStartBehavior: DragStartBehavior.start,
                    clipBehavior: Clip.antiAlias,
                    physics: const BouncingScrollPhysics(),
                    child: SingleChildScrollView(
                      child: HighlightView(
                        prettyJson,
                        padding: const EdgeInsets.all(16),
                        language: name,
                        theme: Theme.of(context).brightness == Brightness.light
                            ? tomorrowTheme
                            : tomorrowNightTheme,
                        textStyle: const TextStyle(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

  // ============ FAB AND PANEL MANAGEMENT ============

  Widget _buildFloatingActionButton() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Speed dial options (shown when FAB is tapped)
          if (_showSpeedDial) ...[
            _buildSpeedDialOptions(),
            const SizedBox(height: 12),
          ],
          // Main FAB
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _showSpeedDial = !_showSpeedDial;
              });
            },
            child: AnimatedRotation(
              turns: _showSpeedDial ? 0.125 : 0, // 45 degrees when open
              duration: const Duration(milliseconds: 200),
              child: Icon(_showSpeedDial ? Icons.close : Icons.menu),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDialOptions() {
    final scenarioState = ref.watch(scenarioProvider);

    if (scenarioState.mode == ScenarioMode.simulation) {
      // Simulation mode: Device properties and Ping Test
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildSpeedDialOption(
            icon: Icons.settings,
            label: 'Device Properties',
            onTap: () => _openPanel(BottomPanelType.deviceProperties),
          ),
          const SizedBox(height: 12),
          _buildSpeedDialOption(
            icon: Icons.network_ping,
            label: 'Ping Test',
            onTap: () => _openPanel(BottomPanelType.pingTest),
          ),
        ],
      );
    } else {
      // Edit mode: All options including Ping Test
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildSpeedDialOption(
            icon: Icons.add_circle,
            label: 'Add Device',
            onTap: () => _openPanel(BottomPanelType.addDevice),
          ),
          const SizedBox(height: 12),
          _buildSpeedDialOption(
            icon: Icons.settings,
            label: 'Device Properties',
            onTap: () => _openPanel(BottomPanelType.deviceProperties),
          ),
          const SizedBox(height: 12),
          _buildSpeedDialOption(
            icon: Icons.edit_note,
            label: 'Scenario Properties',
            onTap: () => _openPanel(BottomPanelType.scenarioProperties),
          ),
          const SizedBox(height: 12),
          _buildSpeedDialOption(
            icon: Icons.flag,
            label: 'Conditions',
            onTap: () => _openPanel(BottomPanelType.conditionsEditor),
          ),
          const SizedBox(height: 12),
          _buildSpeedDialOption(
            icon: Icons.network_ping,
            label: 'Ping Test',
            onTap: () => _openPanel(BottomPanelType.pingTest),
          ),
        ],
      );
    }
  }

  Widget _buildSpeedDialOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Icon button
        FloatingActionButton.small(
          onPressed: onTap,
          heroTag: label,
          child: Icon(icon),
        ),
      ],
    );
  }

  void _openPanel(BottomPanelType type) {
    setState(() {
      _currentPanelType = type;
      _showBottomPanel = true;
      _showSpeedDial = false; // Close speed dial
    });
  }

  void _closePanel() {
    setState(() {
      _showBottomPanel = false;
      _currentPanelType = null;
    });
  }

  Widget _buildCurrentPanel() {
    if (_currentPanelType == null) return const SizedBox.shrink();

    final scenarioState = ref.watch(scenarioProvider);

    switch (_currentPanelType!) {
      case BottomPanelType.addDevice:
        return _buildPanelWrapper(
          title: 'Add Device',
          icon: Icons.add_circle,
          child: const DevicePalette(),
        );
      case BottomPanelType.deviceProperties:
        return _buildPanelWrapper(
          title: 'Device Properties',
          icon: Icons.settings,
          child: ContextualEditor(
            simulationMode: scenarioState.mode == ScenarioMode.simulation,
          ),
        );
      case BottomPanelType.scenarioProperties:
        return _buildPanelWrapper(
          title: 'Scenario Properties',
          icon: Icons.edit_note,
          child: const ScenarioPropertiesEditor(),
        );
      case BottomPanelType.conditionsEditor:
        return _buildPanelWrapper(
          title: 'Success Conditions',
          icon: Icons.flag,
          child: const ConditionsEditor(),
        );
      case BottomPanelType.pingTest:
        return _buildPingTestPanel();
    }
  }

  Widget _buildPanelWrapper({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      height: 400,
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
          // Header with close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _closePanel,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          // Content
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildPingTestPanel() {
    return Container(
      height: 200, // Compact height for touch-friendly targets
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
          // Header with close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.network_ping,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Ping Test',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _closePanel,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          // Content
          Expanded(child: CompactPingBottomSheet()),
        ],
      ),
    );
  }

  // ============ CLEANUP METHODS ============

  /// Comprehensive cleanup method to dispose resources and clear state
  void _performCleanup() {
    CanvasLifecycleManager.performCleanup(ref);
  }

  /// Safe cleanup method using saved notifier references (for use in dispose)
  void _performCleanupSafely() {
    CanvasLifecycleManager.performSafeCleanup(
      _canvasNotifier,
      _scenarioNotifier,
      _transformationNotifier,
    );
  }
}
