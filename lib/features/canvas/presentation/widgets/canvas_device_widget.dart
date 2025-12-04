import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/data/models/device_link.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/canvas/presentation/widgets/network_canvas.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/switch_device.dart';
import 'package:netsim_mobile/features/devices/domain/factories/device_factory.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:netsim_mobile/features/scenarios/presentation/widgets/scenario_bottom_panel.dart';

class CanvasDeviceWidget extends ConsumerStatefulWidget {
  final CanvasDevice device;
  final double scale;

  const CanvasDeviceWidget({
    super.key,
    required this.device,
    required this.scale,
  });

  @override
  ConsumerState<CanvasDeviceWidget> createState() => _CanvasDeviceWidgetState();
}

class _CanvasDeviceWidgetState extends ConsumerState<CanvasDeviceWidget> {
  Offset? dragStartPosition;
  Timer? _edgeScrollTimer;

  @override
  void dispose() {
    _edgeScrollTimer?.cancel();
    super.dispose();
  }

  /// Start edge scrolling when dragging near screen edges
  void _startEdgeScrolling(Offset globalPosition, BuildContext context) {
    // Don't restart timer if already scrolling in same direction
    final transformationController = ref.read(
      canvasTransformationControllerProvider,
    );
    if (transformationController == null) return;

    const edgeThreshold = 50.0; // Pixels from edge to trigger scrolling
    const scrollSpeed = 8.0; // Reduced speed for better control

    final screenSize = MediaQuery.of(context).size;

    // Calculate scroll direction based on proximity to edges
    double scrollX = 0;
    double scrollY = 0;

    if (globalPosition.dx < edgeThreshold) {
      scrollX = scrollSpeed; // Scroll right (pan canvas left)
    } else if (globalPosition.dx > screenSize.width - edgeThreshold) {
      scrollX = -scrollSpeed; // Scroll left (pan canvas right)
    }

    if (globalPosition.dy < edgeThreshold) {
      scrollY = scrollSpeed; // Scroll down (pan canvas up)
    } else if (globalPosition.dy > screenSize.height - edgeThreshold) {
      scrollY = -scrollSpeed; // Scroll up (pan canvas down)
    }

    // If not near any edge, stop scrolling
    if (scrollX == 0 && scrollY == 0) {
      _stopEdgeScrolling();
      return;
    }

    // If already scrolling, don't create new timer
    if (_edgeScrollTimer?.isActive ?? false) {
      return;
    }

    // Start periodic scrolling
    _edgeScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      final currentMatrix = transformationController.value.clone();
      final translation = currentMatrix.getTranslation();

      // Apply scroll to canvas transformation
      currentMatrix.setTranslationRaw(
        translation.x + scrollX,
        translation.y + scrollY,
        0,
      );

      transformationController.value = currentMatrix;
    });
  }

  /// Stop edge scrolling
  void _stopEdgeScrolling() {
    _edgeScrollTimer?.cancel();
    _edgeScrollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasProvider);
    final canvasNotifier = ref.read(canvasProvider.notifier);

    // Get NetworkDevice to access displayName (which respects showIpOnCanvas toggle)
    NetworkDevice? networkDevice = canvasNotifier.getNetworkDevice(
      widget.device.id,
    );

    // If not cached yet, create it
    if (networkDevice == null) {
      networkDevice = DeviceFactory.fromCanvasDevice(widget.device);
      // Cache it after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        canvasNotifier.setNetworkDevice(widget.device.id, networkDevice!);
      });
    }

    return Positioned(
      left:
          widget.device.position.dx -
          20, // Offset to account for tooltip extending left
      top:
          widget.device.position.dy - 48, // Offset to account for tooltip above
      child: SizedBox(
        width: 120, // 80 (device) + 20 (left offset) + 20 (right buffer)
        height: 128, // 80 (device) + 48 (tooltip above)
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main device widget with gesture detection - offset to account for expanded hit area
            Positioned(
              left: 20,
              top: 48,
              child: GestureDetector(
                onTap: () {
                  if (canvasState.isLinkingMode) {
                    _handleLinkingTap(context, canvasState, canvasNotifier);
                  } else {
                    // Select device in canvas
                    canvasNotifier.selectDevice(widget.device.id);

                    // Also select in scenario provider for contextual editor
                    Future.microtask(() {
                      ref
                          .read(scenarioProvider.notifier)
                          .selectDevice(widget.device.id);
                      // Switch to properties tab automatically
                      ref
                          .read(bottomPanelTabProvider.notifier)
                          .setTab(BottomPanelTab.properties);
                    });

                    // Device details now shown in properties tab - no dialog
                  }
                },
                onLongPress: () {
                  // Select device for properties tab on long press
                  canvasNotifier.selectDevice(widget.device.id);
                  Future.microtask(() {
                    ref
                        .read(scenarioProvider.notifier)
                        .selectDevice(widget.device.id);
                    // Switch to properties tab automatically
                    ref
                        .read(bottomPanelTabProvider.notifier)
                        .setTab(BottomPanelTab.properties);
                  });
                },
                onPanStart: (details) {
                  if (!canvasState.isLinkingMode) {
                    dragStartPosition = widget.device.position;
                    canvasNotifier.selectDevice(widget.device.id);
                    // Sync selection with scenario provider
                    ref
                        .read(scenarioProvider.notifier)
                        .selectDevice(widget.device.id);
                  }
                },
                onPanUpdate: (details) {
                  if (!canvasState.isLinkingMode && dragStartPosition != null) {
                    // Check if near edge and start scrolling if needed
                    _startEdgeScrolling(details.globalPosition, context);

                    // Get current transformation
                    final transformationController = ref.read(
                      canvasTransformationControllerProvider,
                    );

                    if (transformationController != null) {
                      final matrix = transformationController.value;
                      final scale = matrix.getMaxScaleOnAxis();
                      final translation = matrix.getTranslation();

                      // Convert global position to canvas coordinates
                      final canvasX =
                          (details.globalPosition.dx - translation.x) / scale;
                      final canvasY =
                          (details.globalPosition.dy - translation.y) / scale;

                      // Calculate new device position (centered on cursor)
                      const deviceSize = 80.0;
                      final newPosition = Offset(
                        canvasX - (deviceSize / 2),
                        canvasY - (deviceSize / 2),
                      );

                      // Constrain position to canvas bounds
                      const canvasWidth = 2000.0;
                      const canvasHeight = 2000.0;

                      final constrainedPosition = Offset(
                        newPosition.dx.clamp(0.0, canvasWidth - deviceSize),
                        newPosition.dy.clamp(0.0, canvasHeight - deviceSize),
                      );

                      canvasNotifier.updateDevicePosition(
                        widget.device.id,
                        constrainedPosition,
                      );
                    }
                  }
                },
                onPanEnd: (details) {
                  dragStartPosition = null;
                  _stopEdgeScrolling();
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: widget.device.type.color.withValues(alpha: 0.2),
                    border: Border.all(
                      color: widget.device.isSelected
                          ? Colors.blue
                          : canvasState.isLinkingMode &&
                                canvasState.linkingFromDeviceId ==
                                    widget.device.id
                          ? Colors.green
                          : widget.device.type.color,
                      width: widget.device.isSelected
                          ? 3
                          : canvasState.isLinkingMode &&
                                canvasState.linkingFromDeviceId ==
                                    widget.device.id
                          ? 3
                          : 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: widget.device.isSelected
                        ? [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : canvasState.isLinkingMode &&
                              canvasState.linkingFromDeviceId ==
                                  widget.device.id
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.device.type.icon,
                        size: 32,
                        color: widget.device.type.color,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        networkDevice.displayName,
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.device.status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Quick actions tooltip - positioned relative to SizedBox
            if (widget.device.isSelected && !canvasState.isLinkingMode)
              Positioned(
                top: 4, // Near top of SizedBox (which starts 48px above device)
                left: 0, // At left edge of SizedBox
                child: _DeviceQuickActions(
                  deviceId: widget.device.id,
                  hasLinks: canvasState.links.any(
                    (l) =>
                        l.fromDeviceId == widget.device.id ||
                        l.toDeviceId == widget.device.id,
                  ),
                ),
              ),
            // Linking mode badge - adjusted for new positions
            if (canvasState.isLinkingMode &&
                canvasState.linkingFromDeviceId == widget.device.id)
              Positioned(
                top: 44, // 48 - 4
                right: 16, // 20 - 4
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.cable, size: 16, color: Colors.white),
                ),
              ),
            // Clickable to link badge
            if (canvasState.isLinkingMode &&
                canvasState.linkingFromDeviceId != widget.device.id &&
                canvasState.linkingFromDeviceId != null)
              Positioned(
                top: 44, // 48 - 4
                right: 16, // 20 - 4
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_link,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleLinkingTap(
    BuildContext context,
    CanvasState canvasState,
    CanvasNotifier canvasNotifier,
  ) {
    final sourceId = canvasState.linkingFromDeviceId;
    final targetId = widget.device.id;

    if (sourceId == null || sourceId == targetId) {
      canvasNotifier.completeLinking(targetId);
      return;
    }

    final sourceDevice = canvasNotifier.getNetworkDevice(sourceId);
    final targetDevice = canvasNotifier.getNetworkDevice(targetId);

    final sourceIsSwitch = sourceDevice?.deviceType == 'Switch';
    final targetIsSwitch = targetDevice?.deviceType == 'Switch';

    if (sourceIsSwitch || targetIsSwitch) {
      _showPortSelectionDialog(
        context,
        canvasNotifier,
        sourceId,
        targetId,
        sourceDevice,
        targetDevice,
        sourceIsSwitch,
        targetIsSwitch,
      );
    } else {
      canvasNotifier.completeLinking(targetId);
    }
  }

  void _showPortSelectionDialog(
    BuildContext context,
    CanvasNotifier canvasNotifier,
    String sourceId,
    String targetId,
    NetworkDevice? sourceDevice,
    NetworkDevice? targetDevice,
    bool sourceIsSwitch,
    bool targetIsSwitch,
  ) {
    // We need to import SwitchDevice to access ports, but we can't easily here without circular deps or type issues if not careful.
    // However, we can use dynamic or check properties if we are careful.
    // Or better, assume we can access 'ports' if it's a switch.
    // Since we are in the widget, we can try to cast if we import SwitchDevice.
    // Let's assume we can access the ports list.

    // Helper to get available ports
    List<SwitchPort> getAvailablePorts(NetworkDevice? device) {
      if (device == null || device is! SwitchDevice) return [];
      return device.ports.where((p) => p.connectedLinkId == null).toList();
    }

    List<SwitchPort> sourcePorts = sourceIsSwitch
        ? getAvailablePorts(sourceDevice)
        : [];
    List<SwitchPort> targetPorts = targetIsSwitch
        ? getAvailablePorts(targetDevice)
        : [];

    int? selectedSourcePortId;
    int? selectedTargetPortId;

    // Pre-select first available port
    if (sourcePorts.isNotEmpty) {
      selectedSourcePortId = sourcePorts.first.portId;
    }
    if (targetPorts.isNotEmpty) {
      selectedTargetPortId = targetPorts.first.portId;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Select Ports'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sourceIsSwitch) ...[
                  Text('Source: ${sourceDevice?.displayName ?? "Switch"}'),
                  const SizedBox(height: 8),
                  if (sourcePorts.isEmpty)
                    const Text(
                      'No available ports',
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    DropdownButton<int>(
                      value: selectedSourcePortId,
                      isExpanded: true,
                      items: sourcePorts.map((p) {
                        return DropdownMenuItem<int>(
                          value: p.portId,
                          child: Text('Port ${p.portId}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedSourcePortId = val);
                      },
                    ),
                  const SizedBox(height: 16),
                ],
                if (targetIsSwitch) ...[
                  Text('Target: ${targetDevice?.displayName ?? "Switch"}'),
                  const SizedBox(height: 8),
                  if (targetPorts.isEmpty)
                    const Text(
                      'No available ports',
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    DropdownButton<int>(
                      value: selectedTargetPortId,
                      isExpanded: true,
                      items: targetPorts.map((p) {
                        return DropdownMenuItem<int>(
                          value: p.portId,
                          child: Text('Port ${p.portId}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedTargetPortId = val);
                      },
                    ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    (sourceIsSwitch && selectedSourcePortId == null) ||
                        (targetIsSwitch && selectedTargetPortId == null)
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        canvasNotifier.completeLinkingWithPort(
                          targetId,
                          selectedSourcePortId,
                          selectedTargetPortId,
                        );
                      },
                child: const Text('Connect'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Quick action buttons that appear above a selected device
class _DeviceQuickActions extends ConsumerWidget {
  final String deviceId;
  final bool hasLinks;

  const _DeviceQuickActions({required this.deviceId, required this.hasLinks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Create Link button
            _QuickActionButton(
              icon: Icons.add_link,
              color: const Color(0xFF10B981),
              tooltip: 'Create Link',
              onTap: () {
                ref.read(canvasProvider.notifier).startLinking(deviceId);
                ref.read(scenarioProvider.notifier).selectDevice(null);
              },
            ),
            // Remove Link button - only show if device has links
            if (hasLinks) ...[
              const SizedBox(width: 3),
              _QuickActionButton(
                icon: Icons.link_off,
                color: const Color(0xFFF59E0B),
                tooltip: 'Remove Link',
                onTap: () => _showRemoveLinkDialog(context, ref),
              ),
            ],
            const SizedBox(width: 3),
            // Delete Device button
            _QuickActionButton(
              icon: Icons.delete_outline,
              color: const Color(0xFFEF4444),
              tooltip: 'Delete Device',
              onTap: () => _confirmDeleteDevice(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  // ...existing code...
  void _showRemoveLinkDialog(BuildContext context, WidgetRef ref) {
    final canvasState = ref.read(canvasProvider);
    final canvasNotifier = ref.read(canvasProvider.notifier);

    // Get all links connected to this device
    final connectedLinks = canvasState.links
        .where((l) => l.fromDeviceId == deviceId || l.toDeviceId == deviceId)
        .toList();

    if (connectedLinks.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Link'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a connection to remove:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              ...connectedLinks.map((link) {
                final otherDeviceId = link.fromDeviceId == deviceId
                    ? link.toDeviceId
                    : link.fromDeviceId;

                final otherDevice = canvasState.devices
                    .where((d) => d.id == otherDeviceId)
                    .firstOrNull;

                if (otherDevice == null) return const SizedBox.shrink();

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      otherDevice.type.icon,
                      color: otherDevice.type.color,
                    ),
                    title: Text(
                      otherDevice.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${link.type.displayName} • ${otherDevice.type.displayName}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade600,
                      ),
                      tooltip: 'Remove this link',
                      onPressed: () {
                        canvasNotifier.removeLink(link.id);
                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Disconnected from ${otherDevice.name}',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDevice(BuildContext context, WidgetRef ref) {
    final canvasState = ref.read(canvasProvider);
    final canvasNotifier = ref.read(canvasProvider.notifier);

    // Find links connected to this device
    final connectedLinks = canvasState.links
        .where(
          (link) =>
              link.fromDeviceId == deviceId || link.toDeviceId == deviceId,
        )
        .toList();

    // Find the device name
    final device = canvasState.devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => canvasState.devices.first,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete ${device.name}?'),
            if (connectedLinks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This device has ${connectedLinks.length} active connection${connectedLinks.length > 1 ? 's' : ''}. All links will be removed.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove all connected links first
              for (final link in connectedLinks) {
                canvasNotifier.removeLink(link.id);
              }
              // Then remove the device
              canvasNotifier.removeDevice(deviceId);
              ref.read(scenarioProvider.notifier).selectDevice(null);
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${device.name} deleted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Individual quick action button
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isEnabled
                  ? color.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: isEnabled ? color : Colors.grey),
          ),
        ),
      ),
    );
  }
}
