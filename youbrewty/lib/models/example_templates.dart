// SPDX-License-Identifier: MIT
// Example template registrations for brewing and sourdough shown using the registry.

import 'schema_registry.dart';
import 'field_descriptor.dart';
import 'ontology.dart';

void registerBuiltInTemplates(SchemaRegistry registry) {
  // example units
  final ml = Unit(id: 'ml', label: 'milliliter', category: 'volume');
  final g = Unit(id: 'g', label: 'gram', category: 'mass');
  final celsius = Unit(id: '°C', label: 'Celsius', category: 'temperature');

  // Example Taxonomy: organisms
  final organisms = Taxonomy(id: 'organisms', label: 'Organisms');
  organisms.addTaxon(Taxon(id: 'wild_yeast', label: 'Wild yeast'));
  organisms.addTaxon(Taxon(id: 'saccharomyces', label: 'Saccharomyces', attributes: {'kingdom': 'Fungi'}));
  organisms.addTaxon(Taxon(id: 'lactobacillus', label: 'Lactobacillus', attributes: {'kingdom': 'Bacteria'}));
  registry.registerTaxonomy(organisms);

  // Brewing batch template
  final brewFields = <FieldDescriptor>[
    FieldDescriptor(
      id: 'recipe_name',
      label: 'Recipe name',
      type: FieldType.text,
      required: true,
    ),
    FieldDescriptor(
      id: 'batch_volume',
      label: 'Batch volume',
      type: FieldType.quantity,
      allowedUnits: [ml],
      required: true,
    ),
    FieldDescriptor(
      id: 'pitch_temp',
      label: 'Pitch temperature',
      type: FieldType.quantity,
      allowedUnits: [celsius],
    ),
    FieldDescriptor(
      id: 'starter_size',
      label: 'Starter size',
      type: FieldType.quantity,
      allowedUnits: [ml, g],
      validation: ValidationRule(min: 1),
    ),
    FieldDescriptor(
      id: 'dominant_organism',
      label: 'Dominant organism',
      type: FieldType.taxonomy,
      taxonomyId: 'organisms',
    ),
    FieldDescriptor(
      id: 'notes',
      label: 'Notes',
      type: FieldType.text,
    ),
  ];

  registry.registerTemplate(DomainTemplate(
    id: 'brew_batch_v1',
    label: 'Brewing batch (v1)',
    description: 'Template for brewing batches including starter and organism',
    fields: brewFields,
    recommendedTaxonomy: 'organisms',
  ));

  // Sourdough template
  final sdFields = <FieldDescriptor>[
    FieldDescriptor(
      id: 'starter_hydration',
      label: 'Starter hydration (%)',
      description: 'Percent hydration of starter (water/ flour * 100)',
      type: FieldType.decimal,
      validation: ValidationRule(min: 50, max: 200),
    ),
    FieldDescriptor(
      id: 'feed_ratio',
      label: 'Feed ratio',
      type: FieldType.text,
      description: 'E.g., 1:1:1 (starter:water:flour)',
    ),
    FieldDescriptor(
      id: 'proof_time',
      label: 'Proof time (hours)',
      type: FieldType.decimal,
      allowedUnits: [Unit(id: 'h', label: 'hours', category: 'time')],
    ),
    FieldDescriptor(
      id: 'dominant_organism',
      label: 'Dominant organism',
      type: FieldType.taxonomy,
      taxonomyId: 'organisms',
    ),
  ];

  registry.registerTemplate(DomainTemplate(
    id: 'sourdough_starter_v1',
    label: 'Sourdough starter (v1)',
    description: 'Starter feeding and hydration',
    fields: sdFields,
    recommendedTaxonomy: 'organisms',
  ));
}