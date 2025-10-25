// SPDX-License-Identifier: MIT
// Model representing a filled form instance (one submission of a DomainTemplate)

import 'dart:convert';

class FormInstance {
  final String id;
  final String templateId;
  DateTime createdAt;
  DateTime updatedAt;

  /// Map from FieldDescriptor.id -> serialized FieldValue (Map)
  /// Example:
  /// {
  ///   'starter_size': { 'descriptorId': 'starter_size', 'value': 50, 'unitId': 'ml' },
  ///   'notes': { 'descriptorId': 'notes', 'value': 'Smelled funky', ... }
  /// }
  Map<String, dynamic> values;

  FormInstance({
    required this.id,
    required this.templateId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? values,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        values = values ?? {};

  FormInstance copyWith({
    String? id,
    String? templateId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? values,
  }) {
    return FormInstance(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      values: values ?? Map<String, dynamic>.from(this.values),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'values': values,
      };

  factory FormInstance.fromJson(Map<String, dynamic> json) {
    return FormInstance(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      values: Map<String, dynamic>.from(json['values'] as Map? ?? {}),
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}