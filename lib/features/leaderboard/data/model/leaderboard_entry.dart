class LeaderboardEntry {
  final String name;
  final int score;

  LeaderboardEntry({required this.name, required this.score});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      name: json['name'] ?? 'Unknown',
      score: (json['score'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
      };
}
