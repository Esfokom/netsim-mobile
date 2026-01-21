import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:netsim_mobile/features/leaderboard/data/model/leaderboard_entry.dart';

class LeaderboardDataSource {
  Future<List<LeaderboardEntry>> loadLeaderboard() async {
    final jsonStr = await rootBundle.loadString('assets/data/leaderboard.json');
    final List<dynamic> data = json.decode(jsonStr);
    return data.map((e) => LeaderboardEntry.fromJson(e)).toList();
  }
}
