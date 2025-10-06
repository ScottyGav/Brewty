import 'dart:math';
import 'package:test/test.dart';
import '../lib/models.dart';
import 'utils/ingredient_lineage_wireframe.dart';


void main() {
  group('Dynamic Data Generation and Lineage', () {
    final random = Random();

    String randomId(String prefix) => '$prefix${random.nextInt(10000)}';

    // Generate random clubs
    List<Club> generateClubs(int count) => List.generate(count, (i) => Club(
          clubId: randomId('C'),
          name: 'Club ${i + 1}',
          ownerBrewerId: '', // will assign later
        ));

    // Generate brewers and assign each to a club
    List<Brewer> generateBrewers(int count, List<Club> clubs) => List.generate(count, (i) {
      final club = clubs[random.nextInt(clubs.length)];
      final brewer = Brewer(
        brewerId: randomId('B'),
        name: 'Brewer ${i + 1}',
        memberClubIds: [club.clubId],
      );
      if (club.ownerBrewerId.isEmpty) club.ownerBrewerId = brewer.brewerId;
      if (!club.memberBrewerIds.contains(brewer.brewerId)) {
        club.memberBrewerIds.add(brewer.brewerId);
      }
      return brewer;
    });

    // Each brewer gets one or more rooms
    Map<String, List<Room>> generateRooms(List<Brewer> brewers, {int minRooms = 1, int maxRooms = 3}) {
      final roomsByBrewer = <String, List<Room>>{};
      for (var brewer in brewers) {
        int roomCount = minRooms + random.nextInt(maxRooms - minRooms + 1);
        roomsByBrewer[brewer.brewerId] = List.generate(roomCount, (i) =>
          Room(
            roomId: randomId('R'),
            name: 'Room ${i + 1} of ${brewer.name}',
            // Optionally add a brewerId field to Room if you wish
          )
        );
      }
      return roomsByBrewer;
    }

    final ingredients = ['water', 'sugar', 'honey', 'ginger', 'lemon', 'yeast', 'apple juice', 'grape juice'];
    List<IngredientEvent> randomIngredients(int count, DateTime start) {
      return List.generate(count, (i) => IngredientEvent(
            ingredientType: ingredients[random.nextInt(ingredients.length)],
            quantity: (random.nextDouble() * 500).roundToDouble(),
            action: IngredientAction.add,
            timestamp: start.add(Duration(hours: i)),
          ));
    }

    // Each batch belongs to a brewer and is placed in one of that brewer's rooms
    List<Batch> generateBatches(
      int count,
      DateTime start,
      List<Brewer> brewers,
      Map<String, List<Room>> roomsByBrewer,
      List<MergeEvent> allMergeEvents,
    ) {
      List<Batch> batches = [];
      // Build initial batches (no parents)
      for (int i = 0; i < count; i++) {
        final brewer = brewers[random.nextInt(brewers.length)];
        final brewerRooms = roomsByBrewer[brewer.brewerId]!;
        final room = brewerRooms[random.nextInt(brewerRooms.length)];
        final batch = Batch(
          batchId: randomId('BA'),
          name: 'Batch ${i + 1}',
          capacity: 500 + random.nextInt(1000).toDouble(),
          ingredientEvents: randomIngredients(1 + random.nextInt(3), start.add(Duration(days: i))),
          sharedWithBrewers: [brewer.brewerId],
          roomHistory: [
            RoomEvent(roomId: room.roomId, timestamp: start.add(Duration(days: i))),
          ],
        );
        brewer.ownedBatchIds.add(batch.batchId);
        batches.add(batch);
      }

      // Random batch splits/merges (simulate merges at creation)
      for (int i = 0; i < count ~/ 2; i++) {
        // Pick 2 distinct batches as parents
        List<int> idxs = List.generate(batches.length, (i) => i)..shuffle(random);
        int parentA = idxs[0];
        int parentB = idxs[1];
        if (parentA == parentB) continue;

        // Create a new merged batch from parentA and parentB
        final brewer = brewers[random.nextInt(brewers.length)];
        final brewerRooms = roomsByBrewer[brewer.brewerId]!;
        final room = brewerRooms[random.nextInt(brewerRooms.length)];
        final mergeBatchId = randomId('BA');
        final mergeBatch = Batch(
          batchId: mergeBatchId,
          name: 'MergedBatch ${i + 1}',
          capacity: 500 + random.nextInt(1000).toDouble(),
          ingredientEvents: randomIngredients(1 + random.nextInt(2), start.add(Duration(days: count + i))),
          sharedWithBrewers: [brewer.brewerId],
          roomHistory: [
            RoomEvent(roomId: room.roomId, timestamp: start.add(Duration(days: count + i))),
          ],
          parentBatchIds: [batches[parentA].batchId, batches[parentB].batchId],
        );
        brewer.ownedBatchIds.add(mergeBatch.batchId);

        // Add merge event (type: creation)
        final mergeEvent = MergeEvent(
          hostBatchId: mergeBatchId,
          sourceBatchIds: [batches[parentA].batchId, batches[parentB].batchId],
          timestamp: start.add(Duration(days: count + i, hours: random.nextInt(24))),
          type: MergeEventType.creation,
        );
        mergeBatch.mergeEvents = [mergeEvent];
        allMergeEvents.add(mergeEvent);

        // Link children to parents
        batches[parentA].childBatchIds.add(mergeBatchId);
        batches[parentB].childBatchIds.add(mergeBatchId);

        batches.add(mergeBatch);
      }

      // Randomly simulate ingredient-merge events (add an entire batch as ingredient)
      for (int i = 0; i < count ~/ 2; i++) {
        var hostIdx = random.nextInt(batches.length);
        var sourceIdx = random.nextInt(batches.length);
        if (hostIdx == sourceIdx) continue;
        var host = batches[hostIdx];
        var source = batches[sourceIdx];

        // Add the ingredient event representing an ingredient batch addition
        host.ingredientEvents.add(IngredientEvent(
          ingredientType: 'batch:${source.batchId}',
          quantity: (random.nextDouble() * 250).roundToDouble(),
          action: IngredientAction.add,
          timestamp: start.add(Duration(days: count * 2 + i)),
        ));

        // Add merge event (type: ingredient)
        final mergeEvent = MergeEvent(
          hostBatchId: host.batchId,
          sourceBatchIds: [source.batchId],
          timestamp: start.add(Duration(days: count * 2 + i)),
          type: MergeEventType.ingredient,
        );
        host.mergeEvents = (host.mergeEvents ?? [])..add(mergeEvent);
        allMergeEvents.add(mergeEvent);

        // Optionally, make the host batch a child of the source batch
        source.childBatchIds.add(host.batchId);
        host.parentBatchIds.add(source.batchId);
      }

      return batches;
    }

    // --- Lineage functions ---

    // Chronological, batchId-annotated lineage
    List<Map<String, Object>> collectIngredientLineageWithBatch(
      Batch batch,
      Map<String, Batch> batchMap, [
      Set<String>? visited,
    ]) {
      visited ??= <String>{};
      if (visited.contains(batch.batchId)) return [];
      visited.add(batch.batchId);

      List<Map<String, Object>> lineage = batch.ingredientEvents.map((e) => {
        'batchId': batch.batchId,
        'ingredient': e.ingredientType,
        'quantity': e.quantity,
        'action': e.action.toString().split('.').last,
        'timestamp': e.timestamp.toIso8601String(),
      }).toList();

      for (var parentId in batch.parentBatchIds) {
        if (batchMap.containsKey(parentId)) {
          lineage.addAll(collectIngredientLineageWithBatch(batchMap[parentId]!, batchMap, visited));
        }
      }
      return lineage;
    }

    // Hierarchical wireframe with merge events
    void printIngredientLineageHierarchy(
      Batch batch,
      Map<String, Batch> batchMap, {
      String prefix = '',
      Set<String>? visited,
      bool isFinal = true,
    }) {
      visited ??= <String>{};
      if (visited.contains(batch.batchId)) return;
      visited.add(batch.batchId);

      print('$prefix${isFinal ? "➡️" : "└─"} Batch ${batch.batchId}');
      for (var e in batch.ingredientEvents) {
        print('$prefix   └─ ${e.ingredientType} (${e.quantity}ml) @ ${e.timestamp.toIso8601String()}');
      }

      // Print merge events
      if ((batch.mergeEvents ?? []).isNotEmpty) {
        for (var me in batch.mergeEvents!) {
          print('$prefix   └─ MERGE [${me.type}] (${me.timestamp.toIso8601String()}): from ${me.sourceBatchIds}');
        }
      }

      // Print parents (if any)
      for (var i = 0; i < batch.parentBatchIds.length; i++) {
        final parentId = batch.parentBatchIds[i];
        final parentBatch = batchMap[parentId];
        if (parentBatch != null) {
          final isLast = i == batch.parentBatchIds.length - 1;
          final childPrefix = prefix + (isFinal ? '   ' : '   ') + (isLast ? '   ' : '│  ');
          printIngredientLineageHierarchy(
            parentBatch,
            batchMap,
            prefix: childPrefix,
            visited: visited,
            isFinal: false,
          );
        }
      }
    }

    // Chronological wireframe
    void printIngredientLineageWireframeChrono(List<Map<String, Object>> lineage, String finalBatchId) {
      final sorted = List<Map<String, Object>>.from(lineage)
        ..sort((a, b) {
          final ta = DateTime.parse(a['timestamp'] as String);
          final tb = DateTime.parse(b['timestamp'] as String);
          final cmp = ta.compareTo(tb);
          if (cmp != 0) return cmp;
          return (a['batchId'] as String).compareTo(b['batchId'] as String);
        });

      print('\nIngredient Lineage Wireframe (chronological, final batch: $finalBatchId):');
      for (var e in sorted) {
        final isFinal = (e['batchId'] == finalBatchId);
        print(' ${isFinal ? '➡️' : '  '} [${e['batchId']}] ${e['ingredient']} (${e['quantity']}ml) @ ${e['timestamp']}');
      }
    }

    // Find all terminal batches (no children)
    List<Batch> findTerminalBatches(List<Batch> batches) =>
        batches.where((b) => b.childBatchIds.isEmpty).toList();

    // Filter for terminal batches with a merge in their ancestry
    bool hasMergeInAncestry(Batch batch, Map<String, Batch> batchMap, [Set<String>? visited]) {
      visited ??= {};
      if (visited.contains(batch.batchId)) return false;
      visited.add(batch.batchId);

      if ((batch.mergeEvents ?? []).any((me) => me.sourceBatchIds.length > 1)) return true;
      for (final pid in batch.parentBatchIds) {
        final parent = batchMap[pid];
        if (parent != null && hasMergeInAncestry(parent, batchMap, visited)) {
          return true;
        }
      }
      return false;
    }

    test('Generate, link, and merge data, then collect ingredient lineage for a merged terminal batch', () {
      final clubs = generateClubs(3);
      final brewers = generateBrewers(5, clubs);
      final roomsByBrewer = generateRooms(brewers);
      final allMergeEvents = <MergeEvent>[];
      final batches = generateBatches(8, DateTime(2025, 1, 1), brewers, roomsByBrewer, allMergeEvents);

      final batchMap = { for (var b in batches) b.batchId : b };

      // Find terminal batches with a merge in their ancestry
      final terminalBatches = findTerminalBatches(batches);
      final mergedTerminalBatches = terminalBatches.where((b) => hasMergeInAncestry(b, batchMap)).toList();

      if (mergedTerminalBatches.isEmpty) {
        throw Exception('No terminal batches found that are also merge nodes or have merges in their ancestry!');
      }
      final finalBatch = mergedTerminalBatches[random.nextInt(mergedTerminalBatches.length)];

      // =================== Output ===================
      print('Final batch: ${finalBatch.batchId} (${finalBatch.name})\n');

      // Chronological lineage output
      final lineage = collectIngredientLineageWithBatch(finalBatch, batchMap);
      printIngredientLineageWireframeChrono(lineage, finalBatch.batchId);

      // Hierarchy wireframe with merge events
      print('\nIngredient Lineage Hierarchy:');
      //printIngredientLineageHierarchy(finalBatch, batchMap);
      printIngredientLineageTrueHierarchy(finalBatch, batchMap);

      // Useful for AI input or further processing
      final aiInput = lineage.map((e) => {
        'batchId': e['batchId'],
        'ingredient': e['ingredient'],
        'quantity': e['quantity'],
        'action': e['action'],
        'timestamp': e['timestamp'],
      }).toList();
      print('\nAI lineage JSON: $aiInput');

      // Simple assertion: lineage is not empty
      expect(lineage, isNotEmpty);
    });
  });
}