import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/device_packet_stats.dart';
import 'package:netsim_mobile/features/simulation/domain/services/packet_telemetry_service.dart';
import 'package:netsim_mobile/features/simulation/domain/services/simulation_engine.dart';

/// Provider for the packet telemetry service
final packetTelemetryServiceProvider = Provider<PacketTelemetryService>((ref) {
  final service = PacketTelemetryService();
  final engine = ref.watch(simulationEngineProvider);

  // Initialize with simulation engine
  service.initialize(engine);

  // Cleanup on dispose
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for device-specific packet statistics
final devicePacketStatsProvider = Provider.family<DevicePacketStats, String>((
  ref,
  deviceId,
) {
  final telemetry = ref.watch(packetTelemetryServiceProvider);
  return telemetry.getDeviceStats(deviceId);
});

/// Provider to reset telemetry (useful for simulation reset)
final resetTelemetryProvider = Provider<void Function()>((ref) {
  return () {
    final telemetry = ref.read(packetTelemetryServiceProvider);
    telemetry.reset();
  };
});
