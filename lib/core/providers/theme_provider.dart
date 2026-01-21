import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preferences_service.dart';

/// Provider for PreferencesService
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

/// Provider for theme state management
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

/// Theme state notifier
class ThemeNotifier extends Notifier<ThemeMode> {
  late final PreferencesService _preferencesService;

  @override
  ThemeMode build() {
    _preferencesService = ref.read(preferencesServiceProvider);
    _loadTheme();
    return ThemeMode.system;
  }

  /// Load theme from preferences on initialization
  Future<void> _loadTheme() async {
    final savedTheme = await _preferencesService.getThemeMode();
    state = savedTheme ?? ThemeMode.system;
  }

  /// Change theme and persist to preferences
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _preferencesService.setThemeMode(mode);
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setTheme(newMode);
  }
}
