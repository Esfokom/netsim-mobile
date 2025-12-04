// lib/core/services/preferences_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gender options for user profile
enum Gender {
  male('Male'),
  female('Female'),
  other('Other'),
  preferNotToSay('Prefer not to say');

  final String displayName;
  const Gender(this.displayName);

  static Gender fromString(String? value) {
    return Gender.values.firstWhere(
      (g) => g.name == value,
      orElse: () => Gender.preferNotToSay,
    );
  }
}

/// User profile model
class UserProfile {
  final String username;
  final Gender gender;
  final int age;

  const UserProfile({
    required this.username,
    required this.gender,
    required this.age,
  });

  UserProfile copyWith({String? username, Gender? gender, int? age}) {
    return UserProfile(
      username: username ?? this.username,
      gender: gender ?? this.gender,
      age: age ?? this.age,
    );
  }

  /// Validate age is within acceptable bounds (5-120)
  static bool isValidAge(int age) => age >= 5 && age <= 120;

  /// Get time-based greeting
  String getGreeting() {
    final hour = DateTime.now().hour;
    String timeGreeting;

    if (hour >= 5 && hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }

    return '$timeGreeting, $username!';
  }
}

class PreferencesService {
  static const _themeModeKey = 'theme_mode';
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _usernameKey = 'user_username';
  static const _genderKey = 'user_gender';
  static const _ageKey = 'user_age';
  static const _profileExistsKey = 'user_profile_exists';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Theme methods
  Future<ThemeMode?> getThemeMode() async {
    final instance = await prefs;
    final mode = instance.getString(_themeModeKey);
    if (mode == 'dark') return ThemeMode.dark;
    if (mode == 'light') return ThemeMode.light;
    return null;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final instance = await prefs;
    await instance.setString(_themeModeKey, mode.name);
  }

  Future<bool> isOnboardingComplete() async {
    final instance = await prefs;
    return instance.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    final instance = await prefs;
    await instance.setBool(_onboardingCompleteKey, value);
  }

  // User profile methods
  Future<bool> hasUserProfile() async {
    final instance = await prefs;
    return instance.getBool(_profileExistsKey) ?? false;
  }

  Future<UserProfile?> getUserProfile() async {
    final instance = await prefs;
    final exists = instance.getBool(_profileExistsKey) ?? false;

    if (!exists) return null;

    final username = instance.getString(_usernameKey) ?? '';
    final genderStr = instance.getString(_genderKey);
    final age = instance.getInt(_ageKey) ?? 18;

    return UserProfile(
      username: username,
      gender: Gender.fromString(genderStr),
      age: age,
    );
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final instance = await prefs;
    await instance.setString(_usernameKey, profile.username);
    await instance.setString(_genderKey, profile.gender.name);
    await instance.setInt(_ageKey, profile.age);
    await instance.setBool(_profileExistsKey, true);
  }

  Future<void> clearUserProfile() async {
    final instance = await prefs;
    await instance.remove(_usernameKey);
    await instance.remove(_genderKey);
    await instance.remove(_ageKey);
    await instance.setBool(_profileExistsKey, false);
  }
}
