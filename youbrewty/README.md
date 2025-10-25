# youbrewty

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- Start Android studio -> More Actions -> Virtual Device Manager -> Pixel 9 Pro XL
- CMD : C:\Dev\YouBrewty\youbrewty
- flutter test
- flutter run
- 
- GitHup -> Repo -> Scpaces, to continue AI chat


# YouBrewty — AI Instruction & Developer Guide

This README captures the AI-generated instructions, code examples, and developer guidance produced during an interactive conversation that covered: modeling StrainTransferEvent networks, test scaffolds, helper functions, VS Code setup (Dart/Flutter and GitHub Copilot / Copilot Chat), common Dart tips, and running tests. Treat this document as the canonical reference for the code and workflow discussed.

---

## What I compiled for you

I read through the conversation and assembled the following practical content:
- Dart/Flutter test scaffolds and helper functions for Strain/StrainTransferEvent modeling.
- A unit test example that builds a graph of StrainTransferEvent nodes and edges.
- Utility functions:
  - `extractStrainTransferEvents` — returns generated test events.
  - `addBatchAsIngredient` — copies strains from a source batch into a destination batch as StrainTransferEvents.
- Troubleshooting advice for a missing dependency (`graphview`) and how to add it to `pubspec.yaml`.
- VS Code recommendations (Dart, Flutter, GitHub Copilot, Copilot Chat) and how to enable them.
- Common Dart tips: list initialization, `addAll`, static properties, renaming variables across the project, sharing test fixtures, and test run commands.

Below you will find structured usage instructions, code snippets, and commands so you can copy/paste directly into your repository.

---

## Quick table of contents

- Model & Test helpers
  - extractStrainTransferEvents
  - addBatchAsIngredient
  - Example test: `test/strain_transfer_network_diagram_test.dart`
  - Example extractor file: `test/strain_transfer_event_extraction.dart`
- VS Code setup
  - Extensions to install
  - Enabling GitHub Copilot and Copilot Chat
- Dependency fix: graphview
- Dart tips & small patterns
  - Initialize lists
  - Add one list to another
  - Static properties
  - Rename symbol (F2)
- Running & testing commands

---

## Model & Test helpers

Add or adapt these files within your project. These are the functions and test scaffolds discussed.

1) extractStrainTransferEvents — returns a list of generated events
```dart
// test/strain_transfer_event_extraction.dart
import 'package:youbrewty_models/strain_transfer_event.dart';
import 'package:youbrewty_models/dynamic_data_generation_test.dart';

/// Returns a list of StrainTransferEvents from the generated test data.
/// [count] is the number of events to generate and return.
List<StrainTransferEvent> extractStrainTransferEvents({int count = 10}) {
  return generateRandomStrainTransferEvents(count: count);
}
```

2) addBatchAsIngredient — add strains from sourceBatch as ingredient events into destinationBatch
```dart
// lib/utils/batch_utils.dart
import 'package:youbrewty_models/batch.dart';
import 'package:youbrewty_models/strain_transfer_event.dart';

/// Adds each strain from [sourceBatch] as a new ingredient transfer event in [destinationBatch].
/// Returns the list of newly created events.
List<StrainTransferEvent> addBatchAsIngredient({
  required Batch sourceBatch,
  required Batch destinationBatch,
  required DateTime timestamp,
}) {
  final List<StrainTransferEvent> newEvents = [];
  for (final strain in sourceBatch.strainHistory) {
    final event = StrainTransferEvent(
      eventId: '${destinationBatch.batchId}_${strain.strainId}_${timestamp.toIso8601String()}',
      strain: strain,
      destinationBatch: destinationBatch,
      timestamp: timestamp,
      transferType: 'ingredient',
  sourceBatch: sourceBatch,
      sourceIngredientType: null,
    );
    // Assumes destinationBatch.strainTransferEvents is a mutable List<StrainTransferEvent>
    destinationBatch.strainTransferEvents.add(event);
    newEvents.add(event);
  }
  return newEvents;
}
```

3) Example unit test (graph construction) — nodes are StrainTransferEvents, edges are relationships
```dart
// test/strain_transfer_network_diagram_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

import 'package:youbrewty_models/strain_transfer_event.dart';
import 'package:youbrewty_models/dynamic_data_generation_test.dart';
import 'strain_transfer_event_extraction.dart';

void main() {
  group('StrainTransferEvent network diagram construction', () {
    test('should generate a network graph from random StrainTransferEvents', () {
      // Generate test data
      final List<StrainTransferEvent> events = extractStrainTransferEvents(count: 10);

      // Create a graph where nodes are StrainTransferEvents and edges are relationships
      final Graph graph = Graph();
      final Map<String, Node> eventNodes = {};

      // 1. Create nodes for each StrainTransferEvent
      for (var event in events) {
        eventNodes[event.eventId] = Node.Text(
          '${event.strain.strainName} → ${event.destinationBatch.batchId}\n${event.timestamp}',
        );
        graph.addNode(eventNodes[event.eventId]!);
      }

      // 2. Create edges between events (sourceBatchId links)
      for (var event in events) {
        if (event.sourceBatch != null) {
          final prevEvent = events.firstWhere(
            (e) => e.destinationBatch.batchId == event.sourceBatch.batchId && e.strain.strainId == event.strain.strainId,
            orElse: () => null,
          );
          if (prevEvent != null) {
            graph.addEdge(eventNodes[prevEvent.eventId]!, eventNodes[event.eventId]!);
          }
        }
      }

      // 3. Assert that all nodes are present
      expect(graph.nodeCount(), events.length);

      // Debugging info
      print('Graph has ${graph.nodeCount()} nodes and ${graph.edgeCount()} edges.');
    });
  });
}
```

