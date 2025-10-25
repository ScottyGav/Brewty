// SPDX-License-Identifier: MIT
// Simple plugin interface for dynamic schema/taxonomy registration.

import '../models/schema_registry.dart';

abstract class SchemaPlugin {
  /// Called at app startup to register templates and taxonomies
  void register(SchemaRegistry registry);
}