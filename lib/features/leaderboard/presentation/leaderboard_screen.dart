import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../logic/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        //title: const Text('Leaderboard'),
        //centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ShadCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Leaderboard",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Top performers based on monitoring efficiency and issue resolution",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            leaderboardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(
                    child: Text('No leaderboard data found.'),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ShadCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text(
                                " Top Players",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Text(
                              "Scores",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        const Divider(height: 1),
                        ...List.generate(entries.length, (index) {
                          final entry = entries[index];
                          final rank = index + 1;

                          IconData? icon;
                          Color? color;
                          switch (rank) {
                            case 1:
                              icon = Icons.emoji_events;
                              color = Colors.amber;
                              break;
                            case 2:
                              icon = Icons.workspace_premium_sharp;
                              color = Colors.grey;
                              break;
                            case 3:
                              icon = Icons.military_tech;
                              color = Colors.brown;
                              break;
                            default:
                              icon = Icons.person;
                              color = Colors.blueGrey;
                          }

                          return Column(
                            children: [
                              ListTile(
                                leading: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4.0,
                                    bottom: 4.0,
                                    right: 15.0,
                                  ),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: color.withValues(
                                      alpha: 0.2,
                                    ),
                                    child: Icon(icon, color: color, size: 22),
                                  ),
                                ),

                                title: Text(
                                  entry.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Rank #$rank',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: Text(
                                  '${entry.score}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: rank == 1
                                        ? Colors.amber
                                        : rank == 2
                                        ? Colors.grey
                                        : rank == 3
                                        ? Colors.brown
                                        : Colors.blue,
                                  ),
                                ),
                              ),
                              if (rank != entries.length)
                                const Divider(height: 1),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
