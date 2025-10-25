```text
Schema & Ontology — Design Notes

Purpose
- Provide a pluggable, versioned schema system so the app can support multiple fermentation domains (brewing, sourdough, kombucha, cheesemaking) without code changes.
- Keep a canonical ontology/taxonomy layer to normalize domain vocabularies (organisms, ingredient types, container types).

Key Components
- FieldDescriptor: canonical description of a data element (type, validation, units, UI hints).
- Ontology / Taxonomy: hierarchical vocabularies (taxons) replaced by stable ids.
- DomainTemplate: a named set of FieldDescriptors for a given workflow.
- SchemaRegistry: central registry to register domain templates and ontologies at app startup.
- SchemaPlugin: interface to register templates/taxonomies from external packages.
- FieldValue: runtime wrapper for a field instance and basic validation logic.

Usage
1. On app startup, call:
   final registry = SchemaRegistry();
   registry.init(bootstrap: (r) => registerBuiltInTemplates(r));
   // Optionally register additional plugins:
   myPlugin.register(registry);

2. When showing a form for a template:
   final template = registry.getTemplate('brew_batch_v1');
   for (var fd in template.fields) buildWidgetForField(fd);

3. Validation:
   final fv = FieldValue(descriptor: fd, value: inputValue, unitId: chosenUnit);
   final errors = fv.validate(registry.ontology);

Extending
- Add new FieldType entries and UI widget implementations.
- Plugins implement SchemaPlugin and call registry.registerTemplate / registerTaxonomy.
- Taxonomies can be loaded from JSON or remote endpoints; keep taxon ids stable.

Notes on Cross-domain support
- Keep FieldDescriptor.id stable and versioned (e.g., 'brew_batch_v1') to enable migrations.
- Store units with category metadata for safe conversions.
- Provide UI hints to let a single widget factory render many field types.

Next Steps
- Implement UI widget factory that maps FieldDescriptor -> Flutter widget (with localization & unit-picker).
- Add persistence layer for saving filled FieldValue objects to batch records.
- Add migration helpers that map older templates to newer templates when descriptors change.
```