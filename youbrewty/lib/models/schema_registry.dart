// SPDX-License-Identifier: MIT
// Registry that holds domain templates, descriptors, and ontology.
// Allows runtime registration (plugins) and lookup.

import 'dart:collection';

import 'field_descriptor.dart';
import 'ontology.dart';

/// Domain template is a named composition of field descriptors for a particular workflow (recipe, batch, sample).
class DomainTemplate {
  final String id; // e.g., 'brew_batch_v1'
  final String label;
  final String description;
  final List<FieldDescriptor> fields;
  final String? recommendedTaxonomy; // optional taxonomy id used as default

  DomainTemplate({
    required this.id,
    required this.label,
    this.description = '',
    List<FieldDescriptor>? fields,
    this.recommendedTaxonomy,
  }) : fields = fields ?? [];

  FieldDescriptor? fieldById(String id) {
    for (final f in fields) {
      if (f.id == id) return f;
    }
    return null;
  }
}

/// A registry singleton for templates and ontologies. Plugins should call register* methods.
class SchemaRegistry {
  static final SchemaRegistry _instance = SchemaRegistry._internal();

  factory SchemaRegistry() => _instance;

  SchemaRegistry._internal();

  final Map<String, DomainTemplate> _templates = {};
  final Ontology _ontology = Ontology();

  /// Register a domain template
  void registerTemplate(DomainTemplate tpl) {
    _templates[tpl.id] = tpl;
  }

  DomainTemplate? getTemplate(String id) => _templates[id];

  List<DomainTemplate> listTemplates() => UnmodifiableListView(_templates.values);

  /// Register a taxonomy
  void registerTaxonomy(Taxonomy tax) => _ontology.register(tax);

  Taxonomy? taxonomy(String id) => _ontology.taxonomy(id);

  Ontology get ontology => _ontology;

  /// Helper to clear registry (useful for tests)
  void clear() {
    _templates.clear();
    // note: ontology clearing not implemented; create new instance if needed
  }

  /// Initialize with a bootstrap function (call at app startup)
  void init({required void Function(SchemaRegistry) bootstrap}) {
    bootstrap(this);
  }
}