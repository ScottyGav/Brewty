// SPDX-License-Identifier: MIT
// FieldValue wrapper and basic validation helpers

import 'dart:convert';

import 'field_descriptor.dart';
import 'ontology.dart';

class FieldValue {
  final FieldDescriptor descriptor;
  dynamic value;
  String? unitId; // for quantity fields or unit choices
  String? referencedId; // for relation/taxonomy fields hold referenced entity id

  FieldValue({
    required this.descriptor,
    this.value,
    this.unitId,
    this.referencedId,
  });

  /// Validate according to descriptor.validation. Returns list of error messages (empty = valid).
  List<String> validate(Ontology? ontology) {
    final errors = <String>[];
    final v = value;

    // Required
    final required = descriptor.validation?.required ?? descriptor.required;
    if (required) {
      if (v == null || (v is String && v.trim().isEmpty)) {
        errors.add('${descriptor.label} is required');
        return errors;
      }
    }

    switch (descriptor.type) {
      case FieldType.integer:
        if (v != null && v is! int) errors.add('${descriptor.label} should be an integer');
        break;
      case FieldType.decimal:
      case FieldType.quantity:
        if (v != null && v is! num) errors.add('${descriptor.label} should be a number');
        if (descriptor.type == FieldType.quantity && v != null) {
          if (unitId == null) errors.add('${descriptor.label} requires a unit');
        }
        break;
      case FieldType.enumeration:
        if (v != null && descriptor.enumOptions != null && !descriptor.enumOptions!.contains(v)) {
          errors.add('${descriptor.label} value is not in allowed options');
        }
        break;
      case FieldType.taxonomy:
        if (v != null && descriptor.taxonomyId != null && ontology != null) {
          final tax = ontology.taxonomy(descriptor.taxonomyId!);
          if (tax == null || tax.getTaxon(v.toString()) == null) {
            errors.add('${descriptor.label} references unknown taxonomy value');
          }
        }
        break;
      case FieldType.relation:
        // relation validation is context-specific; allow the app to validate further
        break;
      default:
        break;
    }

    // Number bounds
    if (v is num && descriptor.validation != null) {
      final min = descriptor.validation!.min;
      final max = descriptor.validation!.max;
      if (min != null && v < min) errors.add('${descriptor.label} must be ≥ $min');
      if (max != null && v > max) errors.add('${descriptor.label} must be ≤ $max');
    }

    // String length
    if (v is String && descriptor.validation != null) {
      final minL = descriptor.validation!.minLength;
      final maxL = descriptor.validation!.maxLength;
      if (minL != null && v.length < minL) errors.add('${descriptor.label} length must be ≥ $minL');
      if (maxL != null && v.length > maxL) errors.add('${descriptor.label} length must be ≤ $maxL');
    }

    return errors;
  }

  Map<String, dynamic> toJson() => {
        'descriptorId': descriptor.id,
        'value': value,
        'unitId': unitId,
        'referencedId': referencedId,
      };

  @override
  String toString() => jsonEncode(toJson());
}