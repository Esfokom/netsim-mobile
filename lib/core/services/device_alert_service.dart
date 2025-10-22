import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:netsim_mobile/features/devices/data/models/device_model.dart';
import 'package:netsim_mobile/core/widgets/root_scaffold.dart';

enum AlertType { positive, negative }

class DeviceAlert {
  final String deviceType;
  final String deviceId;
  final String message;
  final AlertType type;
  final double? percentageChange;

  DeviceAlert({
    required this.deviceType,
    required this.deviceId,
    required this.message,
    required this.type,
    this.percentageChange,
  });
}

class DeviceAlertService {
  static final DeviceAlertService _instance = DeviceAlertService._internal();
  factory DeviceAlertService() => _instance;
  DeviceAlertService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<DeviceAlert> _alertQueue = [];
  bool _isProcessingQueue = false;

  /// Analyzes device changes and adds alerts to the queue
  Future<void> analyzeDeviceChanges(
    Device oldDevice,
    Device newDevice,
    BuildContext context,
  ) async {
    debugPrint(
      '🔍 [DeviceAlertService] Starting analysis for device: ${newDevice.type} (ID: ${newDevice.id})',
    );
    debugPrint('🔍 [DeviceAlertService] Context mounted: ${context.mounted}');

    _alertQueue.clear();
    debugPrint('🔍 [DeviceAlertService] Alert queue cleared');

    // 1. Check online/offline status
    if (oldDevice.status.online != newDevice.status.online) {
      debugPrint(
        '✅ [DeviceAlertService] Online status changed: ${oldDevice.status.online} -> ${newDevice.status.online}',
      );
      _alertQueue.add(
        DeviceAlert(
          deviceType: newDevice.type,
          deviceId: newDevice.id,
          message: newDevice.status.online
              ? 'Device is now ONLINE'
              : 'Device is now OFFLINE',
          type: newDevice.status.online
              ? AlertType.positive
              : AlertType.negative,
        ),
      );
    }

    // 2. Check latency threshold
    if (oldDevice.parameters.latencyThreshold !=
        newDevice.parameters.latencyThreshold) {
      final oldValue = oldDevice.parameters.latencyThreshold;
      final newValue = newDevice.parameters.latencyThreshold;
      final change = newValue - oldValue;
      final percentChange = ((change / oldValue) * 100).abs();

      debugPrint(
        '✅ [DeviceAlertService] Latency threshold changed: $oldValue -> $newValue (${percentChange.toStringAsFixed(1)}%)',
      );

      _alertQueue.add(
        DeviceAlert(
          deviceType: newDevice.type,
          deviceId: newDevice.id,
          message: change < 0
              ? 'Latency threshold decreased to ${newValue}ms'
              : 'Latency threshold increased to ${newValue}ms',
          type: change < 0 ? AlertType.positive : AlertType.negative,
          percentageChange: percentChange,
        ),
      );
    }

    // 3. Check ping interval
    if (oldDevice.parameters.pingInterval !=
        newDevice.parameters.pingInterval) {
      final oldValue = oldDevice.parameters.pingInterval;
      final newValue = newDevice.parameters.pingInterval;
      final change = newValue - oldValue;
      final percentChange = ((change / oldValue) * 100).abs();

      debugPrint(
        '✅ [DeviceAlertService] Ping interval changed: $oldValue -> $newValue (${percentChange.toStringAsFixed(1)}%)',
      );

      _alertQueue.add(
        DeviceAlert(
          deviceType: newDevice.type,
          deviceId: newDevice.id,
          message: change < 0
              ? 'Ping interval decreased to ${newValue}ms'
              : 'Ping interval increased to ${newValue}ms',
          type: change < 0 ? AlertType.positive : AlertType.negative,
          percentageChange: percentChange,
        ),
      );
    }

    // 4. Check failure probability
    if (oldDevice.parameters.failureProbability !=
        newDevice.parameters.failureProbability) {
      final oldValue = oldDevice.parameters.failureProbability;
      final newValue = newDevice.parameters.failureProbability;
      final change = newValue - oldValue;
      final percentChange = oldValue > 0
          ? ((change / oldValue) * 100).abs()
          : 0.0;

      debugPrint(
        '✅ [DeviceAlertService] Failure probability changed: $oldValue -> $newValue (${percentChange.toStringAsFixed(1)}%)',
      );

      _alertQueue.add(
        DeviceAlert(
          deviceType: newDevice.type,
          deviceId: newDevice.id,
          message: change < 0
              ? 'Failure probability decreased to ${(newValue * 100).toStringAsFixed(1)}%'
              : 'Failure probability increased to ${(newValue * 100).toStringAsFixed(1)}%',
          type: change < 0 ? AlertType.positive : AlertType.negative,
          percentageChange: percentChange,
        ),
      );
    }

    // 5. Check traffic load
    if (oldDevice.parameters.trafficLoad != newDevice.parameters.trafficLoad) {
      final oldValue = oldDevice.parameters.trafficLoad;
      final newValue = newDevice.parameters.trafficLoad;
      final change = newValue - oldValue;
      final percentChange = oldValue > 0
          ? ((change / oldValue) * 100).abs()
          : 0.0;

      debugPrint(
        '✅ [DeviceAlertService] Traffic load changed: $oldValue -> $newValue (${percentChange.toStringAsFixed(1)}%)',
      );

      _alertQueue.add(
        DeviceAlert(
          deviceType: newDevice.type,
          deviceId: newDevice.id,
          message: change < 0
              ? 'Traffic load decreased to $newValue'
              : 'Traffic load increased to $newValue',
          type: change > 0 ? AlertType.positive : AlertType.negative,
          percentageChange: percentChange,
        ),
      );
    }

    debugPrint(
      '📊 [DeviceAlertService] Total alerts in queue: ${_alertQueue.length}',
    );

    // Start processing the queue
    if (_alertQueue.isNotEmpty && !_isProcessingQueue) {
      debugPrint('🚀 [DeviceAlertService] Starting to process alert queue');
      _processAlertQueue(context);
    } else if (_alertQueue.isEmpty) {
      debugPrint('⚠️ [DeviceAlertService] No changes detected, queue is empty');
    } else if (_isProcessingQueue) {
      debugPrint('⚠️ [DeviceAlertService] Queue is already being processed');
    }
  }

