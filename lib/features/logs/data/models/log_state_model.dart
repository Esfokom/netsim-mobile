// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:netsim_mobile/features/logs/data/models/log_model.dart';

class LogState {
  final List<LogModel> logs;
  final List<LogModel> filteredLogs;
  final int page;
  final String? statusFilter;
  final String? eventTypeFilter;
  LogState({
    required this.logs,
    required this.filteredLogs,
    required this.page,
    this.statusFilter,
    this.eventTypeFilter,
  });

  LogState copyWith({
    List<LogModel>? logs,
    List<LogModel>? filteredLogs,
    int? page,
    String? statusFilter,
    String? eventTypeFilter,
  }) {
    return LogState(
      logs: logs ?? this.logs,
      filteredLogs: filteredLogs ?? this.filteredLogs,
      page: page ?? this.page,
      statusFilter: statusFilter ?? this.statusFilter,
      eventTypeFilter: eventTypeFilter ?? this.eventTypeFilter,
    );
  }
}
