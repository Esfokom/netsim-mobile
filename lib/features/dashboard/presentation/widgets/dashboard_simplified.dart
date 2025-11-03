import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';

class DashboardSimplified extends ConsumerWidget {
  const DashboardSimplified({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasState = ref.watch(canvasProvider);

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.inverseSurface,
          ),
          color: Theme.of(context).colorScheme.surface,
        ),
        height: 80,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _StatCard(
                title: "Total Devices",
                value: canvasState.totalDevices.toString(),
                icon: Icons.devices,
                color: Colors.blue,
              ),
            ),
            Expanded(
              child: _StatCard(
                title: "Online",
                value: canvasState.devicesOnline.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            Expanded(
              child: _StatCard(
                title: "Offline",
                value: canvasState.devicesOffline.toString(),
                icon: Icons.cancel,
                color: Colors.grey,
              ),
            ),
            Expanded(
              child: _StatCard(
                title: "Warnings",
                value: canvasState.devicesWithWarning.toString(),
                icon: Icons.warning,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
