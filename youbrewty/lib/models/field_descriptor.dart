// SPDX-License-Identifier: MIT
// Field descriptor and supporting types for pluggable schema

import 'dart:convert';

import 'ontology.dart';

enum FieldType {
  text,
  integer,
  decimal,
  boolean,
  datetime,
  quantity, // value + unit
  enumeration,
  taxonomy, // reference to a taxonomy/taxon id
  image,
  timeSeries,
  relation, // reference to other entity (batch, strain)
}

/// Unit descriptor for quantity fields.
class Unit {
  final String id; // e.g., 'ml', 'g', '°C', 'cells/mL'
  final String label; // e.g., 'milliliter'
  final String category; // e.g., 'volume', 'mass', 'temperature', 'concentration'

  const Unit({
    required this.id,
    required this.label,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'category': category,
      };

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
        id: json['id'] as String,
        label: json['label'] as String,
        category: json['category'] as String,
      );
}

/// Validation rules for a field.
class ValidationRule {
  final num? min;
  final num? max;
  final int? minLength;
  final int? maxLength;
  final String? pattern; // regex
  final bool? required;

  const ValidationRule({
    this.min,
    this.max,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.required,
  });

  Map<String, dynamic> toJson() => {
        'min': min,
        'max': max,
        'minLength': minLength,
        'maxLength': maxLength,
        'pattern': pattern,
        'required': required,
      };

  factory ValidationRule.fromJson(Map<String, dynamic> json) => ValidationRule(
        min: json['min'] as num?,
        max: json['max'] as num?,
        minLength: json['minLength'] as int?,
        maxLength: json['maxLength'] as int?,
        pattern: json['pattern'] as String?,
        required: json['required'] as bool?,
      );
}

/// Field descriptor is the canonical description of a single data element.
class FieldDescriptor {
  final String id; // stable id, e.g., 'starter_hydration'
  final String label;
  final String? description;
  final FieldType type;
  final List<Unit>? allowedUnits; // for quantity types
  final ValidationRule? validation;
  final bool required; // baseline required flag
  final List<String>? enumOptions; // for enumeration
  final String? taxonomyId; // for taxonomy fields, references Taxonomy.id
  final Map<String, dynamic>? uiHints; // e.g., widget type, placeholder, step, precision
  final dynamic defaultValue;

  const FieldDescriptor({
    required this.id,
    required this.label,
    this.description,
    required this.type,
    this.allowedUnits,
    this.validation,
    this.required = false,
    this.enumOptions,
    this.taxonomyId,
    this.uiHints,
    this.defaultValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'description': description,
        'type': type.toString().split('.').last,
        'allowedUnits': allowedUnits?.map((u) => u.toJson()).toList(),
        'validation': validation?.toJson(),
        'required': required,
        'enumOptions': enumOptions,
        'taxonomyId': taxonomyId,
        'uiHints': uiHints,
        'defaultValue': defaultValue,
      };

  factory FieldDescriptor.fromJson(Map<String, dynamic> json) => FieldDescriptor(
        id: json['id'] as String,
        label: json['label'] as String,
        description: json['description'] as String?,
        type: FieldType.values.firstWhere(
            (e) => e.toString().split('.').last == (json['type'] as String)),
        allowedUnits: (json['allowedUnits'] as List<dynamic>?)
            ?.map((e) => Unit.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        validation: json['validation'] == null
            ? null
            : ValidationRule.fromJson(Map<String, dynamic>.from(json['validation'])),
        required: json['required'] as bool? ?? false,
        enumOptions:
            (json['enumOptions'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        taxonomyId: json['taxonomyId'] as String?,
        uiHints: json['uiHints'] == null ? null : Map<String, dynamic>.from(json['uiHints']),
        defaultValue: json['defaultValue'],
      );

  @override
  String toString() => jsonEncode(toJson());
}