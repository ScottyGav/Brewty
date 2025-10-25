import 'package:flutter/material.dart';

import '../models/user_profile.dart';

/// Settings screen to view/change ExpertiseLevel and toggle individual FeatureFlag items.
/// This version does NOT depend on shared_preferences. Instead it receives the
/// current UserProfile and a save callback so the caller controls persistence.
///
/// Usage:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(
///     profile: currentProfile,
///     onSave: (updated) async { await profileStore.save(updated); },
///   )));
class SettingsScreen extends StatefulWidget {
  final UserProfile profile;
  final Future<void> Function(UserProfile) onSave;

  const SettingsScreen({
    Key? key,
    required this.profile,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserProfile _profile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Work on a local copy so changes can be discarded if the user cancels.
    _profile = widget.profile.copyWith(
      enabledFeatures: Set<FeatureFlag>.from(widget.profile.enabledFeatures),
      preferences: Map<String, dynamic>.from(widget.profile.preferences),
    );
  }

  String _featureTitle(FeatureFlag flag) {
    switch (flag) {
      case FeatureFlag.starterSize:
        return 'Capture starter size';
      case FeatureFlag.pitchRate:
        return 'Capture pitch rate';
      case FeatureFlag.environmentSensors:
        return 'Environment sensors (time-series)';
      case FeatureFlag.strainCatalog:
        return 'Strain catalog';
      case FeatureFlag.strainIsolation:
        return 'Strain isolation workflow';
      case FeatureFlag.strainBanking:
        return 'Strain banking (glycerol stocks)';
      case FeatureFlag.advancedQC:
        return 'Advanced QC fields';
      case FeatureFlag.photoUploads:
        return 'Photo uploads';
      case FeatureFlag.mlPredictions:
        return 'ML predictions & drift detection';
      case FeatureFlag.exportCsv:
        return 'Export CSV';
      case FeatureFlag.apiAccess:
        return 'API access';
      default:
        return flag.toString().split('.').last;
    }
  }

  String _featureSubtitle(FeatureFlag flag) {
    switch (flag) {
      case FeatureFlag.starterSize:
        return 'Record the volume/weight of starters used for propagation.';
      case FeatureFlag.pitchRate:
        return 'Enable entering or estimating cell pitch rate.';
      case FeatureFlag.environmentSensors:
        return 'Allow linking or logging continuous temperature, pH, DO.';
      case FeatureFlag.strainCatalog:
        return 'Keep a catalog of strains and metadata.';
      case FeatureFlag.strainIsolation:
        return 'Access guided isolation workflows (colony picks).';
      case FeatureFlag.strainBanking:
        return 'Track freezer/glycerol stock records.';
      case FeatureFlag.advancedQC:
        return 'Enable microscopy, plating, sequencing fields.';
      case FeatureFlag.photoUploads:
        return 'Attach photos for colonies, krausen, etc.';
      case FeatureFlag.mlPredictions:
        return 'Enable predictive analytics and drift alerts.';
      case FeatureFlag.exportCsv:
        return 'Allow exporting batch and strain data to CSV.';
      case FeatureFlag.apiAccess:
        return 'Enable programmatic access (API keys).';
      default:
        return '';
    }
  }

  Widget _buildLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Expertise Level',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        DropdownButton<ExpertiseLevel>(
          value: _profile.level,
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              // Change level but do NOT merge defaults automatically here.
              // The Promote button below demonstrates merging defaults intentionally.
              _profile.setLevel(v, mergeDefaults: false);
            });
          },
          items: ExpertiseLevel.values.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level.toString().split('.').last.capitalize()),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.trending_up),
          label: const Text('Promote level (merge recommended defaults)'),
          onPressed: () {
            setState(() {
              _profile.promote();
              // Merge sensible defaults for the new level but do not override explicit opt-outs.
              _profile.setLevel(_profile.level, mergeDefaults: true);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Promoted to ${_profile.level.toString().split('.').last}')),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildFeatureTiles() {
    return FeatureFlag.values.map((flag) {
      final enabled = _profile.isFeatureEnabled(flag);
      return SwitchListTile(
        title: Text(_featureTitle(flag)),
        subtitle: Text(_featureSubtitle(flag)),
        value: enabled,
        onChanged: (val) {
          setState(() {
            if (val) {
              _profile.enableFeature(flag);
            } else {
              _profile.disableFeature(flag);
            }
          });
        },
      );
    }).toList();
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      Navigator.of(context).maybePop(_profile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _handleSave,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLevelSelector(),
            const Divider(height: 32),
            const Text(
              'Feature Toggles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._buildFeatureTiles(),
            const SizedBox(height: 24),
            Text(
              'Tip: promoting merges recommended defaults for the new level but does not override features you explicitly turned off.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple helper to capitalize enum string labels.
extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}