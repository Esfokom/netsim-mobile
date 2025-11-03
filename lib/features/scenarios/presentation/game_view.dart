import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/dashboard/presentation/widgets/dashboard_simplified.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/network_canvas.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/device_palette.dart';

class GameView extends ConsumerStatefulWidget {
  const GameView({super.key});

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Canvas (full screen background)
          const NetworkCanvas(),

          // Dashboard at the top (floating)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DashboardSimplified(),
          ),

          // Device palette at the bottom (floating)
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DevicePalette(),
          ),
        ],
      ),
    );
  }
}
