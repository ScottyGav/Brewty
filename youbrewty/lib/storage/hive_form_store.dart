// SPDX-License-Identifier: MIT
// Hive-backed FormStore implementation.
// Note: add hive dependency in pubspec.yaml: hive: ^2.2.3
// For Flutter apps it's common to use hive_flutter and call Hive.initFlutter().
//
// This implementation stores form instances as JSON strings in a single box.
// It avoids custom TypeAdapters by serializing to JSON. For larger or more
// structured apps you may prefer writing TypeAdapters.

import 'dart:convert';
import 'package:hive/hive.dart';

import 'form_store.dart';
import 'form_instance.dart';

class HiveFormStore implements FormStore {
  final String boxName;
  Box<dynamic>? _box;

  HiveFormStore({this.boxName = 'form_instances'});

  /// If running in Flutter, call Hive.initFlutter() before init().
  /// Otherwise, call Hive.init(appDocumentPath) in non-Flutter contexts.
  @override
  Future<void> init() async {
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box(boxName);
    } else {
      _box = await Hive.openBox(boxName);
    }
  }

  @override
  Future<void> saveForm(FormInstance form) async {
    if (_box == null) throw StateError('HiveFormStore not initialized');
    form.updatedAt = DateTime.now();
    final jsonStr = jsonEncode(form.toJson());
    await _box!.put(form.id, jsonStr);
  }

  @override
  Future<FormInstance?> loadForm(String id) async {
    if (_box == null) throw StateError('HiveFormStore not initialized');
    final raw = _box!.get(id) as String?;
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return FormInstance.fromJson(map);
  }

  @override
  Future<List<FormInstance>> listForms({String? templateId}) async {
    if (_box == null) throw StateError('HiveFormStore not initialized');
    final results = <FormInstance>[];
    for (final v in _box!.values) {
      try {
        final map = jsonDecode(v as String) as Map<String, dynamic>;
        final fi = FormInstance.fromJson(map);
        if (templateId == null || fi.templateId == templateId) results.add(fi);
      } catch (_) {
        // ignore malformed entry
      }
    }
    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  @override
  Future<void> deleteForm(String id) async {
    if (_box == null) throw StateError('HiveFormStore not initialized');
    await _box!.delete(id);
  }

  @override
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
  }
}