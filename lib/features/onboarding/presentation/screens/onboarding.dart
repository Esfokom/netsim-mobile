import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ShadCard(
            title: Text("Network Simulation Game"),
            child: Column(
              spacing: 15,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadButton(
                  width: double.infinity,
                  leading: Icon(Icons.add),
                  child: Text("Dashboard"),
                  onPressed: () => Navigator.pushNamed(context, "/dashboard"),
                ),
                ShadButton(
                  width: double.infinity,
                  leading: Icon(Icons.add),
                  child: Text("Leaderboard"),
                  onPressed: () => Navigator.pushNamed(context, "/leaderboard"),
                ),
                ShadButton(
                  width: double.infinity,
                  leading: Icon(Icons.new_label),
                  child: Text("Scenarios"),
                  onPressed: () => Navigator.pushNamed(context, "/scenario"),
                ),
                ShadButton(
                  width: double.infinity,
                  leading: Icon(Icons.info),
                  child: Text("Logs"),
                  onPressed: () => Navigator.pushNamed(context, "/logs"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
