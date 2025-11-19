import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/features/scenarios/presentation/providers/bottom_panel_provider.dart';

/// Bottom panel tabs
enum BottomPanelTab { devices, properties, conditions }

extension BottomPanelTabExtension on BottomPanelTab {
  String get label {
    switch (this) {
      case BottomPanelTab.devices:
        return 'Devices';
      case BottomPanelTab.properties:
        return 'Properties';
      case BottomPanelTab.conditions:
        return 'Conditions';
    }
  }

  IconData get icon {
    switch (this) {
      case BottomPanelTab.devices:
        return Icons.devices;
      case BottomPanelTab.properties:
        return Icons.settings;
      case BottomPanelTab.conditions:
        return Icons.check_circle_outline;
    }
  }
}

/// Notifier for bottom panel tab state
class BottomPanelTabNotifier extends Notifier<BottomPanelTab> {
  @override
  BottomPanelTab build() => BottomPanelTab.devices;

  void setTab(BottomPanelTab tab) {
    state = tab;
  }
}

/// Provider for the active bottom panel tab
final bottomPanelTabProvider =
    NotifierProvider<BottomPanelTabNotifier, BottomPanelTab>(() {
      return BottomPanelTabNotifier();
    });

/// Bottom panel that switches between different tabs - with resize and collapse
class ScenarioBottomPanel extends ConsumerStatefulWidget {
  final Widget devicesContent;
  final Widget propertiesContent;
  final Widget conditionsContent;

  const ScenarioBottomPanel({
    super.key,
    required this.devicesContent,
    required this.propertiesContent,
    required this.conditionsContent,
  });

  @override
  ConsumerState<ScenarioBottomPanel> createState() =>
      _ScenarioBottomPanelState();
}

class _ScenarioBottomPanelState extends ConsumerState<ScenarioBottomPanel> {
  static const double minHeight = 0.2; // 20% of screen
  static const double maxHeight = 0.7; // 70% of screen

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(bottomPanelTabProvider);
    final heightFraction = ref.watch(bottomPanelHeightProvider);
    final isCollapsed = ref.watch(bottomPanelCollapsedProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    // If collapsed, show only the handle
    if (isCollapsed) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: GestureDetector(
          onTap: () {
            ref.read(bottomPanelCollapsedProvider.notifier).setCollapsed(false);
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.expand_less,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          // Calculate new height fraction
          final newFraction =
              heightFraction - (details.delta.dy / screenHeight);
          final clampedFraction = newFraction.clamp(minHeight, maxHeight);
          ref
              .read(bottomPanelHeightProvider.notifier)
              .setHeight(clampedFraction);
        },
        child: Container(
          height: screenHeight * heightFraction,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              GestureDetector(
                onTap: () {
                  ref
                      .read(bottomPanelCollapsedProvider.notifier)
                      .setCollapsed(true);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.expand_more,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tab selector
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: BottomPanelTab.values.map((tab) {
                    final isActive = tab == activeTab;
                    return Expanded(
                      child: InkWell(
                        onTap: () => ref
                            .read(bottomPanelTabProvider.notifier)
                            .setTab(tab),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tab.icon,
                                size: 20,
                                color: isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tab.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isActive
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Content area
              Expanded(
                child: IndexedStack(
                  index: activeTab.index,
                  children: [
                    widget.devicesContent,
                    widget.propertiesContent,
                    widget.conditionsContent,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