  Future<void> _processAlertQueue(BuildContext context) async {
    debugPrint('🎬 [DeviceAlertService] processAlertQueue started');
    debugPrint('🎬 [DeviceAlertService] Context mounted: ${context.mounted}');

    if (!context.mounted) {
      debugPrint('❌ [DeviceAlertService] Context not mounted, aborting');
      return;
    }

    _isProcessingQueue = true;
    debugPrint('🎬 [DeviceAlertService] Processing flag set to true');

    int alertNumber = 0;
    while (_alertQueue.isNotEmpty) {
      alertNumber++;
      final alert = _alertQueue.removeAt(0);

      debugPrint(
        '📢 [DeviceAlertService] Processing alert $alertNumber of ${alertNumber + _alertQueue.length}',
      );
      debugPrint(
        '📢 [DeviceAlertService] Alert details: ${alert.deviceType} (${alert.deviceId}) - ${alert.message}',
      );
      debugPrint(
        '📢 [DeviceAlertService] Alert type: ${alert.type == AlertType.positive ? "POSITIVE" : "NEGATIVE"}',
      );

      // Play sound
      debugPrint('🔊 [DeviceAlertService] Playing sound...');
      await _playSound(alert.type);
      debugPrint('🔊 [DeviceAlertService] Sound played');

      // Show snackbar using RootScaffold's device alert method
      debugPrint('📱 [DeviceAlertService] Attempting to show snackbar...');
      debugPrint('📱 [DeviceAlertService] Context is: ${context.runtimeType}');
      debugPrint('📱 [DeviceAlertService] Context mounted: ${context.mounted}');

      RootScaffold.showDeviceAlert(
        context: context,
        deviceType: alert.deviceType,
        deviceId: alert.deviceId,
        message: alert.message,
        isPositive: alert.type == AlertType.positive,
        percentageChange: alert.percentageChange,
      );

      debugPrint('✅ [DeviceAlertService] showDeviceAlert called');

      // Wait for 5 seconds before showing the next alert
      debugPrint(
        '⏳ [DeviceAlertService] Waiting 5 seconds before next alert...',
      );
      await Future.delayed(const Duration(seconds: 5));
      debugPrint('⏳ [DeviceAlertService] Wait complete');
    }

    _isProcessingQueue = false;
    debugPrint('🏁 [DeviceAlertService] Alert queue processing complete');
  }

  Future<void> _playSound(AlertType type) async {
    try {
      final soundPath = type == AlertType.positive
          ? 'assets/sounds/positive.wav'
          : 'assets/sounds/negative.wav';

      debugPrint('🔊 [DeviceAlertService] Sound path: $soundPath');

      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource(soundPath.replaceFirst('assets/', '')),
      );
      debugPrint('🔊 [DeviceAlertService] Sound played successfully');
    } catch (e) {
      debugPrint('❌ [DeviceAlertService] Error playing sound: $e');
    }
  }

  void dispose() {
    debugPrint('🗑️ [DeviceAlertService] Disposing service');
    _audioPlayer.dispose();
    _alertQueue.clear();
  }
}
