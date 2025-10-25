// SPDX-License-Identifier: MIT
// Abstract persistence interface for form instances.

import '../storage/form_instance.dart';

abstract class FormStore {
  /// Initialize the store (open DB, open boxes, etc).
  Future<void> init();

  /// Save or update a form instance.
  Future<void> saveForm(FormInstance form);

  /// Load a form instance by id, or null if not found.
  Future<FormInstance?> loadForm(String id);

  /// List all forms (optionally filtered by templateId).
  Future<List<FormInstance>> listForms({String? templateId});

  /// Delete a form instance.
  Future<void> deleteForm(String id);

  /// Close the store and release resources.
  Future<void> close();
}