import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Bottom panel that switches between different tabs
class ScenarioBottomPanel extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(bottomPanelTabProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
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
                    onTap: () =>
                        ref.read(bottomPanelTabProvider.notifier).setTab(tab),
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
          Flexible(
            child: IndexedStack(
              index: activeTab.index,
              children: [devicesContent, propertiesContent, conditionsContent],
            ),
          ),
        ],
      ),
    );
  }
}
