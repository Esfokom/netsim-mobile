import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/leaderboard/data/model/leaderboard_entry.dart';
import '../data/leaderboard_data_source.dart';


final leaderboardDataSourceProvider = Provider<LeaderboardDataSource>((ref) {
  return LeaderboardDataSource();
});

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final dataSource = ref.read(leaderboardDataSourceProvider);
  final entries = await dataSource.loadLeaderboard();

  // Sort by descending score
  entries.sort((a, b) => b.score.compareTo(a.score));
  return entries;
});
