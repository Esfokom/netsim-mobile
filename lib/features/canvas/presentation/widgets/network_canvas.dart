import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/canvas_device_widget.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/links_painter.dart';
import 'package:netsim_mobile/features/simulation/domain/services/simulation_engine.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/packet.dart';

/// Notifier for the canvas transformation controller
class CanvasTransformationNotifier extends Notifier<TransformationController?> {
  @override
  TransformationController? build() => null;

  void setController(TransformationController controller) {
    state = controller;
  }

  void clearController() {
    // Only clear if there's actually a controller to clear
    if (state != null) {
      state = null;
    }
  }
}

/// Provider for the canvas transformation controller
final canvasTransformationControllerProvider =
    NotifierProvider<CanvasTransformationNotifier, TransformationController?>(
      CanvasTransformationNotifier.new,
    );

class NetworkCanvas extends ConsumerStatefulWidget {
  const NetworkCanvas({super.key});

  @override
  ConsumerState<NetworkCanvas> createState() => _NetworkCanvasState();
}

class _NetworkCanvasState extends ConsumerState<NetworkCanvas>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();

  // Save the notifier reference to use safely during disposal
  CanvasTransformationNotifier? _transformationNotifier;

  // Animation state
  late Ticker _ticker;
  final List<PacketAnimation> _packetAnimations = [];
  StreamSubscription? _packetSubscription;
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();

    // Save the notifier reference for safe disposal
    _transformationNotifier = ref.read(
      canvasTransformationControllerProvider.notifier,
    );

    // Initialize ticker for animation loop
    _ticker = createTicker(_onTick);
    _ticker.start();
    print('[NetworkCanvas] Ticker started: ${_ticker.isActive}');

    // Subscribe to packet stream
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final simulationEngine = ref.read(simulationEngineProvider);
      print('[NetworkCanvas] Subscribing to packet stream');
      _packetSubscription = simulationEngine.packetStream.listen(
        _handlePacketEvent,
        onError: (error, stackTrace) {
          print('[NetworkCanvas] Stream error: $error');
          print(stackTrace);
        },
        onDone: () {
          print('[NetworkCanvas] Stream closed');
        },
      );

      // Initialize the canvas centered on the grid
      // Get the screen size
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final viewportSize = renderBox.size;

        // Canvas is 2000x2000, center it
        const canvasWidth = 2000.0;
        const canvasHeight = 2000.0;

        // Calculate offset to center the canvas
        final offsetX = (viewportSize.width - canvasWidth) / 2;
        final offsetY = (viewportSize.height - canvasHeight) / 2;

        // Set the transformation to center the canvas
        _transformationController.value = Matrix4.identity()
          ..setTranslationRaw(offsetX, offsetY, 0);
      }

      // Make the controller available to other widgets
      _transformationNotifier?.setController(_transformationController);
    });
  }

  @override
  void dispose() {
    _packetSubscription?.cancel();
    _ticker.dispose();

    // Clear the controller from the provider after dispose completes
    // Use Future to delay the modification as recommended by Riverpod
    Future(() {
      _transformationNotifier?.clearController();
    });

    _transformationController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final now = DateTime.now();
    if (_lastFrameTime == null) {
      _lastFrameTime = now;
      return;
    }

    final dt = now.difference(_lastFrameTime!).inMilliseconds / 1000.0;
    _lastFrameTime = now;

    if (_packetAnimations.isEmpty) return;

    // Log before update
    if (_packetAnimations.isNotEmpty) {
      print(
        '[NetworkCanvas] Tick: ${_packetAnimations.length} animations, dt: $dt',
      );
    }

    setState(() {
      int removedCount = 0;
      _packetAnimations.removeWhere((anim) {
        // Update progress based on duration (1.0s for better visibility)
        const duration = 1.0; // Increased from 0.5 to 1.0 second
        final oldProgress = anim.progress;
        anim.progress += dt / duration;

        if (anim.progress >= 1.0) {
          print(
            '[NetworkCanvas] Removing animation ${anim.id}: ${anim.fromDeviceId} -> ${anim.toDeviceId}, progress: $oldProgress -> ${anim.progress}',
          );
          removedCount++;
          return true;
        }

        // Log progress for first few frames
        if (oldProgress < 0.1) {
          print(
            '[NetworkCanvas] Animation ${anim.id} progress: $oldProgress -> ${anim.progress}',
          );
        }

        return false;
      });

      if (removedCount > 0) {
        print(
          '[NetworkCanvas] Removed $removedCount animations, ${_packetAnimations.length} remaining',
        );
      }

      // Always trigger rebuild when animations are active to ensure CustomPaint repaints
      if (_packetAnimations.isNotEmpty) {
        print(
          '[NetworkCanvas] Triggering rebuild for ${_packetAnimations.length} active animations',
        );
      }
    });
  }

  void _handlePacketEvent(PacketEvent event) {
    try {
      print(
        '[NetworkCanvas] Received packet event: ${event.type} - ${event.packet.type}',
      );
      final canvasState = ref.read(canvasProvider);

      if (event.type == PacketEventType.sent) {
        // Packet sent from a device (usually EndDevice)
        // It goes to all connected links
        // SimulationEngine uses 500ms delay
        if (event.sourceDeviceId != null) {
          final connectedLinks = canvasState.links.where(
            (l) =>
                l.fromDeviceId == event.sourceDeviceId ||
                l.toDeviceId == event.sourceDeviceId,
          );

          print(
            '[NetworkCanvas] Found ${connectedLinks.length} connected links for ${event.sourceDeviceId}',
          );

          for (final link in connectedLinks) {
            final targetId = link.fromDeviceId == event.sourceDeviceId
                ? link.toDeviceId
                : link.fromDeviceId;

            print(
              '[NetworkCanvas] Adding animation: ${event.sourceDeviceId} -> $targetId',
            );
            _addPacketAnimation(
              event.sourceDeviceId!,
              targetId,
              event.packet.type,
            );
          }
        }
      } else if (event.type == PacketEventType.forwarded) {
        // Packet forwarded by a switch on a specific link
        // SimulationEngine uses 200ms delay
        if (event.sourceDeviceId != null && event.targetDeviceId != null) {
          print(
            '[NetworkCanvas] Adding forwarded animation: ${event.sourceDeviceId} -> ${event.targetDeviceId}',
          );
          _addPacketAnimation(
            event.sourceDeviceId!,
            event.targetDeviceId!,
            event.packet.type,
          );
        }
      }
    } catch (e, stackTrace) {
      print('[NetworkCanvas] Error handling packet event: $e');
      print(stackTrace);
    }
  }

  void _addPacketAnimation(String fromId, String toId, PacketType type) {
    Color color;
    switch (type) {
      case PacketType.arpRequest:
      case PacketType.arpReply:
        color = Colors.orange;
        break;
      case PacketType.icmpEchoRequest:
      case PacketType.icmpEchoReply:
        color = Colors.cyan;
        break;
      default:
        color = Colors.purple;
    }

    print(
      '[NetworkCanvas] Creating packet animation: $fromId -> $toId, type: $type, color: $color',
    );

    print('[NetworkCanvas] Ticker is active: ${_ticker.isActive}');

    setState(() {
      _packetAnimations.add(
        PacketAnimation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fromDeviceId: fromId,
          toDeviceId: toId,
          color: color,
        ),
      );
      print(
        '[NetworkCanvas] Total animations now: ${_packetAnimations.length}',
      );
    });

    // Force another frame to ensure repaint
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          print(
            '[NetworkCanvas] Post-frame callback: ${_packetAnimations.length} animations',
          );
        });
      }
    });
  }

  /// Get the next number for a device type
  int _getNextDeviceNumber(DeviceType type, List<CanvasDevice> devices) {
    final devicesOfType = devices.where((d) => d.type == type).length;
    return devicesOfType + 1;
  }

  /// Constrain position to be within canvas bounds
  Offset _constrainPosition(Offset position) {
    const canvasWidth = 2000.0;
    const canvasHeight = 2000.0;
    const deviceSize = 80.0; // Device widget is 80x80

    // Ensure device stays within canvas bounds
    final x = position.dx.clamp(0.0, canvasWidth - deviceSize);
    final y = position.dy.clamp(0.0, canvasHeight - deviceSize);

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider);
    final canvasNotifier = ref.read(canvasProvider.notifier);

    return DragTarget<DeviceType>(
      onAcceptWithDetails: (details) {
        // Get the position where the device was dropped
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);

        // Adjust for current transformation
        final matrix = _transformationController.value;
        final scale = matrix.getMaxScaleOnAxis();
        final translation = matrix.getTranslation();

        // Calculate the actual position on the canvas
        final adjustedPosition = Offset(
          (localPosition.dx - translation.x) / scale -
              40, // -40 to center the device
          (localPosition.dy - translation.y) / scale - 40,
        );

        // Constrain position to canvas bounds
        final constrainedPosition = _constrainPosition(adjustedPosition);

        // Get the next number for this device type
        final deviceNumber = _getNextDeviceNumber(
          details.data,
          canvasState.devices,
        );

        // Create and add the device
        final device = CanvasDevice(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '${details.data.displayName} $deviceNumber',
          type: details.data,
          position: constrainedPosition,
        );

        canvasNotifier.addDevice(device);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            // Deselect all devices when tapping empty space
            if (!canvasState.isLinkingMode) {
              canvasNotifier.deselectAllDevices();
            }
          },
          child: Container(
            color: candidateData.isNotEmpty
                ? Colors.green.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(200),
              constrained: false,
              child: SizedBox(
                width: 2000,
                height: 2000,
                child: Stack(
                  children: [
                    // Grid background
                    CustomPaint(
                      size: const Size(2000, 2000),
                      painter: GridPainter(),
                    ),
                    // Links between devices
                    CustomPaint(
                      size: const Size(2000, 2000),
                      painter: LinksPainter(
                        devices: canvasState.devices,
                        links: canvasState.links,
                        packetAnimations: _packetAnimations,
                      ),
                    ),
                    // Devices
                    ...canvasState.devices.map((device) {
                      return CanvasDeviceWidget(
                        key: ValueKey(device.id),
                        device: device,
                        scale: _transformationController.value
                            .getMaxScaleOnAxis(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Painter for grid background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    const gridSize = 50.0;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw white border around the grid
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}
