// lib/core/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/preferences_service.dart';
import 'theme_provider.dart';

/// Provider for user profile state management
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(() {
      return UserProfileNotifier();
    });

/// Provider to check if user has completed profile setup
final hasUserProfileProvider = FutureProvider<bool>((ref) async {
  final prefsService = ref.read(preferencesServiceProvider);
  return prefsService.hasUserProfile();
});

/// User profile state notifier
class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  late final PreferencesService _preferencesService;

  @override
  Future<UserProfile?> build() async {
    _preferencesService = ref.read(preferencesServiceProvider);
    return _preferencesService.getUserProfile();
  }

  /// Save user profile
  Future<void> saveProfile(UserProfile profile) async {
    state = const AsyncValue.loading();
    try {
      await _preferencesService.saveUserProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? username,
    Gender? gender,
    int? age,
  }) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    final updatedProfile = currentProfile.copyWith(
      username: username,
      gender: gender,
      age: age,
    );

    await saveProfile(updatedProfile);
  }

  /// Clear user profile
  Future<void> clearProfile() async {
    await _preferencesService.clearUserProfile();
    state = const AsyncValue.data(null);
  }

  /// Refresh profile from storage
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _preferencesService.getUserProfile());
  }
}
