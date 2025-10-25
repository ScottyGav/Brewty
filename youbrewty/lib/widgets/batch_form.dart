import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/preferences_service.dart';
import '../models/user_profile.dart';

/// A simple Batch creation/edit form demonstrating validators that consult
/// feature toggles via `PreferencesService.instance.isFeatureEnabled(...)`.
class BatchForm extends StatefulWidget {
  final Batch? initial;
  final Future<void> Function(Batch) onSave;

  const BatchForm({Key? key, this.initial, required this.onSave}) : super(key: key);

  @override
  State<BatchForm> createState() => _BatchFormState();
}

class _BatchFormState extends State<BatchForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TextEditingController _starterSizeController;
  late TextEditingController _qcNotesController;

  bool _starterSizeRequired = false;
  bool _advancedQcRequired = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _capacityController = TextEditingController(text: initial?.capacity.toString() ?? '');
    _starterSizeController = TextEditingController();
    _qcNotesController = TextEditingController();

    // Consult preferences to set which fields are required.
  _starterSizeRequired = PreferencesService.instance.isFeatureEnabledFlag(FeatureFlag.starterSize, defaultValue: false);
  _advancedQcRequired = PreferencesService.instance.isFeatureEnabledFlag(FeatureFlag.advancedQC, defaultValue: false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _starterSizeController.dispose();
    _qcNotesController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _capacityValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null) return 'Must be a number';
    if (n <= 0) return 'Must be > 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Batch name'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _capacityController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Capacity (mL)'),
              validator: _capacityValidator,
            ),
            const SizedBox(height: 8),

            // Starter size field is required only when the preference is enabled.
            if (PreferencesService.instance.isFeatureEnabledFlag(FeatureFlag.starterSize))
              TextFormField(
                controller: _starterSizeController,
                decoration: InputDecoration(
                  labelText: 'Starter size',
                  hintText: _starterSizeRequired ? 'Required' : 'Optional',
                ),
                validator: _starterSizeRequired ? _requiredValidator : null,
              ),

            const SizedBox(height: 8),

            // Advanced QC notes only shown/required if advanced QC toggle enabled
            if (PreferencesService.instance.isFeatureEnabledFlag(FeatureFlag.advancedQC))
              TextFormField(
                controller: _qcNotesController,
                decoration: InputDecoration(
                  labelText: 'Advanced QC notes',
                  hintText: _advancedQcRequired ? 'Required' : 'Optional',
                ),
                validator: _advancedQcRequired ? _requiredValidator : null,
                maxLines: 3,
              ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                // Build Batch minimal object and call onSave. In a real app you'd
                // keep more fields and merge with existing batch metadata.
                final batch = Batch(
                  batchId: widget.initial?.batchId ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _nameController.text.trim(),
                  capacity: double.parse(_capacityController.text.trim()),
                );
                await widget.onSave(batch);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
