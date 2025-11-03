import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/dashboard/presentation/widgets/dashboard_simplified.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/network_canvas.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/device_palette.dart';
import 'package:netsim_mobile/features/scenarios/providers/canvas_provider.dart';

class GameView extends ConsumerStatefulWidget {
  const GameView({super.key});

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView> {
  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider);
    final canvasNotifier = ref.read(canvasProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Simulator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              canvasNotifier.clearCanvas();
            },
            tooltip: 'Clear Canvas',
          ),
          IconButton(
            icon: Icon(
              canvasState.isLinkingMode ? Icons.link_off : Icons.link,
              color: canvasState.isLinkingMode ? Colors.blue : null,
            ),
            onPressed: () {
              if (canvasState.isLinkingMode) {
                canvasNotifier.cancelLinking();
              }
            },
            tooltip: canvasState.isLinkingMode ? 'Cancel Linking' : 'Link Mode',
          ),
        ],
      ),
      body: Column(
        children: [
          // Dashboard at the top
          const DashboardSimplified(),

          // Canvas in the middle (expandable)
          const Expanded(child: NetworkCanvas()),

          // Device palette at the bottom
          const DevicePalette(),
        ],
      ),
    );
  }
}
