import 'package:shared_preferences/shared_preferences.dart';
import 'feature_keys.dart';
import '../models/user_profile.dart';

/// Lightweight SharedPreferences adapter service.
///
  /// Usage:
  /// final prefs = PreferencesService.instance;
  /// await prefs.init();
  /// prefs.setBool(FeatureKeys.batchExtendedFields, true);
  /// bool enabled = prefs.isFeatureEnabled(FeatureKeys.batchExtendedFields);
class PreferencesService {
  PreferencesService._internal();

  static final PreferencesService _instance = PreferencesService._internal();
  static PreferencesService get instance => _instance;

  SharedPreferences? _prefs;

  /// Initialize the backing SharedPreferences instance. Call once at app startup.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  bool getBool(String key, {bool defaultValue = false}) => _prefs?.getBool(key) ?? defaultValue;

  Future<bool> setBool(String key, bool value) async {
    if (_prefs == null) await init();
    return _prefs!.setBool(key, value);
  }

  String? getString(String key) => _prefs?.getString(key);

  Future<bool> setString(String key, String value) async {
    if (_prefs == null) await init();
    return _prefs!.setString(key, value);
  }

  Future<bool> remove(String key) async {
    if (_prefs == null) await init();
    return _prefs!.remove(key);
  }

  /// Convenience for feature toggles saved as booleans.
  bool isFeatureEnabled(String featureKey, {bool defaultValue = false}) {
    return getBool(featureKey, defaultValue: defaultValue);
  }

  /// Profile-scoped feature storage helper. Prefixes the key with the profile id.
  String _profileFeatureKey(String profileId, String featureKey) => 'profile:$profileId:$featureKey';

  bool isFeatureEnabledForProfile(String profileId, String featureKey, {bool defaultValue = false}) {
    return getBool(_profileFeatureKey(profileId, featureKey), defaultValue: defaultValue);
  }

  Future<bool> setFeatureForProfile(String profileId, String featureKey, bool enabled) {
    return setBool(_profileFeatureKey(profileId, featureKey), enabled);
  }
  
  // --- Typed overloads using FeatureFlag enum ---

  /// Check a feature's enabled state using the typed [FeatureFlag].
  bool isFeatureEnabledFlag(FeatureFlag flag, {bool defaultValue = false}) {
    final key = FeatureKeys.keyForFlag(flag);
    return isFeatureEnabled(key, defaultValue: defaultValue);
  }

  /// Global set/clear for a feature using the typed [FeatureFlag].
  Future<bool> setFeature(FeatureFlag flag, bool enabled) {
    final key = FeatureKeys.keyForFlag(flag);
    return setBool(key, enabled);
  }

  /// Profile-scoped check using the typed [FeatureFlag].
  bool isFeatureEnabledForProfileFlag(String profileId, FeatureFlag flag, {bool defaultValue = false}) {
    final key = FeatureKeys.keyForFlag(flag);
    return isFeatureEnabledForProfile(profileId, key, defaultValue: defaultValue);
  }

  /// Profile-scoped set using the typed [FeatureFlag].
  Future<bool> setFeatureForProfileFlag(String profileId, FeatureFlag flag, bool enabled) {
    final key = FeatureKeys.keyForFlag(flag);
    return setFeatureForProfile(profileId, key, enabled);
  }
}
