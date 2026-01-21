import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/alert_notification.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';

/// State for alert notifications
class AlertNotificationState {
  final List<AlertNotification> alertQueue;
  final List<AlertNotification> alertHistory;
  final AlertNotification? currentAlert;
  final bool isShowingAlert;

  const AlertNotificationState({
    this.alertQueue = const [],
    this.alertHistory = const [],
    this.currentAlert,
    this.isShowingAlert = false,
  });

  AlertNotificationState copyWith({
    List<AlertNotification>? alertQueue,
    List<AlertNotification>? alertHistory,
    AlertNotification? currentAlert,
    bool? isShowingAlert,
    bool clearCurrentAlert = false,
  }) {
    return AlertNotificationState(
      alertQueue: alertQueue ?? this.alertQueue,
      alertHistory: alertHistory ?? this.alertHistory,
      currentAlert: clearCurrentAlert
          ? null
          : (currentAlert ?? this.currentAlert),
      isShowingAlert: isShowingAlert ?? this.isShowingAlert,
    );
  }
}

/// Provider for managing alert notifications
class AlertNotificationNotifier extends Notifier<AlertNotificationState> {
  @override
  AlertNotificationState build() => const AlertNotificationState();

  /// Add an alert to the queue (prepend to front)
  void addAlert(AlertNotification alert) {
    appLogger.d('[AlertNotification] Adding alert: ${alert.title}');

    final updatedQueue = [alert, ...state.alertQueue];
    final updatedHistory = [alert, ...state.alertHistory];

    state = state.copyWith(
      alertQueue: updatedQueue,
      alertHistory: updatedHistory,
    );

    // If no alert is currently showing, show this one
    if (!state.isShowingAlert) {
      _showNextAlert();
    }
  }

  /// Show the next alert from the queue
  void _showNextAlert() {
    if (state.alertQueue.isEmpty) {
      appLogger.d('[AlertNotification] No more alerts in queue');
      state = state.copyWith(clearCurrentAlert: true, isShowingAlert: false);
      return;
    }

    final nextAlert = state.alertQueue.first;
    final remainingQueue = state.alertQueue.sublist(1);

    appLogger.d('[AlertNotification] Showing alert: ${nextAlert.title}');

    state = state.copyWith(
      currentAlert: nextAlert,
      alertQueue: remainingQueue,
      isShowingAlert: true,
    );
  }

  /// Dismiss the current alert and show next
  void dismissCurrentAlert() {
    appLogger.d('[AlertNotification] Dismissing current alert');
    _showNextAlert();
  }

  /// Clear all alerts from queue (but keep history)
  void clearQueue() {
    appLogger.d('[AlertNotification] Clearing alert queue');
    state = state.copyWith(
      alertQueue: [],
      clearCurrentAlert: true,
      isShowingAlert: false,
    );
  }

  /// Clear alert history
  void clearHistory() {
    appLogger.d('[AlertNotification] Clearing alert history');
    state = state.copyWith(alertHistory: []);
  }

  /// Clear all alerts (queue and history)
  void clearAll() {
    appLogger.d('[AlertNotification] Clearing all alerts');
    state = const AlertNotificationState();
  }

  /// Helper method to create and add protocol event alerts
  void addProtocolEventAlert({
    required String title,
    required String message,
    required AlertType type,
    String? sourceDeviceId,
    String? sourceDeviceName,
    String? targetDeviceId,
    String? targetDeviceName,
    String? protocolType,
    int? responseTimeMs,
    Map<String, dynamic> details = const {},
  }) {
    final alert = AlertNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      sourceDeviceId: sourceDeviceId,
      sourceDeviceName: sourceDeviceName,
      targetDeviceId: targetDeviceId,
      targetDeviceName: targetDeviceName,
      protocolType: protocolType,
      responseTimeMs: responseTimeMs,
      details: details,
    );

    addAlert(alert);
  }
}

/// Provider instance
final alertNotificationProvider =
    NotifierProvider<AlertNotificationNotifier, AlertNotificationState>(
      AlertNotificationNotifier.new,
    );
