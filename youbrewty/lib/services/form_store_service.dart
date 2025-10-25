// SPDX-License-Identifier: MIT
// A ChangeNotifier wrapper around FormStore to expose persistence via Provider / GetIt.
// The service delegates to an injected FormStore implementation (SembastFormStore, HiveFormStore, etc)
// and exposes convenience methods and lifecycle (init/close). Callers can listen to this service
// (ChangeNotifier) or obtain it via GetIt.

import 'package:flutter/foundation.dart';

import '../storage/form_store.dart';
import '../storage/form_instance.dart';

class FormStoreService extends ChangeNotifier {
  final FormStore store;

  bool _initialized = false;
  bool get initialized => _initialized;

  FormStoreService({required this.store});

  /// Initialize the underlying store (open DB, boxes, etc).
  Future<void> init() async {
    if (_initialized) return;
    await store.init();
    _initialized = true;
    notifyListeners();
  }

  /// Close and cleanup underlying store resources.
  Future<void> disposeService() async {
    if (!_initialized) return;
    await store.close();
    _initialized = false;
    notifyListeners();
  }

  /// Save or update a form instance and notify listeners.
  Future<void> saveForm(FormInstance form) async {
    await store.saveForm(form);
    notifyListeners();
  }

  /// Load a form instance by id (no side-effects).
  Future<FormInstance?> loadForm(String id) => store.loadForm(id);

  /// List forms optionally filtered by template id.
  Future<List<FormInstance>> listForms({String? templateId}) =>
      store.listForms(templateId: templateId);

  /// Delete a form instance and notify listeners.
  Future<void> deleteForm(String id) async {
    await store.deleteForm(id);
    notifyListeners();
  }

  /// Convenience: upsert a field value in a FormInstance then save.
  Future<void> upsertFieldAndSave({
    required String formId,
    required String templateId,
    required String fieldId,
    required Map<String, dynamic> serializedFieldValue,
  }) async {
    final existing = await store.loadForm(formId);
    final fi = existing ??
        FormInstance(
          id: formId,
          templateId: templateId,
          values: {},
        );
    fi.values[fieldId] = serializedFieldValue;
    await saveForm(fi);
  }
}