Project: YouBrewty — quick guide for AI coding agents

Purpose
- Short, actionable notes to help an AI agent be immediately productive in this Flutter codebase.

Big picture (what to know first)
- This is a Flutter app centered on a domain model for brewing `Batch` objects (see `lib/models.dart`).
- UI is split into simple screens in `lib/screens/` and small reusable widgets in `lib/widgets/` (e.g. `BatchNodeWidget`).
- Lineage and merge logic (batch ancestry, strain transfer events) is implemented in test helpers and in `BatchLineageScreen` UI. Look at the test `test/dynamic_data_generation_test.dart` for the canonical data-generation and lineage algorithms (functions like `generateBatches`, `findTerminalBatches`, `hasMergeInAncestry`, `collectIngredientLineageWithBatch`).

Key files to open first
- `lib/models.dart` — core domain types (Batch, IngredientEvent, MergeEvent, Strain, StrainTransferEvent, Brewer, Club, etc.).
- `lib/main.dart` — app entry. Note: it currently uses a test-data generator path and boots into `BatchLineageScreen` for quick UI debugging.
- `lib/screens/batch_lineage_screen.dart` and `lib/widgets/batch_node_widget.dart` — recursive rendering of batch ancestry (watch for the `visited` set to avoid cycles).
- `test/dynamic_data_generation_test.dart` — authoritative place for lineage algorithms and random data generation; prefer tests when inferring algorithmic intent.
- `pubspec.yaml` — dependencies (notably `graphview`) and Flutter SDK constraints.

Developer workflows / commands (Windows PowerShell)
- Install/update packages:
  ```powershell
  flutter pub get
  ```
- Run the app (desktop):
  ```powershell
  flutter run -d windows
  ```
- Run app on another target (web):
  ```powershell
  flutter run -d chrome
  ```
- Run the test suite (tests include data generation & graph tests):
  ```powershell
  flutter test
  ```

Project-specific conventions & patterns
- Single-file domain model: `lib/models.dart` contains almost all business types. Prefer extending types there when adding domain fields rather than creating duplicated types elsewhere.
- BatchMap pattern: UI code often builds a Map<String, Batch> (batchId -> Batch) and passes it down to widgets; widgets use that map to resolve parents and children. Example: `BatchNodeWidget(batch: rootBatch, batchMap: batchMap)`.
- Recursion with cycle protection: `BatchNodeWidget` and test helpers use a `visited` Set to avoid infinite loops when rendering or traversing ancestry — preserve this pattern when adding traversal or visualization logic.
- Tests-as-spec: behavioral algorithms (lineage collection, merge detection) are implemented and validated in `test/dynamic_data_generation_test.dart`. When changing logic, update tests to capture expected behavior.

Integration points & external dependencies
- Graph and visualization: `graphview` is declared in `pubspec.yaml`. Tests build a `Graph` from `StrainTransferEvent` nodes for network assertions.
- Platform integrations: standard Flutter targets (android/ios/windows/linux/macos/web) are present; platform-specific assets/configs live under respective folders.

Notable smells / TODOs for contributors (discoverable issues)
- `lib/main.dart` imports `utils/test_data.dart` but `lib/utils` is not present in the repo root — the test data generator exists inside `test/dynamic_data_generation_test.dart`. Confirm whether `lib/utils/test_data.dart` should be added or `main.dart` should import from `test/` during dev runs. AI edits touching `main.dart` should either (a) point to `test` utilities or (b) add a local `lib/utils` test helper.
- `models.dart` uses many nullable and optional collections. Keep constructors' defaults consistent when adding new fields to avoid null-related UI crashes.

How the UI chooses the initial screen (important for running/debugging)
- `lib/main.dart` currently builds a `batchMap` from generated batches and selects a random terminal batch that has a merge in its ancestry. If none are found it throws. Be cautious when changing data generation: absence of merged terminal batches will cause a startup exception.

Quick examples (copyable patterns)
- Build `batchMap` from a list of `Batch` objects:
  ```dart
  final batchMap = { for (var b in batches) b.batchId : b };
  ```
- Recurse with cycle detection (pattern used in `BatchNodeWidget`):
  ```dart
  if (visited.contains(batch.batchId)) return Text('↳ ${batch.batchId} [see above]');
  final newVisited = Set<String>.from(visited)..add(batch.batchId);
  ```

When making changes, prioritize
- Updating `test/dynamic_data_generation_test.dart` to encode expected lineage behaviors.
- Preserving `batchMap`-based resolution and `visited` cycle-guard when modifying traversal/rendering.

If you need more context
- Ask for the intended runtime target (desktop, mobile, web) so we can adjust run/debug instructions. Also confirm if `lib/utils/test_data.dart` should be created or `main.dart` should point at the test generator.

End of short guide — request feedback on anything unclear so I can iterate.
