// SPDX-License-Identifier: MIT
// Taxonomy / Ontology model for canonical domain vocabularies

import 'dart:convert';

/// Single taxon in a taxonomy.
class Taxon {
  final String id; // stable id, e.g., 'saccharomyces_cerevisiae'
  final String label; // human label
  final String? parentId; // for hierarchy
  final Map<String, dynamic> attributes; // free-form attributes (e.g., phenotype)

  Taxon({
    required this.id,
    required this.label,
    this.parentId,
    Map<String, dynamic>? attributes,
  }) : attributes = attributes ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'parentId': parentId,
        'attributes': attributes,
      };

  factory Taxon.fromJson(Map<String, dynamic> json) => Taxon(
        id: json['id'] as String,
        label: json['label'] as String,
        parentId: json['parentId'] as String?,
        attributes: Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
      );

  @override
  String toString() => jsonEncode(toJson());
}

/// A taxonomy is a named collection of taxons (e.g., 'organisms', 'ingredient-types').
class Taxonomy {
  final String id;
  final String label;
  final Map<String, Taxon> _taxa;

  Taxonomy({
    required this.id,
    required this.label,
    Map<String, Taxon>? taxa,
  }) : _taxa = taxa ?? {};

  List<Taxon> get taxa => _taxa.values.toList(growable: false);

  void addTaxon(Taxon t) {
    _taxa[t.id] = t;
  }

  Taxon? getTaxon(String id) => _taxa[id];

  /// Find descendants recursively (useful for UI lists)
  List<Taxon> descendantsOf(String id) {
    final result = <Taxon>[];
    for (final t in _taxa.values) {
      var current = t;
      var parent = current.parentId;
      while (parent != null) {
        if (parent == id) {
          result.add(t);
          break;
        }
        parent = _taxa[parent]?.parentId;
      }
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'taxa': _taxa.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory Taxonomy.fromJson(Map<String, dynamic> json) {
    final taxaMap = <String, Taxon>{};
    final taxaJson = json['taxa'] as Map<String, dynamic>? ?? {};
    taxaJson.forEach((k, v) {
      taxaMap[k] = Taxon.fromJson(Map<String, dynamic>.from(v));
    });
    return Taxonomy(
      id: json['id'] as String,
      label: json['label'] as String,
      taxa: taxaMap,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}

/// Simple Ontology that aggregates taxonomies
class Ontology {
  final Map<String, Taxonomy> _taxonomies;

  Ontology({Map<String, Taxonomy>? taxonomies}) : _taxonomies = taxonomies ?? {};

  void register(Taxonomy tax) => _taxonomies[tax.id] = tax;

  Taxonomy? taxonomy(String id) => _taxonomies[id];

  Map<String, dynamic> toJson() => {
        'taxonomies': _taxonomies.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory Ontology.fromJson(Map<String, dynamic> json) {
    final map = <String, Taxonomy>{};
    final tacos = json['taxonomies'] as Map<String, dynamic>? ?? {};
    tacos.forEach((k, v) {
      map[k] = Taxonomy.fromJson(Map<String, dynamic>.from(v));
    });
    return Ontology(taxonomies: map);
  }

  @override
  String toString() => jsonEncode(toJson());
}