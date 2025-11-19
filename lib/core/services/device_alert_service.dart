// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:netsim_mobile/features/devices/data/models/device_model.dart';
// import 'package:netsim_mobile/core/widgets/root_scaffold.dart';
//
// enum AlertType { positive, negative }
//
// class DeviceAlert {
//   final String deviceType;
//   final String deviceId;
//   final String message;
//   final AlertType type;
//   final double? percentageChange;
//
//   DeviceAlert({
//     required this.deviceType,
//     required this.deviceId,
//     required this.message,
//     required this.type,
//     this.percentageChange,
//   });
// }
//
// class DeviceAlertService {
//   static final DeviceAlertService _instance = DeviceAlertService._internal();
//   factory DeviceAlertService() => _instance;
//   DeviceAlertService._internal();
//
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   final List<DeviceAlert> _alertQueue = [];
//   bool _isProcessingQueue = false;
//
//   /// Analyzes device changes and adds alerts to the queue
//   Future<void> analyzeDeviceChanges(
//     Device oldDevice,
//     Device newDevice,
//     BuildContext context,
//   ) async {
//     if (!context.mounted) return;
//
//     _alertQueue.clear();
//
//     _checkOnlineStatus(oldDevice, newDevice);
//     _checkLatencyThreshold(oldDevice, newDevice);
//     _checkPingInterval(oldDevice, newDevice);
//     _checkFailureProbability(oldDevice, newDevice);
//     _checkTrafficLoad(oldDevice, newDevice);
//
//     if (_alertQueue.isNotEmpty && !_isProcessingQueue) {
//       _processAlertQueue(context);
//     }
//   }
//
//   void _checkOnlineStatus(Device oldDevice, Device newDevice) {
//     if (oldDevice.status.online != newDevice.status.online) {
//       _alertQueue.add(
//         DeviceAlert(
//           deviceType: newDevice.type,
//           deviceId: newDevice.id,
//           message: newDevice.status.online
//               ? 'Device is now ONLINE'
//               : 'Device is now OFFLINE',
//           type: newDevice.status.online
//               ? AlertType.positive
//               : AlertType.negative,
//         ),
//       );
//     }
//   }
//
//   void _checkLatencyThreshold(Device oldDevice, Device newDevice) {
//     if (oldDevice.parameters.latencyThreshold !=
//         newDevice.parameters.latencyThreshold) {
//       final oldValue = oldDevice.parameters.latencyThreshold;
//       final newValue = newDevice.parameters.latencyThreshold;
//       final change = newValue - oldValue;
//       final percentChange = ((change / oldValue) * 100).abs();
//
//       _alertQueue.add(
//         DeviceAlert(
//           deviceType: newDevice.type,
//           deviceId: newDevice.id,
//           message: change < 0
//               ? 'Latency threshold decreased to ${newValue}ms'
//               : 'Latency threshold increased to ${newValue}ms',
//           type: change < 0 ? AlertType.positive : AlertType.negative,
//           percentageChange: percentChange,
//         ),
//       );
//     }
//   }
//
//   void _checkPingInterval(Device oldDevice, Device newDevice) {
//     if (oldDevice.parameters.pingInterval !=
//         newDevice.parameters.pingInterval) {
//       final oldValue = oldDevice.parameters.pingInterval;
//       final newValue = newDevice.parameters.pingInterval;
//       final change = newValue - oldValue;
//       final percentChange = ((change / oldValue) * 100).abs();
//
//       _alertQueue.add(
//         DeviceAlert(
//           deviceType: newDevice.type,
//           deviceId: newDevice.id,
//           message: change < 0
//               ? 'Ping interval decreased to ${newValue}ms'
//               : 'Ping interval increased to ${newValue}ms',
//           type: change < 0 ? AlertType.positive : AlertType.negative,
//           percentageChange: percentChange,
//         ),
//       );
//     }
//   }
//
//   void _checkFailureProbability(Device oldDevice, Device newDevice) {
//     if (oldDevice.parameters.failureProbability !=
//         newDevice.parameters.failureProbability) {
//       final oldValue = oldDevice.parameters.failureProbability;
//       final newValue = newDevice.parameters.failureProbability;
//       final change = newValue - oldValue;
//       final percentChange = oldValue > 0
//           ? ((change / oldValue) * 100).abs()
//           : 0.0;
//
//       _alertQueue.add(
//         DeviceAlert(
//           deviceType: newDevice.type,
//           deviceId: newDevice.id,
//           message: change < 0
//               ? 'Failure probability decreased to ${(newValue * 100).toStringAsFixed(1)}%'
//               : 'Failure probability increased to ${(newValue * 100).toStringAsFixed(1)}%',
//           type: change < 0 ? AlertType.positive : AlertType.negative,
//           percentageChange: percentChange,
//         ),
//       );
//     }
//   }
//
//   void _checkTrafficLoad(Device oldDevice, Device newDevice) {
//     if (oldDevice.parameters.trafficLoad != newDevice.parameters.trafficLoad) {
//       final oldValue = oldDevice.parameters.trafficLoad;
//       final newValue = newDevice.parameters.trafficLoad;
//       final change = newValue - oldValue;
//       final percentChange = oldValue > 0
//           ? ((change / oldValue) * 100).abs()
//           : 0.0;
//
//       _alertQueue.add(
//         DeviceAlert(
//           deviceType: newDevice.type,
//           deviceId: newDevice.id,
//           message: change < 0
//               ? 'Traffic load decreased to $newValue'
//               : 'Traffic load increased to $newValue',
//           type: change > 0 ? AlertType.positive : AlertType.negative,
//           percentageChange: percentChange,
//         ),
//       );
//     }
//   }
//
//   Future<void> _processAlertQueue(BuildContext context) async {
//     if (!context.mounted) return;
//
//     _isProcessingQueue = true;
//
//     while (_alertQueue.isNotEmpty) {
//       final alert = _alertQueue.removeAt(0);
//
//       await _playSound(alert.type);
//
//       RootScaffold.showDeviceAlert(
//         context: context,
//         deviceType: alert.deviceType,
//         deviceId: alert.deviceId,
//         message: alert.message,
//         isPositive: alert.type == AlertType.positive,
//         percentageChange: alert.percentageChange,
//       );
//
//       await Future.delayed(const Duration(seconds: 5));
//     }
//
//     _isProcessingQueue = false;
//   }
//
//   Future<void> _playSound(AlertType type) async {
//     try {
//       final soundPath = type == AlertType.positive
//           ? 'sounds/positive.wav'
//           : 'sounds/negative.wav';
//
//       await _audioPlayer.stop();
//       await _audioPlayer.play(AssetSource(soundPath));
//     } catch (e) {
//       debugPrint('Error playing sound: $e');
//     }
//   }
//
//   void dispose() {
//     _audioPlayer.dispose();
//     _alertQueue.clear();
//   }
// }