Notes:
- Adapt field names to your actual model if they differ (e.g., `strainHistory`, `strainTransferEvents`).
- `extractStrainTransferEvents` uses your `generateRandomStrainTransferEvents` utility from `dynamic_data_generation_test.dart`.

---

## Dependency: graphview

If you see:
```
Error: Couldn't resolve the package 'graphview' in 'package:graphview/GraphView.dart'.
```
Then add the dependency and fetch packages.

In `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  graphview: ^1.2.0   # check https://pub.dev/packages/graphview for latest version
```

Then run:
```bash
flutter pub get
```

If you are writing pure Dart tests (no Flutter), ensure the package supports pure Dart or switch to a test-friendly graph library.

---

## VS Code — recommended extensions & setup

Essential extensions:
- Dart (Dart language support)
- Flutter (if you use Flutter)
- GitHub Copilot (code completion)
- GitHub Copilot Chat (conversational assistant inside VS Code)
- Bracket Pair Colorizer 2
- Error Lens
- Better Comments
- GitLens

Enable Copilot Chat:
1. Install **GitHub Copilot Chat** from Extensions.
2. Sign in: Command Palette → `GitHub: Sign in`.
3. Open chat: Command Palette → `GitHub Copilot Chat: Open Chat`.
4. Allow workspace access when prompted for file-aware answers.

Troubleshooting:
- If Copilot/Chat fails to sign in, ensure you have a Copilot subscription and allow pop-ups in the browser.
- Restart VS Code after extension installs.

Recommended settings (in `settings.json`):
```json
{
  "editor.formatOnSave": true,
  "dart.lineLength": 80,
  "files.exclude": {
    "**/.dart_tool": true,
    "**/build": true
  }
}
```

---

## Dart tips & small patterns

- Declare a public list:
```dart
class MyClass {
  List<String> items = []; // public by default (no underscore)
}
```

- Initialize lists:
```dart
final List<String> fruits = ['apple','banana'];
final List<int> empty = [];
final List<int> zeros = List.filled(5, 0);
final List<int> squares = List.generate(5, (i) => i * i);
```

- Add all elements from one list to another:
```dart
list1.addAll(list2);
```

- Static class property:
```dart
class Example {
  static int counter = 0;
}
```

- Rename symbol across files in VS Code:
  - Place cursor on name, press `F2` (Rename Symbol). This updates all occurrences using the analyzer.

---

## Sharing data across tests

Important: test files run in separate isolates/processes. A list created dynamically in one test file at runtime will not automatically be populated in another test file.

Options:
- Put the collection in a shared fixture file (top-level, non-private), import it into tests. But runtime modifications inside one test execution don't cross process boundaries.
- Serialize dynamic data to disk (JSON) from one test, then read it in another test.
- Recommended: initialize or generate fresh data in each test (or use deterministic fixtures) for reproducibility.

Example shared fixture:
```dart
// test/test_data.dart
final List<MyModel> sharedFixtures = [ /* static objects */ ];
```

---

## Running & testing commands

Prerequisites:
- Flutter SDK or Dart SDK installed and on your PATH.
- Run `flutter doctor` to verify.

Install dependencies:
- Flutter project: `flutter pub get`
- Pure Dart package: `dart pub get`

Run app:
- `flutter run`
- `flutter devices`
- `flutter run -d <deviceId>`

Run tests:
- All tests: `flutter test` or `dart test` (pure Dart).
- Single test file: `flutter test test/strain_transfer_network_diagram_test.dart`
- Single test by line: `flutter test test/path/file_test.dart:NN`

Generate coverage:
- `flutter test --coverage` (creates `coverage/lcov.info`)

Formatting and analysis:
- `flutter format .`
- `flutter analyze`

Clean:
- `flutter clean`

---

## Troubleshooting common issues

- "Couldn't resolve the package 'graphview'": add to `pubspec.yaml`, run `flutter pub get`.
- Tests failing due to missing generated code: run `flutter pub run build_runner build --delete-conflicting-outputs`.
- Shared runtime state not visible across test files: tests are isolated — use fixtures or serialization.

---

## Example usage flow (what I did and what's next)

I collected the functions and test scaffolds we discussed and turned them into usable code snippets and file examples above. You can drop these into your repo (adjusting model-field names where necessary). Next, add `graphview` to `pubspec.yaml` and run `flutter pub get`, then run the test file shown to validate graph construction. If you'd like, I can generate complete files ready to commit, or adapt everything to match your exact model names and types.

---

If you want, I can:
- Produce complete file contents (ready to paste into your repo) for each example above.
- Convert the extracts into actual test fixtures or integration tests.
- Provide a small script to serialize test data so separate tests can reuse runtime-created collections.

If you want me to produce the files now, tell me which files you want generated and where to place them.