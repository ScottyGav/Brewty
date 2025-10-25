// SPDX-License-Identifier: MIT
// Example wiring showing how to use either adapter.
//
// - For Hive (Flutter): add hive and hive_flutter, then call Hive.initFlutter() in main()
// - For Sembast: compute a path (e.g., via path_provider) and pass to SembastFormStore
//
// This file demonstrates usage and should be adapted to your app's DI layer.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'form_instance.dart';
import 'hive_form_store.dart';
import 'sembast_form_store.dart';
import 'form_store.dart';

Future<FormStore> createHiveStore({String boxName = 'form_instances'}) async {
  // If using Flutter, call Hive.initFlutter() in main() before this.
  final store = HiveFormStore(boxName: boxName);
  await store.init();
  return store;
}

Future<FormStore> createSembastStore(String dbPath) async {
  final store = SembastFormStore(dbPath: dbPath);
  await store.init();
  return store;
}

// Simple example usage in a widget
class StorageExampleWidget extends StatefulWidget {
  final FormStore store;

  const StorageExampleWidget({Key? key, required this.store}) : super(key: key);

  @override
  State<StorageExampleWidget> createState() => _StorageExampleWidgetState();
}

class _StorageExampleWidgetState extends State<StorageExampleWidget> {
  List<FormInstance> _forms = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.store.listForms();
    if (!mounted) return;
    setState(() => _forms = items);
  }

  Future<void> _createDummy() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final fi = FormInstance(
      id: id,
      templateId: 'brew_batch_v1',
      values: {
        'recipe_name': {'descriptorId': 'recipe_name', 'value': 'Test Brew'},
        'batch_volume': {'descriptorId': 'batch_volume', 'value': 2000, 'unitId': 'ml'}
      },
    );
    await widget.store.saveForm(fi);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(onPressed: _createDummy, child: const Text('Create dummy form')),
        Expanded(
          child: ListView(
            children: _forms
                .map((f) => ListTile(
                      title: Text('${f.templateId} — ${f.id}'),
                      subtitle: Text('Updated: ${f.updatedAt.toIso8601String()}'),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}