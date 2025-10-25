// SPDX-License-Identifier: MIT
// Simple GetIt-based service locator for the FormStoreService.
// Provides async setup function to initialize and register the service.
// Usage:
//   await setupServiceLocator(); // in main()
//   final svc = getIt<FormStoreService>();

import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart' show DatabaseFactory;
import 'package:sembast/sembast_io.dart' show databaseFactoryIo;
import 'package:sembast_web/sembast_web.dart' show databaseFactoryWeb;

import '../storage/form_store.dart';
import '../storage/sembast_form_store.dart';
import '../services/form_store_service.dart';

final GetIt getIt = GetIt.instance;

/// Initialize and register the FormStoreService with GetIt.
///
/// If [dbFactory] is omitted, a platform-appropriate DatabaseFactory is chosen:
///  - web: databaseFactoryWeb (requires sembast_web)
///  - non-web: databaseFactoryIo
///
/// If [dbPath] is omitted for non-web, the default will be:
///   <appDocumentsDir>/youbrewty.db
///
/// Example in main():
///   WidgetsFlutterBinding.ensureInitialized();
///   await setupServiceLocator();
Future<void> setupServiceLocator({
  DatabaseFactory? dbFactory,
  String? dbPath,
  String storeBoxName = 'form_instances',
}) async {
  if (getIt.isRegistered<FormStoreService>()) return;

  final factory = dbFactory ?? (kIsWeb ? databaseFactoryWeb : databaseFactoryIo);

  String path = dbPath ?? '';
  if (path.isEmpty) {
    if (kIsWeb) {
      // logical name for web (IndexedDB)
      path = 'youbrewty_web.db';
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      path = p.join(appDocDir.path, 'youbrewty.db');
    }
  }

  final formStore = SembastFormStore(dbPath: path, dbFactory: factory);
  final service = FormStoreService(store: formStore);

  await service.init();
  getIt.registerSingleton<FormStoreService>(service, signalsReady: true);
}

/// Helper to unregister/close everything (useful for tests or shutdown).
Future<void> tearDownServiceLocator() async {
  if (getIt.isRegistered<FormStoreService>()) {
    final svc = getIt<FormStoreService>();
    await svc.disposeService();
    await getIt.reset();
  }
}