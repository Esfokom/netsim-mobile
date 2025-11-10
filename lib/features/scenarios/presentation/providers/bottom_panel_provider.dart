import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier for bottom panel height
class BottomPanelHeightNotifier extends Notifier<double> {
  @override
  double build() => 0.4; // Default 40% of screen height

  void setHeight(double fraction) {
    state = fraction;
  }
}

/// Notifier for bottom panel collapsed state
class BottomPanelCollapsedNotifier extends Notifier<bool> {
  @override
  bool build() => false; // Default not collapsed

  void setCollapsed(bool collapsed) {
    state = collapsed;
  }
}

/// Provider for the bottom panel height
final bottomPanelHeightProvider =
    NotifierProvider<BottomPanelHeightNotifier, double>(() {
      return BottomPanelHeightNotifier();
    });

/// Provider for the bottom panel collapsed state
final bottomPanelCollapsedProvider =
    NotifierProvider<BottomPanelCollapsedNotifier, bool>(() {
      return BottomPanelCollapsedNotifier();
    });
