import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/device_packet_stats.dart';
import 'package:netsim_mobile/features/simulation/domain/services/packet_telemetry_service.dart';
import 'package:netsim_mobile/features/simulation/domain/services/simulation_engine.dart';

/// Provider for the packet telemetry service
final packetTelemetryServiceProvider = Provider<PacketTelemetryService>((ref) {
  final service = PacketTelemetryService(ref);
  final engine = ref.watch(simulationEngineProvider);

  // Initialize with simulation engine
  service.initialize(engine);

  // Cleanup on dispose
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for device-specific packet statistics (reactive via StreamProvider)
final devicePacketStatsProvider = StreamProvider.family<DevicePacketStats, String>((
  ref,
  deviceId,
) async* {
  final telemetry = ref.watch(packetTelemetryServiceProvider);
  final engine = ref.watch(simulationEngineProvider);

  appLogger.i(
    '[PacketTelemetry Provider] Watching stats for device: $deviceId',
  );

  // Emit initial state
  final initialStats = telemetry.getDeviceStats(deviceId);
  appLogger.d(
    '[PacketTelemetry Provider] Initial stats for $deviceId: $initialStats',
  );
  yield initialStats;

  // Listen to packet stream and emit stats updates whenever packets are processed
  await for (final event in engine.packetStream) {
    final stats = telemetry.getDeviceStats(deviceId);
    appLogger.d(
      '[PacketTelemetry Provider] Updated stats for $deviceId after ${event.type}: $stats',
    );
    yield stats;
  }
});

/// Provider to reset telemetry (useful for simulation reset)
final resetTelemetryProvider = Provider<void Function()>((ref) {
  return () {
    final telemetry = ref.read(packetTelemetryServiceProvider);
    telemetry.reset();
  };
});
