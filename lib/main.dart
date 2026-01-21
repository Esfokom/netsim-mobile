import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsim_mobile/core/providers/theme_provider.dart';
import 'package:netsim_mobile/core/providers/user_provider.dart';
import 'package:netsim_mobile/core/widgets/root_scaffold.dart';
import 'package:netsim_mobile/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:netsim_mobile/features/onboarding/presentation/screens/main_menu.dart';
import 'package:netsim_mobile/features/onboarding/presentation/screens/settings_screen.dart';
import 'package:netsim_mobile/features/onboarding/presentation/screens/user_onboarding_screen.dart';
import 'package:netsim_mobile/features/game/presentation/screens/game_screen.dart';
import 'package:netsim_mobile/features/game/presentation/screens/scenario_editor.dart';
import 'package:netsim_mobile/features/scenarios/presentation/screens/saved_scenarios_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return ShadApp(
      title: 'Network Simulation Game',
      theme: ShadThemeData(
        colorScheme: ShadZincColorScheme.light(),
        brightness: Brightness.light,
      ),
      darkTheme: ShadThemeData(
        colorScheme: ShadZincColorScheme.dark(),
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,
      builder: (context, child) {
        return RootScaffold(child: child ?? const SizedBox.shrink());
      },
      routes: {
        "/": (context) => const AppEntryPoint(),
        "/home": (context) => const MainMenu(),
        "/onboarding": (context) => const UserOnboardingScreen(),
        "/game": (context) => const GameScreen(),
        "/editor": (context) => const ScenarioEditor(),
        "/scenarios": (context) => const SavedScenariosScreen(),
        "/leaderboard": (context) => LeaderboardScreen(),
        "/settings": (context) => const SettingsScreen(),
      },
    );
  }
}

/// Entry point that checks if user profile exists
class AppEntryPoint extends ConsumerWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasProfileAsync = ref.watch(hasUserProfileProvider);

    return hasProfileAsync.when(
      data: (hasProfile) {
        if (hasProfile) {
          return const MainMenu();
        } else {
          return const UserOnboardingScreen();
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(hasUserProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
