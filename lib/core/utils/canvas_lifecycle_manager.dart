import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';

import '../../features/canvas/presentation/widgets/network_canvas.dart';

/// Utility class for managing canvas lifecycle operations
/// Handles initialization, cleanup, snapshots, and state restoration
class CanvasLifecycleManager {
  /// Initialize canvas with scenario data
  static Future<void> initializeFromScenario(
    WidgetRef ref,
    String? scenarioId,
  ) async {
    if (scenarioId != null) {
      // Load the specified scenario
      await ref
          .read(scenarioProvider.notifier)
          .loadScenarioFromStorage(scenarioId);

      // Restore canvas state from the loaded scenario
      final scenario = ref.read(scenarioProvider).scenario;
      if (scenario.initialDeviceStates.isNotEmpty ||
          scenario.initialLinks.isNotEmpty) {
        ref.read(canvasProvider.notifier).clearCanvas();

        // Restore devices
        for (final device in scenario.initialDeviceStates) {
          ref.read(canvasProvider.notifier).addDevice(device);
        }

        // Restore links
        for (final link in scenario.initialLinks) {
          ref.read(canvasProvider.notifier).addLink(link);
        }
      }
    } else {
      // Create a new scenario
      ref.read(scenarioProvider.notifier).createNewScenario();
    }
  }

  /// Snapshot current canvas state before mode changes or saving
  static void snapshotCurrentState(WidgetRef ref) {
    final canvasState = ref.read(canvasProvider);
    ref
        .read(scenarioProvider.notifier)
        .snapshotCanvasState(canvasState.devices, canvasState.links);
  }

  /// Perform comprehensive cleanup of canvas and scenario state
  static void performCleanup(WidgetRef ref) {
    try {
      // Clear and dispose canvas state
      ref.read(canvasProvider.notifier).disposeAndClear();

      // Reset scenario state
      ref.read(scenarioProvider.notifier).resetToEmpty();

      // Clear transformation controller from provider
      ref
          .read(canvasTransformationControllerProvider.notifier)
          .clearController();

      appLogger.i('Canvas lifecycle cleanup completed successfully');
    } catch (e) {
      appLogger.e('Error during canvas cleanup', error: e);
      // Continue even if cleanup fails
    }
  }

  /// Safe cleanup method for use in dispose (delays provider modifications)
  static void performSafeCleanup(
    CanvasNotifier? canvasNotifier,
    ScenarioNotifier? scenarioNotifier,
    CanvasTransformationNotifier? transformationNotifier,
  ) {
    try {
      // Delay provider modifications to avoid lifecycle conflicts
      Future(() {
        try {
          canvasNotifier?.disposeAndClear();
        } catch (e) {
          appLogger.d('Canvas cleanup error (ignored): $e');
        }

        try {
          scenarioNotifier?.resetToEmpty();
        } catch (e) {
          appLogger.d('Scenario cleanup error (ignored): $e');
        }

        // Note: We don't clear the transformation controller here as it can cause
        // state updates on disposed widgets. It will be reset when rebuilt.

        appLogger.i('Canvas lifecycle safe cleanup completed successfully');
      });
    } catch (e) {
      appLogger.e('Error during safe cleanup', error: e);
      // Continue with disposal even if cleanup fails
    }
  }

  /// Restore canvas state from a scenario
  static void restoreCanvasFromScenario(
    WidgetRef ref,
    List<dynamic> devices,
    List<dynamic> links,
  ) {
    ref.read(canvasProvider.notifier).clearCanvas();

    // Restore devices
    for (final device in devices) {
      ref.read(canvasProvider.notifier).addDevice(device);
    }

    // Restore links
    for (final link in links) {
      ref.read(canvasProvider.notifier).addLink(link);
    }
  }
}
