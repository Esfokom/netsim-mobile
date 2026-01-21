import 'package:netsim_mobile/features/logs/data/services/log_services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';
import '../data/models/log_model.dart';
import '../data/models/log_state_model.dart';

final logsFutureProvider = FutureProvider<List<LogModel>>((ref) async {
  var logs = await LogServices.fetchLogs();
  ref.read(logsProvider.notifier).setLogs(logs);
  return logs;
});

class LogNotifier extends StateNotifier<LogState> {
  LogNotifier() : super(LogState(logs: [], filteredLogs: [], page: 10));
  void setLogs(List<LogModel> logs) {
    state = state.copyWith(logs: logs);
    applyFilters();
  }

  void applyFilters() {
    List<LogModel> filtered = state.logs;

    if (state.statusFilter != null && state.statusFilter!.isNotEmpty) {
      filtered = filtered
          .where((log) => log.status == state.statusFilter)
          .toList();
    }

    if (state.eventTypeFilter != null && state.eventTypeFilter!.isNotEmpty) {
      filtered = filtered
          .where((log) => log.eventType == state.eventTypeFilter)
          .toList();
    }

    state = state.copyWith(filteredLogs: filtered);
  }
}

final logsProvider = StateNotifierProvider<LogNotifier, LogState>((ref) {
  return LogNotifier();
});

final latestLogProvider = StateNotifierProvider<LatestLogNotifier, LogModel?>((
  ref,
) {
  final notifier = LatestLogNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

class LatestLogNotifier extends StateNotifier<LogModel?> {
  final Ref ref;
  Timer? _timer;

  LatestLogNotifier(this.ref) : super(null) {
    _loadLatest();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadLatest());
  }

  Future<void> _loadLatest() async {
    try {
      final latest = await LogServices.fetchLatestLog();
      // Update state only when different to avoid unnecessary rebuilds
      if (latest != null && latest != state) {
        state = latest;
      } else if (latest == null && state != null) {
        state = null;
      }
    } catch (e) {
      debugPrint('Error fetching latest log: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final latestLogsProvider =
    StateNotifierProvider<LatestLogsNotifier, List<LogModel>>((ref) {
      final notifier = LatestLogsNotifier(ref);
      ref.onDispose(() => notifier.dispose());
      return notifier;
    });

class LatestLogsNotifier extends StateNotifier<List<LogModel>> {
  final Ref ref;
  Timer? _timer;

  static const int initialSeedCount = 20;

  LatestLogsNotifier(this.ref) : super([]) {
    _seedInitialLogs();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadLatest());
  }

  Future<void> _seedInitialLogs() async {
    try {
      final all = await LogServices.fetchLogs();
      if (all.isEmpty) return;
      all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      // take the most recent N
      final seed = all.take(initialSeedCount).toList();
      state = seed;
    } catch (e) {
      debugPrint('Error seeding initial logs: $e');
    }
  }

  Future<void> _loadLatest() async {
    try {
      final latest = await LogServices.fetchLatestLog();
      if (latest == null) return;

      if (state.isEmpty || latest.id != state.first.id) {
        state = [latest, ...state];
      }
    } catch (e) {
      debugPrint('Error fetching latest for list: $e');
    }
  }

  /// Clear all stored logs
  void clearAll() {
    state = <LogModel>[];
  }

  Future<void> loadMore({int count = 20}) async {
    try {
      final all = await LogServices.fetchLogs();
      if (all.isEmpty) return;
      all.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final existingIds = state.map((e) => e.id).toSet();

      // Collect logs not already present
      final newOnes = <LogModel>[];
      for (final log in all) {
        if (existingIds.contains(log.id)) continue;
        newOnes.add(log);
      }

      if (newOnes.isEmpty) return;

      // Append older logs after the existing newest-first list
      state = [...state, ...newOnes.take(count)];
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error loading more logs: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
