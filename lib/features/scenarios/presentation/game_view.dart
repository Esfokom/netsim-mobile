import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/dashboard/presentation/widgets/dashboard_simplified.dart';

class GameView extends StatefulWidget {
  const GameView({super.key});

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InteractiveViewer(
            panEnabled: true,
            child: Column(
              children: [
                Container(width: 200, height: 200, color: Colors.blue),
                Container(width: 200, height: 200, color: Colors.red),
              ],
            ),
          ),
          Align(
            alignment: AlignmentGeometry.bottomCenter,
            child: DashboardSimplified(),
          ),
        ],
      ),
    );
  }
}
