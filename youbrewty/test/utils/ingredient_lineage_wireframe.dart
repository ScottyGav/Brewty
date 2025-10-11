/// Recursively print the ingredient lineage as a true hierarchy,
/// expanding MERGE events and batch-ingredient events at the exact event location,
/// and showing batch ancestry and re-use.
///
/// Usage:
///   printIngredientLineageTrueHierarchy(finalBatch, batchMap);
///
/// Arguments:
///   batch: The final (terminal) batch node.
///   batchMap: Map of batchId -> Batch.
///   visited: (optional) Set of batchIds already printed, to prevent cycles.
///   prefix: (optional) String for indentation (used internally).
///
import 'package:youbrewty/models.dart';

void printIngredientLineageTrueHierarchy(
  Batch batch,
  Map<String, Batch> batchMap, {
  Set<String>? visited,
  String prefix = '',
  bool isFinal = true,
}) {
  visited ??= <String>{};
  final seenHere = Set<String>.from(visited); // per-branch
  if (seenHere.contains(batch.batchId)) {
    print('$prefix↳ Batch ${batch.batchId} [see above]');
    return;
  }
  seenHere.add(batch.batchId);

  print('$prefix${isFinal ? "➡️" : "└─"} Batch ${batch.batchId}');
  // Gather events in chronological order: ingredientEvents + mergeEvents
  // Build a timeline of all events (ingredient or merge), sorted by timestamp
  final List<_BatchEvent> timeline = [];
  for (final e in batch.ingredientEvents) {
    timeline.add(_BatchEvent(
      type: _BatchEventType.ingredient,
      event: e,
      timestamp: e.timestamp,
    ));
    // If this is a batch ingredient (e.g. 'batch:BA5608'), we'll expand it below
  }
  if (batch.mergeEvents != null) {
    for (final me in batch.mergeEvents!) {
      timeline.add(_BatchEvent(
        type: _BatchEventType.merge,
        event: me,
        timestamp: me.timestamp,
      ));
    }
  }
  timeline.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  for (final entry in timeline) {
    if (entry.type == _BatchEventType.ingredient) {
      final e = entry.event as IngredientEvent;
      final batchMatch = RegExp(r'^batch:(.+)$').firstMatch(e.ingredient.ingredientType);
      if (batchMatch != null) {
        final mergedBatchId = batchMatch.group(1)!;
        print('$prefix   └─ batch:$mergedBatchId (${e.quantity}ml) @ ${e.timestamp.toIso8601String()}');
        
        // Find corresponding mergeEvent if exists
        MergeEvent? mergeEv;
        if (batch.mergeEvents != null) {
        final matches = batch.mergeEvents!.where(
            (me) => me.type == MergeEventType.ingredient &&
                    me.sourceBatchIds.contains(mergedBatchId) &&
                    me.timestamp == e.timestamp,
        );
        mergeEv = matches.isNotEmpty ? matches.first : null;
        }
        if (mergeEv != null) {
        print('$prefix      └─ MERGE [ingredient] (${mergeEv.timestamp.toIso8601String()}): from ${mergeEv.sourceBatchIds}');
        }


        if (batchMap.containsKey(mergedBatchId)) {
          printIngredientLineageTrueHierarchy(
            batchMap[mergedBatchId]!,
            batchMap,
            visited: seenHere,
            prefix: '$prefix         ',
            isFinal: false,
          );
        } else {
          print('$prefix         (Batch $mergedBatchId missing)');
        }
      } else {
        print('$prefix   └─ ${e.ingredient.ingredientType} (${e.quantity}ml) @ ${e.timestamp.toIso8601String()}');
      }
    }
    if (entry.type == _BatchEventType.merge) {
      final me = entry.event as MergeEvent;
      if (me.type == MergeEventType.creation) {
        print('$prefix   └─ MERGE [creation] (${me.timestamp.toIso8601String()}): from ${me.sourceBatchIds}');
        for (final srcId in me.sourceBatchIds) {
          if (batchMap.containsKey(srcId)) {
            printIngredientLineageTrueHierarchy(
              batchMap[srcId]!,
              batchMap,
              visited: seenHere,
              prefix: '$prefix      ',
              isFinal: false,
            );
          } else {
            print('$prefix      (Batch $srcId missing)');
          }
        }
      } else if (me.type == MergeEventType.ingredient) {
        // Already handled inline with ingredient event above; skip here to prevent duplicate display.
      }
    }
  }
}

// Internal helper for event sorting
enum _BatchEventType { ingredient, merge }
class _BatchEvent {
  final _BatchEventType type;
  final dynamic event; // IngredientEvent or MergeEvent
  final DateTime timestamp;
  _BatchEvent({required this.type, required this.event, required this.timestamp});
}