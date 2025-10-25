// SPDX-License-Identifier: MIT
// Sembast-backed FormStore implementation.
// Add to pubspec.yaml: sembast: ^5.0.0
//
// This implementation stores JSON (Map) in a store named 'form_instances'.
// For Flutter, you can compute the DB path via path_provider.

// No json import needed; we store Map<String, Object?> directly in sembast.
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

import 'form_store.dart';
import 'form_instance.dart';

class SembastFormStore implements FormStore {
  final String dbPath;
  final DatabaseFactory _dbFactory;
  Database? _db;
  final StoreRef<String, Map<String, Object?>> _store = stringMapStoreFactory.store('form_instances');

  /// Provide a path and optionally a DatabaseFactory (use databaseFactoryIo for io apps).
  SembastFormStore({required this.dbPath, DatabaseFactory? dbFactory})
      : _dbFactory = dbFactory ?? databaseFactoryIo;

  @override
  Future<void> init() async {
    _db = await _dbFactory.openDatabase(dbPath);
  }

  @override
  Future<void> saveForm(FormInstance form) async {
    if (_db == null) throw StateError('SembastFormStore not initialized');
    form.updatedAt = DateTime.now();
  final map = form.toJson();
  await _store.record(form.id).put(_db!, map);
  }

  @override
  Future<FormInstance?> loadForm(String id) async {
    if (_db == null) throw StateError('SembastFormStore not initialized');
  final value = await _store.record(id).get(_db!);
  if (value == null) return null;
  final map = Map<String, dynamic>.from(value);
  return FormInstance.fromJson(map);
  }

  @override
  Future<List<FormInstance>> listForms({String? templateId}) async {
    if (_db == null) throw StateError('SembastFormStore not initialized');
    final records = await _store.find(_db!);
    final result = <FormInstance>[];
    for (final rec in records) {
      try {
    final value = rec.value;
    final map = Map<String, dynamic>.from(value);
        final fi = FormInstance.fromJson(map);
        if (templateId == null || fi.templateId == templateId) result.add(fi);
      } catch (_) {
        // ignore bad record
      }
    }
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  @override
  Future<void> deleteForm(String id) async {
    if (_db == null) throw StateError('SembastFormStore not initialized');
    await _store.record(id).delete(_db!);
  }

  @override
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}