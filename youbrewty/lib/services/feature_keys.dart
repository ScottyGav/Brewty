/// Centralized feature key constants for `SharedPreferences` toggles.
/// Use these constants wherever a raw preference key would otherwise be used.
import '../models/user_profile.dart';

class FeatureKeys {
  FeatureKeys._();

  static const String starterSize = 'feature.starterSize';
  static const String pitchRate = 'feature.pitchRate';
  static const String environmentSensors = 'feature.environmentSensors';
  static const String strainCatalog = 'feature.strainCatalog';
  static const String strainIsolation = 'feature.strainIsolation';
  static const String strainBanking = 'feature.strainBanking';
  static const String advancedQC = 'feature.advancedQC';
  static const String photoUploads = 'feature.photoUploads';
  static const String mlPredictions = 'feature.mlPredictions';
  static const String exportCsv = 'feature.exportCsv';
  static const String apiAccess = 'feature.apiAccess';

  // Generic / catch-all keys
  static const String batchExtendedFields = 'feature.batchExtendedFields';

  /// Map a typed [FeatureFlag] to its persisted preference key.
  /// This centralizes the mapping between the enum used in the app
  /// and the string keys used for persistence.
  static String keyForFlag(FeatureFlag flag) {
    switch (flag) {
      case FeatureFlag.starterSize:
        return starterSize;
      case FeatureFlag.pitchRate:
        return pitchRate;
      case FeatureFlag.environmentSensors:
        return environmentSensors;
      case FeatureFlag.strainCatalog:
        return strainCatalog;
      case FeatureFlag.strainIsolation:
        return strainIsolation;
      case FeatureFlag.strainBanking:
        return strainBanking;
      case FeatureFlag.advancedQC:
        return advancedQC;
      case FeatureFlag.photoUploads:
        return photoUploads;
      case FeatureFlag.mlPredictions:
        return mlPredictions;
      case FeatureFlag.exportCsv:
        return exportCsv;
      case FeatureFlag.apiAccess:
        return apiAccess;
  }
  }

  /// Reverse-map a persisted key back to a [FeatureFlag] when possible.
  /// Returns `null` for unknown/unmapped keys.
  static FeatureFlag? flagForKey(String key) {
    switch (key) {
      case starterSize:
        return FeatureFlag.starterSize;
      case pitchRate:
        return FeatureFlag.pitchRate;
      case environmentSensors:
        return FeatureFlag.environmentSensors;
      case strainCatalog:
        return FeatureFlag.strainCatalog;
      case strainIsolation:
        return FeatureFlag.strainIsolation;
      case strainBanking:
        return FeatureFlag.strainBanking;
      case advancedQC:
        return FeatureFlag.advancedQC;
      case photoUploads:
        return FeatureFlag.photoUploads;
      case mlPredictions:
        return FeatureFlag.mlPredictions;
      case exportCsv:
        return FeatureFlag.exportCsv;
      case apiAccess:
        return FeatureFlag.apiAccess;
      default:
        return null;
    }
  }
}
