import 'package:flutter/material.dart';

import 'models/user_profile.dart';
import 'screens/settings_screen_example.dart';
import 'services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize SharedPreferences-backed preferences so feature toggles
  // and other settings are available app-wide before the UI builds.
  await PreferencesService.instance.init();
  runApp(const MyApp());
}

/// A simple app demonstrating wiring the Settings screen into navigation.
/// Routes:
///  - "/": HomePage
///  - "/settings": SettingsScreenExample (demonstrates SettingsScreen usage)
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouBrewty (Demo)',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      // Define named routes so you can navigate by name from anywhere.
      routes: {
        '/': (context) => const HomePage(),
        '/settings': (context) => const SettingsScreenExample(),
      },
      initialRoute: '/',
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Local representation of the profile shown on the home screen.
  // This will be updated when the Settings screen returns an updated profile.
  UserProfile _profile = UserProfile(userId: 'local_user');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouBrewty — Home'),
        actions: [
          // Quick route to settings via named route
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => _openSettings(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back!', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Current profile: ${_profile.level.toString().split('.').last.capitalize()}'),
            const SizedBox(height: 8),
            Text('Enabled features (${_profile.enabledFeatures.length}):'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: _profile.enabledFeatures.isEmpty
                    ? [const Text('No features enabled.')]
                    : _profile.enabledFeatures
                        .map((f) => ListTile(title: Text(f.toString().split('.').last.capitalize())))
                        .toList(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              onPressed: () => _openSettings(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.settings_applications),
        onPressed: () => _openSettings(),
        tooltip: 'Open Settings',
      ),
    );
  }

  Future<void> _openSettings() async {
    // Use named route: the SettingsScreenExample will be created and pushed.
    // It returns a UserProfile on save/pop; update local view if present.
    final result = await Navigator.of(context).pushNamed('/settings');

    if (result is UserProfile) {
      setState(() {
        _profile = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } else {
      // If the settings screen was dismissed without saving, do nothing.
    }
  }
}

/// Simple helper to capitalize enum/string labels.
extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}