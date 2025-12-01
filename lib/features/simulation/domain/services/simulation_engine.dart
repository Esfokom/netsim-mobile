import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/switch_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/router_device.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/packet.dart';

enum PacketEventType { sent, delivered, dropped, forwarded }

class PacketEvent {
  final Packet packet;
  final String? sourceDeviceId;
  final String? targetDeviceId;
  final PacketEventType type;
  final String? reason;

  PacketEvent({
    required this.packet,
    this.sourceDeviceId,
    this.targetDeviceId,
    required this.type,
    this.reason,
  });
}

/// Service to handle packet simulation and flow
class SimulationEngine {
  final Ref ref;
  final StreamController<PacketEvent> _packetStreamController =
      StreamController<PacketEvent>.broadcast();

  SimulationEngine(this.ref);

  Stream<PacketEvent> get packetStream => _packetStreamController.stream;

  /// Send a packet from a source device
  void sendPacket(Packet packet, String fromDeviceId) {
    appLogger.d('[Simulation] Sending packet from $fromDeviceId: $packet');

    _emitPacketEvent(
      PacketEvent(
        packet: packet,
        sourceDeviceId: fromDeviceId,
        type: PacketEventType.sent,
      ),
    );

    // Find connected links
    final canvasState = ref.read(canvasProvider);
    final links = canvasState.links
        .where(
          (l) => l.fromDeviceId == fromDeviceId || l.toDeviceId == fromDeviceId,
        )
        .toList();

    if (links.isEmpty) {
      appLogger.d(
        '[Simulation] No links connected to $fromDeviceId. Packet dropped.',
      );
      _emitPacketEvent(
        PacketEvent(
          packet: packet,
          sourceDeviceId: fromDeviceId,
          type: PacketEventType.dropped,
          reason: 'No link connected',
        ),
      );
      return;
    }

    // Transmit to connected devices
    for (final link in links) {
      final targetDeviceId = link.fromDeviceId == fromDeviceId
          ? link.toDeviceId
          : link.fromDeviceId;

      appLogger.d(
        '[Simulation] Scheduling delivery to $targetDeviceId via link ${link.id}',
      );

      // Simulate transmission delay
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          _deliverPacket(packet, targetDeviceId, link.id);
        } catch (e, stackTrace) {
          appLogger.e(
            '[Simulation] Error delivering packet',
            error: e,
            stackTrace: stackTrace,
          );
        }
      });
    }
  }

  /// Deliver a packet to a specific device
  void _deliverPacket(Packet packet, String targetDeviceId, String linkId) {
    final canvasNotifier = ref.read(canvasProvider.notifier);

    // Get the network device domain entity
    final device = canvasNotifier.getNetworkDevice(targetDeviceId);

    if (device == null) {
      appLogger.w('[Simulation] Device not found: $targetDeviceId');
      return;
    }

    appLogger.d(
      '[Simulation] Delivering packet to $targetDeviceId via $linkId',
    );

    _emitPacketEvent(
      PacketEvent(
        packet: packet,
        targetDeviceId: targetDeviceId,
        type: PacketEventType.delivered,
      ),
    );

    // Handle packet delivery based on device type
    if (device is EndDevice) {
      // EndDevice includes PC and Server - supports direct peer-to-peer connections
      appLogger.d(
        '[Simulation] Delivering to end device (${device.deviceType}): direct connection',
      );
      device.handlePacket(packet, this);
    } else if (device is SwitchDevice) {
      // Switch forwards based on MAC address table
      device.handlePacket(packet, linkId, this);
    } else if (device is RouterDevice) {
      // For routers, we need to determine which interface received the packet
      // This is based on which interface has the link connected to it
      final incomingInterface = _determineRouterInterface(device, linkId);
      if (incomingInterface != null) {
        appLogger.d(
          '[Simulation] Router receiving packet on interface $incomingInterface',
        );
        device.handlePacket(packet, incomingInterface, this);
      } else {
        appLogger.w(
          '[Simulation] Could not determine router interface for link $linkId',
        );
      }
    }
  }

  /// Determine which router interface a packet arrived on based on the link
  String? _determineRouterInterface(RouterDevice router, String linkId) {
    // Check each interface to see if it has this link connected
    for (var entry in router.interfaces.entries) {
      final interfaceName = entry.key;
      final interface = entry.value;

      if (interface.connectedLinkId == linkId) {
        return interfaceName;
      }
    }

    // If no interface has this link explicitly set, default to eth0
    // This handles the case where links were created before interface tracking
    return router.interfaces.keys.isNotEmpty
        ? router.interfaces.keys.first
        : null;
  }

  /// Allow a device (like a Switch) to forward a packet on a specific link
  void deliverPacketOnLinkFrom(
    Packet packet,
    String linkId,
    String sourceDeviceId,
  ) {
    final canvasState = ref.read(canvasProvider);
    final link = canvasState.links.firstWhere(
      (l) => l.id == linkId,
      orElse: () => throw Exception('Link not found: $linkId'),
    );

    final targetDeviceId = link.fromDeviceId == sourceDeviceId
        ? link.toDeviceId
        : link.fromDeviceId;

    appLogger.d(
      '[Simulation] Forwarding packet from $sourceDeviceId to $targetDeviceId via $linkId',
    );

    _emitPacketEvent(
      PacketEvent(
        packet: packet,
        sourceDeviceId: sourceDeviceId,
        targetDeviceId: targetDeviceId,
        type: PacketEventType.forwarded,
      ),
    );

    // Simulate transmission delay
    Future.delayed(const Duration(milliseconds: 200), () {
      try {
        _deliverPacket(packet, targetDeviceId, linkId);
      } catch (e, stackTrace) {
        appLogger.e(
          '[Simulation] Error forwarding packet',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  void _emitPacketEvent(PacketEvent event) {
    try {
      appLogger.d(
        '[Simulation] Emitting packet event: ${event.type} from ${event.sourceDeviceId} to ${event.targetDeviceId}',
      );
      _packetStreamController.add(event);
    } catch (e, stackTrace) {
      appLogger.e(
        '[Simulation] Error emitting packet event',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

final simulationEngineProvider = Provider<SimulationEngine>((ref) {
  return SimulationEngine(ref);
});
