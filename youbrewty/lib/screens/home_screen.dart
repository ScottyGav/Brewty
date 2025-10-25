// SPDX-License-Identifier: MIT
// Minimal example HomeScreen showing two ways to access the FormStoreService:
//  - via Provider (listening for changes)
//  - via GetIt (direct access without listening)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/form_store_service.dart';
import '../storage/form_instance.dart';
import '../di/service_locator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FormInstance> _forms = [];

  @override
  void initState() {
    super.initState();
    _loadForms();
  }

  Future<void> _loadForms() async {
    // Example: get the service from GetIt directly for one-off calls
    final svc = getIt<FormStoreService>();
    final items = await svc.listForms();
    if (!mounted) return;
    setState(() => _forms = items);
  }

  Future<void> _createDummy() async {
    final svc = getIt<FormStoreService>();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final fi = FormInstance(
      id: id,
      templateId: 'brew_batch_v1',
      values: {
        'recipe_name': {'descriptorId': 'recipe_name', 'value': 'Test Brew'},
        'batch_volume': {'descriptorId': 'batch_volume', 'value': 2000, 'unitId': 'ml'}
      },
    );
    await svc.saveForm(fi);
    await _loadForms();
  }

  @override
  Widget build(BuildContext context) {
    // Example: listen to the provider (this rebuilds when service notifies).
    final providerSvc = Provider.of<FormStoreService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('YouBrewty — Home (DI demo)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('Service initialized: ${providerSvc.initialized}'),
          ),
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
      ),
    );
  }
}