import 'package:netsim_mobile/features/logs/data/models/log_model.dart';
import 'package:netsim_mobile/features/logs/data/sources/dummy_logs.dart';

class LogServices {
  /*static final dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:1011/api/', // Replace with your API base URL
    ),
  );
*/
  static Future<List<LogModel>> fetchLogs() async {
    await Future.delayed(const Duration(milliseconds: 10));
    try {
      return logsList
          .map((log) => LogModel.fromMap(Map<String, dynamic>.from(log)))
          .toList();
    } catch (_) {
      return <LogModel>[];
    }
  }

  static Future<LogModel?> fetchLatestLog() async {
    try {
      final all = await fetchLogs();
      if (all.isEmpty) return null;
      // pick a random log
      final rnd = all[DateTime.now().millisecondsSinceEpoch % all.length];
      final simulated = rnd.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
      );
      return simulated;
    } catch (_) {
      return null;
    }
  }
}
