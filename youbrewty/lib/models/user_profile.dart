/// User profile model storing explicit per-feature opt-in/opt-out flags
/// rather than referencing a named preset. This makes each feature
/// individually configurable and persisted.
///
/// Usage:
///   final profile = UserProfile(userId: 'u1');
///   profile.enableFeature(FeatureFlag.starterSize);
///   final json = profile.toJson();
///   final restored = UserProfile.fromJson(json);
///
import 'dart:convert';

enum ExpertiseLevel { beginner, intermediate, advanced }

/// Individual feature/data-collection flags that can be enabled or disabled
/// per user. Add new flags here as new capabilities are developed.
enum FeatureFlag {
  starterSize,        // require / capture starter size
  pitchRate,          // require / capture pitch rate or cell estimate
  environmentSensors, // capture time-series temp/pH/DO
  strainCatalog,      // enable strain catalog UI
  strainIsolation,    // enable isolation workflow
  strainBanking,      // enable banking/glycerol records
  advancedQC,         // enable QC fields (microscopy, plating, sequencing)
  photoUploads,       // allow photo attachments for colonies, krausen
  mlPredictions,      // enable ML predictions & drift detection
  exportCsv,          // enable export functionality
  apiAccess,          // enable API access for integrations
  // extend with more flags as needed
}

/// A user profile that persists explicit per-feature opt-ins.
class UserProfile {
  final String userId;
  ExpertiseLevel level;
  final Set<FeatureFlag> enabledFeatures;
  Map<String, dynamic> preferences;
  DateTime createdAt;
  DateTime updatedAt;

  UserProfile({
    required this.userId,
    this.level = ExpertiseLevel.beginner,
    Set<FeatureFlag>? enabledFeatures,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : enabledFeatures = enabledFeatures ?? _defaultFeaturesForLevel(ExpertiseLevel.beginner),
        preferences = preferences ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Enable a feature for this user.
  void enableFeature(FeatureFlag flag) {
    enabledFeatures.add(flag);
    updatedAt = DateTime.now();
  }

  /// Disable a feature for this user.
  void disableFeature(FeatureFlag flag) {
    enabledFeatures.remove(flag);
    updatedAt = DateTime.now();
  }

  /// Toggle a feature on/off.
  void toggleFeature(FeatureFlag flag) {
    if (enabledFeatures.contains(flag)) {
      enabledFeatures.remove(flag);
    } else {
      enabledFeatures.add(flag);
    }
    updatedAt = DateTime.now();
  }

  /// Check if a feature is enabled.
  bool isFeatureEnabled(FeatureFlag flag) {
    return enabledFeatures.contains(flag);
  }

  /// Promote the user's expertise level and optionally apply sensible defaults.
  /// This does NOT force-enable features the user previously opted out of;
  /// instead it merges recommended defaults for the new level, letting the user keep control.
  void promote() {
    if (level == ExpertiseLevel.beginner) {
      setLevel(ExpertiseLevel.intermediate, mergeDefaults: true);
    } else if (level == ExpertiseLevel.intermediate) {
      setLevel(ExpertiseLevel.advanced, mergeDefaults: true);
    }
  }

  /// Set level and optionally merge the feature defaults for the new level.
  void setLevel(ExpertiseLevel newLevel, {bool mergeDefaults = false}) {
    level = newLevel;
    if (mergeDefaults) {
      enabledFeatures.addAll(_defaultFeaturesForLevel(newLevel));
    }
    updatedAt = DateTime.now();
  }

  /// Returns a copy of this profile with modifications applied.
  UserProfile copyWith({
    String? userId,
    ExpertiseLevel? level,
    Set<FeatureFlag>? enabledFeatures,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      level: level ?? this.level,
      enabledFeatures: enabledFeatures ?? Set<FeatureFlag>.from(this.enabledFeatures),
      preferences: preferences ?? Map<String, dynamic>.from(this.preferences),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serialize to JSON-friendly map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'level': level.toString().split('.').last,
      'enabledFeatures': enabledFeatures.map((f) => f.toString().split('.').last).toList(),
      'preferences': preferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Deserialize from JSON map.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final levelStr = json['level'] as String? ?? 'beginner';
    final featuresList = (json['enabledFeatures'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    return UserProfile(
      userId: json['userId'] as String,
      level: _parseLevel(levelStr),
      enabledFeatures: featuresList
          .map((s) => _parseFeatureFlag(s))
          .whereType<FeatureFlag>()
          .toSet(),
      preferences: Map<String, dynamic>.from(json['preferences'] as Map? ?? {}),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Helper parsing functions:
  static ExpertiseLevel _parseLevel(String s) {
    switch (s) {
      case 'intermediate':
        return ExpertiseLevel.intermediate;
      case 'advanced':
        return ExpertiseLevel.advanced;
      case 'beginner':
      default:
        return ExpertiseLevel.beginner;
    }
  }

  static FeatureFlag? _parseFeatureFlag(String s) {
    for (var f in FeatureFlag.values) {
      if (f.toString().split('.').last == s) return f;
    }
    return null;
  }

  /// Sensible defaults per expertise level. These are used when creating
  /// a new profile or when merging defaults upon promotion.
  static Set<FeatureFlag> _defaultFeaturesForLevel(ExpertiseLevel level) {
    switch (level) {
      case ExpertiseLevel.intermediate:
        return {
          FeatureFlag.starterSize,
          FeatureFlag.pitchRate,
          FeatureFlag.strainCatalog,
          FeatureFlag.photoUploads,
          FeatureFlag.exportCsv,
        };
      case ExpertiseLevel.advanced:
        return {
          FeatureFlag.starterSize,
          FeatureFlag.pitchRate,
          FeatureFlag.environmentSensors,
          FeatureFlag.strainCatalog,
          FeatureFlag.strainIsolation,
          FeatureFlag.strainBanking,
          FeatureFlag.advancedQC,
          FeatureFlag.photoUploads,
          FeatureFlag.mlPredictions,
          FeatureFlag.exportCsv,
          FeatureFlag.apiAccess,
        };
      case ExpertiseLevel.beginner:
      default:
        return {
          // minimal defaults for beginners; keep friction low
          FeatureFlag.photoUploads,
          FeatureFlag.exportCsv,
        };
    }
  }

  @override
  String toString() => jsonEncode(toJson());
}