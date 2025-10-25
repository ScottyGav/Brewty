import 'dart:math';
import 'package:test/test.dart';
import 'package:youbrewty/models/models.dart';
import 'utils/ingredient_lineage_wireframe.dart';

import 'package:graphview/GraphView.dart';

void main() {

  final List<Strain> globalStrains = [];
final List<StrainTransferEvent> globalStrainTransferEvents = [];

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

final List<Ingredient> ingredients = [
  Ingredient(ingredientType: 'water', introducesStrain: false),
  Ingredient(ingredientType: 'honey', introducesStrain: false),
  Ingredient(ingredientType: 'apple', introducesStrain: true),
  Ingredient(ingredientType: 'grape', introducesStrain: true),
    
    Ingredient(ingredientType: 'sugar', introducesStrain: false),
    Ingredient(ingredientType: 'ginger', introducesStrain: true),
    Ingredient(ingredientType: 'lemon', introducesStrain: true),
    Ingredient(ingredientType: 'yeast', introducesStrain: true),
  // Add more as needed...
];


// (removed) copyIngredientEvents was unused — helper removed to clean analyzer warnings

List<StrainTransferEvent?> findLatestStrainTransferEventForStrain(Batch batch, Strain strain, List<StrainTransferEvent?> latestStrainTransferEventForStrain) {
  // Filter events for the given strain


 

  final eventsForStrain = batch.strainTransferEvents.where((e) => e.strain.strainId == strain.strainId).toList();
  if (eventsForStrain.isNotEmpty){

       eventsForStrain.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      //return eventsForStrain.first;
      latestStrainTransferEventForStrain.add(eventsForStrain.first);
  }
  else
  {
    //for all parent parentBatchs, get the last event fro this same strain
    for(final parentBatch in batch.parentBatchs)
    {
        final event = findLatestStrainTransferEventForStrain(parentBatch, strain, latestStrainTransferEventForStrain);
        latestStrainTransferEventForStrain.addAll(event);
    }
  }
   return latestStrainTransferEventForStrain;
}

/// Adds each strain from [sourceBatch] as a new ingredient transfer event in [destinationBatch].
/// For every strain in the source batch, creates a StrainTransferEvent in the destination batch.
void addBatchAsIngredient({
  required Batch sourceBatch,
  required Batch destinationBatch,
  required DateTime timestamp,
}) {
  for (final strain in sourceBatch.strains) {

     List<StrainTransferEvent?> latestStrainTransferEventForStrain = [];
findLatestStrainTransferEventForStrain(sourceBatch, strain, latestStrainTransferEventForStrain);

print("latestStrainTransferEventForStrain.length addBatchAsIngredient: "+latestStrainTransferEventForStrain.length.toString());


    final event = StrainTransferEvent(
      eventId: '${destinationBatch.batchId}_${strain.strainId}_${timestamp.toIso8601String()}',
      previousStrainTransferEvents: latestStrainTransferEventForStrain,
      strain: strain,
      sourceBatch: sourceBatch,
      destinationBatch: destinationBatch,
      timestamp: timestamp
    );
    destinationBatch.strainTransferEvents.add(event);

    globalStrainTransferEvents.add(event);

    strain.strainTransferEvents.add(event);
  }
}


/*
/// Generates a random list of Ingredient objects from the given [ingredients] collection.
/// [count] specifies how many ingredients to pick.
/// The same ingredient may be picked more than once.
List<Ingredient> randomIngredientsList(int count, List<Ingredient> ingredients) {
  final random = Random();
  return List.generate(
    count,
    (_) => ingredients[random.nextInt(ingredients.length)],
  );
}
*/
/// Selects a single random Ingredient from the given [ingredients] list.
Ingredient randomIngredient(List<Ingredient> ingredients) {
  final random = Random();
  return ingredients[random.nextInt(ingredients.length)];
}


    //final ingredients = ['water', 'sugar', 'honey', 'ginger', 'lemon', 'yeast', 'apple juice', 'grape juice'];

    List<IngredientEvent> randomIngredientEvents(int count, DateTime start) {
      return List.generate(count, (i) => IngredientEvent(
            ingredient:  randomIngredient(ingredients),
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
          ingredientEvents: randomIngredientEvents(1 + random.nextInt(3), start.add(Duration(days: i))),
          sharedWithBrewers: [brewer.brewerId],
          roomHistory: [
            RoomEvent(room: room, timestamp: start.add(Duration(days: i))),
          ],
        );
        brewer.ownedBatchs.add(batch);
        batches.add(batch);

        batch.ingredientEvents.forEach((event) {
         if(event.ingredient.introducesStrain)
         {
            print("event.ingredient.introducesStrain NewBatch: ${event.ingredient.ingredientType}");

            //add a new strain to the batch and global list
            final newStrain = Strain(
              strainId: 'S${globalStrains.length + 1}',
              strainName: 'Strain ${globalStrains.length + 1}',
              ingrediant: event.ingredient, //source ingrediant reference
              initialDate: event.timestamp,
              brewerId: brewer.brewerId,
              description: 'A strain introduced by ${event.ingredient.ingredientType}',
            );

            List<StrainTransferEvent?> latestStrainTransferEventForStrain = [];
            findLatestStrainTransferEventForStrain(batch, newStrain,latestStrainTransferEventForStrain);
            print("latestStrainTransferEventForStrain.length: "+latestStrainTransferEventForStrain.length.toString());

            //create a StrainTransferEvent for this new strain into the batch
            final strainEvent = StrainTransferEvent(
              eventId: '${batch.batchId}_${newStrain.strainId}_${event.timestamp.toIso8601String()}',
              previousStrainTransferEvents: latestStrainTransferEventForStrain,
              strain: newStrain,
              sourceBatch: null, // no source batch, it's introduced here
              destinationBatch: batch,
              timestamp: event.timestamp,
            );

            batch.strainTransferEvents.add(strainEvent);
            globalStrainTransferEvents.add(strainEvent);

            batch.strains.add(newStrain);
            globalStrains.add(newStrain); 

            newStrain.strainTransferEvents.add(strainEvent);

         }
        });
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
          ingredientEvents: randomIngredientEvents(1 + random.nextInt(2), start.add(Duration(days: count + i))),
          sharedWithBrewers: [brewer.brewerId],
          roomHistory: [
            RoomEvent(room: room, timestamp: start.add(Duration(days: count + i))),
          ],
          parentBatchs: [batches[parentA], batches[parentB]],
        );

        mergeBatch.ingredientEvents.forEach((event) {
         
         if(event.ingredient.introducesStrain)
         {

            print("event.ingredient.introducesStrain mergeBatch: ${event.ingredient.ingredientType}");

            //add a new strain to the batch and global list
            final newStrain = Strain(
              strainId: 'S${globalStrains.length + 1}',
              strainName: 'Strain ${globalStrains.length + 1}',
              ingrediant: event.ingredient, //source ingrediant reference
              initialDate: event.timestamp,
              brewerId: brewer.brewerId,
              description: 'A strain introduced by ${event.ingredient.ingredientType}',
            );

          List<StrainTransferEvent?> latestStrainTransferEventForStrain = [];
            findLatestStrainTransferEventForStrain(mergeBatch, newStrain,latestStrainTransferEventForStrain);
            print("latestStrainTransferEventForStrain.length: "+latestStrainTransferEventForStrain.length.toString());

            //create a StrainTransferEvent for this new strain into the batch
            final strainEvent = StrainTransferEvent(
              eventId: '${mergeBatch.batchId}_${newStrain.strainId}_${event.timestamp.toIso8601String()}',
              previousStrainTransferEvents: latestStrainTransferEventForStrain,
              strain: newStrain,
              sourceBatch: null, // no source batch, it's introduced here
              destinationBatch: mergeBatch,
              timestamp: event.timestamp,
            );
            
            mergeBatch.strainTransferEvents.add(strainEvent);
            globalStrainTransferEvents.add(strainEvent);

            mergeBatch.strains.add(newStrain);
            globalStrains.add(newStrain); 

            newStrain.strainTransferEvents.add(strainEvent);
         }

        });

        brewer.ownedBatchs.add(mergeBatch);

        // Add merge event (type: creation)
        final mergeEvent = MergeEvent(
          hostBatch: mergeBatch,
          sourceBatches: [batches[parentA], batches[parentB]],
          timestamp: start.add(Duration(days: count + i, hours: random.nextInt(24))),
          type: MergeEventType.creation,
        );
        
        mergeBatch.mergeEvents = [mergeEvent];
        allMergeEvents.add(mergeEvent);

        // Link children to parents
        batches[parentA].childBatchs.add(mergeBatch);
        batches[parentB].childBatchs.add(mergeBatch);

        batches.add(mergeBatch);
      }

      // Randomly simulate ingredient-merge events (add an entire batch as ingredient)
      for (int i = 0; i < count ~/ 2; i++) {
        var hostIdx = random.nextInt(batches.length);
        var sourceIdx = random.nextInt(batches.length);
        if (hostIdx == sourceIdx) continue;
        var host = batches[hostIdx];
        var source = batches[sourceIdx];

/*
        // Add the ingredient event representing an ingredient batch addition
        host.ingredientEvents.add(IngredientEvent(
          ingredient: 'batch:${source.batchId}',
          quantity: (random.nextDouble() * 250).roundToDouble(),
          action: IngredientAction.add,
          timestamp: start.add(Duration(days: count * 2 + i)),
        ));
*/
       // copyIngredientEvents(source, host);

      //probably to be added to a merge event function later
       addBatchAsIngredient(
          sourceBatch: source,
          destinationBatch: host,
          timestamp: DateTime.now(),
        );

        // Add merge event (type: ingredient)
        final mergeEvent = MergeEvent(
          hostBatch: host,
          sourceBatches: [source],
          timestamp: start.add(Duration(days: count * 2 + i)),
          type: MergeEventType.ingredient,
        );

  host.mergeEvents.add(mergeEvent);
        allMergeEvents.add(mergeEvent);

        // Optionally, make the host batch a child of the source batch
        source.childBatchs.add(host);
        host.parentBatchs.add(source);
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
        'ingredient': e.ingredient.ingredientType,
        'quantity': e.quantity,
        'action': e.action.toString().split('.').last,
        'timestamp': e.timestamp.toIso8601String(),
      }).toList();

      for (var parent in batch.parentBatchs) {
        // parent is a Batch object (models use object references for ancestry)
        lineage.addAll(collectIngredientLineageWithBatch(parent, batchMap, visited));
      }
      return lineage;
    }

    // (removed) printIngredientLineageHierarchy helper — the project uses
    // printIngredientLineageTrueHierarchy (in test/utils) as the canonical printer.

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
        batches.where((b) => b.childBatchs.isEmpty).toList();

    // Filter for terminal batches with a merge in their ancestry
    bool hasMergeInAncestry(Batch batch, Map<String, Batch> batchMap, [Set<String>? visited]) {
      visited ??= {};
      if (visited.contains(batch.batchId)) return false;
      visited.add(batch.batchId);

      if (batch.mergeEvents.any((me) => me.sourceBatches.length > 1)) return true;
      for (final parent in batch.parentBatchs) {
        if (hasMergeInAncestry(parent, batchMap, visited)) {
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

  group('StrainTransferEvent network diagram construction', () {
    test('should generate a network graph from random StrainTransferEvents', () {
      // Generate test data
      

      // Create a graph where nodes are StrainTransferEvents and edges are relationships (e.g., transfer between batches)
      final Graph graph = Graph();
      final Map<String, Node> eventNodes = {};

      // 1. Create nodes for each StrainTransferEvent
      for (var globalStrainTransferEvent in globalStrainTransferEvents) {
        eventNodes[globalStrainTransferEvent.eventId] = Node.Id(
          '${globalStrainTransferEvent.eventId} ',
        );
        graph.addNode(eventNodes[globalStrainTransferEvent.eventId]!);
      }

      // 2. Create edges between events (sourceBatchId links)
      for (var globalStrainTransferEvent in globalStrainTransferEvents) {
          for(final previousEvent in globalStrainTransferEvent.previousStrainTransferEvents)
          {
            if(previousEvent != null && eventNodes.containsKey(previousEvent.eventId))
            {
                graph.addEdge(eventNodes[previousEvent.eventId]!, eventNodes[globalStrainTransferEvent.eventId]!);
            }
          }
      }

      // 3. Assert that all nodes are present
      expect(graph.nodeCount(), globalStrainTransferEvents.length);

      // 4. Optionally, assert expected edge count, connectivity, etc.
      // For a more advanced test, you could check for cycles, connectivity, etc.

      // 5. Print graph info for debugging (optional)
      print('Graph has ${graph.nodeCount()} nodes and ${graph.edges.length} edges.');
    });

  });
}