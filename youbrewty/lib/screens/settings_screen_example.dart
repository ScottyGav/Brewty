import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import 'settings_screen.dart';

/// Example wiring: the app provides persistence. This example demonstrates
/// an in-memory save implementation; replace with your persistence layer.
///
/// Note: Do not include any shared_preferences import here; if you later
/// add shared_preferences, implement the persistence in the saveProfile method.
class SettingsScreenExample extends StatefulWidget {
  const SettingsScreenExample({Key? key}) : super(key: key);

  @override
  State<SettingsScreenExample> createState() => _SettingsScreenExampleState();
}

class _SettingsScreenExampleState extends State<SettingsScreenExample> {
  // In-memory profile for demo/testing. Replace with real store.
  UserProfile _profile = UserProfile(userId: 'local_user');

  Future<void> _saveProfile(UserProfile updated) async {
    // Replace the body of this function with your persistence implementation.
    // Examples:
    // - SharedPreferences: save json string
    // - Hive / sembast / sqlite: store structured record
    // - Backend API: POST /users/{id}/profile
    //
    // For now, we update the in-memory value and pretend to persist.
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _profile = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      profile: _profile,
      onSave: _saveProfile,
    );
  }
}