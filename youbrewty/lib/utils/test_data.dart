import 'dart:math';

import '../models.dart';

// Shared random instance used by main.dart for deterministic-ish selection
final Random random = Random();

// Global collections used by the generator (mirrors test helpers)
final List<Strain> globalStrains = [];
final List<StrainTransferEvent> globalStrainTransferEvents = [];

String randomId(String prefix) => '$prefix${random.nextInt(10000)}';

// Sample ingredients used by the generator
final List<Ingredient> ingredients = [
  Ingredient(ingredientType: 'water', introducesStrain: false),
  Ingredient(ingredientType: 'honey', introducesStrain: false),
  Ingredient(ingredientType: 'apple', introducesStrain: true),
  Ingredient(ingredientType: 'grape', introducesStrain: true),
  Ingredient(ingredientType: 'sugar', introducesStrain: false),
  Ingredient(ingredientType: 'ginger', introducesStrain: true),
  Ingredient(ingredientType: 'lemon', introducesStrain: true),
  Ingredient(ingredientType: 'yeast', introducesStrain: true),
];

Ingredient randomIngredient(List<Ingredient> ingredients) => ingredients[random.nextInt(ingredients.length)];

List<IngredientEvent> randomIngredientEvents(int count, DateTime start) {
  return List.generate(count, (i) => IngredientEvent(
        ingredient: randomIngredient(ingredients),
        quantity: (random.nextDouble() * 500).roundToDouble(),
        action: IngredientAction.add,
        timestamp: start.add(Duration(hours: i)),
      ));
}

List<Club> generateClubs(int count) => List.generate(count, (i) => Club(
      clubId: randomId('C'),
      name: 'Club ${i + 1}',
      ownerBrewerId: '',
    ));

List<Brewer> generateBrewers(int count, List<Club> clubs) => List.generate(count, (i) {
      final club = clubs[random.nextInt(clubs.length)];
      final brewer = Brewer(
        brewerId: randomId('B'),
        name: 'Brewer ${i + 1}',
        memberClubIds: [club.clubId],
      );
      if (club.ownerBrewerId.isEmpty) club.ownerBrewerId = brewer.brewerId;
      if (!club.memberBrewerIds.contains(brewer.brewerId)) club.memberBrewerIds.add(brewer.brewerId);
      return brewer;
    });

Map<String, List<Room>> generateRooms(List<Brewer> brewers, {int minRooms = 1, int maxRooms = 3}) {
  final roomsByBrewer = <String, List<Room>>{};
  for (var brewer in brewers) {
    int roomCount = minRooms + random.nextInt(maxRooms - minRooms + 1);
    roomsByBrewer[brewer.brewerId] = List.generate(roomCount, (i) => Room(
          roomId: randomId('R'),
          name: 'Room ${i + 1} of ${brewer.name}',
        ));
  }
  return roomsByBrewer;
}

/// Finds the latest strain transfer events for [strain] within [batch] or its parents.
List<StrainTransferEvent?> findLatestStrainTransferEventForStrain(
    Batch batch, Strain strain, List<StrainTransferEvent?> latestStrainTransferEventForStrain) {
  final eventsForStrain = batch.strainTransferEvents.where((e) => e.strain.strainId == strain.strainId).toList();
  if (eventsForStrain.isNotEmpty) {
    eventsForStrain.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    latestStrainTransferEventForStrain.add(eventsForStrain.first);
  } else {
    for (final parentBatch in batch.parentBatchs) {
      // parentBatch is modeled as Batch in this codebase; recurse to find events
      final event = findLatestStrainTransferEventForStrain(parentBatch, strain, latestStrainTransferEventForStrain);
      latestStrainTransferEventForStrain.addAll(event);
    }
  }
  return latestStrainTransferEventForStrain;
}

void addBatchAsIngredient({
  required Batch sourceBatch,
  required Batch destinationBatch,
  required DateTime timestamp,
}) {
  for (final strain in sourceBatch.strains) {
    List<StrainTransferEvent?> latestStrainTransferEventForStrain = [];
    findLatestStrainTransferEventForStrain(sourceBatch, strain, latestStrainTransferEventForStrain);

    final event = StrainTransferEvent(
      eventId: '${destinationBatch.batchId}_${strain.strainId}_${timestamp.toIso8601String()}',
      previousStrainTransferEvents: latestStrainTransferEventForStrain,
      strain: strain,
      sourceBatch: sourceBatch,
      destinationBatch: destinationBatch,
      timestamp: timestamp,
    );
    destinationBatch.strainTransferEvents.add(event);
    globalStrainTransferEvents.add(event);
    strain.strainTransferEvents.add(event);
  }
}

List<Batch> generateBatches(
  int count,
  DateTime start,
  List<Brewer> brewers,
  Map<String, List<Room>> roomsByBrewer,
  List<MergeEvent> allMergeEvents,
) {
  List<Batch> batches = [];

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
      roomHistory: [RoomEvent(room: room, timestamp: start.add(Duration(days: i)))],
    );
    brewer.ownedBatchs.add(batch);
    batches.add(batch);

    for (var event in batch.ingredientEvents) {
      if (event.ingredient.introducesStrain) {
        final newStrain = Strain(
          strainId: 'S${globalStrains.length + 1}',
          strainName: 'Strain ${globalStrains.length + 1}',
          ingrediant: event.ingredient,
          initialDate: event.timestamp,
          brewerId: brewer.brewerId,
          description: 'A strain introduced by ${event.ingredient.ingredientType}',
        );

        List<StrainTransferEvent?> latest = [];
        findLatestStrainTransferEventForStrain(batch, newStrain, latest);

        final strainEvent = StrainTransferEvent(
          eventId: '${batch.batchId}_${newStrain.strainId}_${event.timestamp.toIso8601String()}',
          previousStrainTransferEvents: latest,
          strain: newStrain,
          sourceBatch: null,
          destinationBatch: batch,
          timestamp: event.timestamp,
        );

        batch.strainTransferEvents.add(strainEvent);
        globalStrainTransferEvents.add(strainEvent);
        batch.strains.add(newStrain);
        globalStrains.add(newStrain);
        newStrain.strainTransferEvents.add(strainEvent);
      }
    }
  }

  // Random merges (create merged batches)
  for (int i = 0; i < count ~/ 2; i++) {
    List<int> idxs = List.generate(batches.length, (i) => i)..shuffle(random);
    int parentA = idxs[0];
    int parentB = idxs[1];
    if (parentA == parentB) continue;

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
      roomHistory: [RoomEvent(room: room, timestamp: start.add(Duration(days: count + i)))],
      parentBatchs: [batches[parentA], batches[parentB]],
    );

    for (var event in mergeBatch.ingredientEvents) {
      if (event.ingredient.introducesStrain) {
        final newStrain = Strain(
          strainId: 'S${globalStrains.length + 1}',
          strainName: 'Strain ${globalStrains.length + 1}',
          ingrediant: event.ingredient,
          initialDate: event.timestamp,
          brewerId: brewer.brewerId,
          description: 'A strain introduced by ${event.ingredient.ingredientType}',
        );

        List<StrainTransferEvent?> latest = [];
        findLatestStrainTransferEventForStrain(mergeBatch, newStrain, latest);

        final strainEvent = StrainTransferEvent(
          eventId: '${mergeBatch.batchId}_${newStrain.strainId}_${event.timestamp.toIso8601String()}',
          previousStrainTransferEvents: latest,
          strain: newStrain,
          sourceBatch: null,
          destinationBatch: mergeBatch,
          timestamp: event.timestamp,
        );

        mergeBatch.strainTransferEvents.add(strainEvent);
        globalStrainTransferEvents.add(strainEvent);
        mergeBatch.strains.add(newStrain);
        globalStrains.add(newStrain);
        newStrain.strainTransferEvents.add(strainEvent);
      }
    }

    brewer.ownedBatchs.add(mergeBatch);

    final mergeEvent = MergeEvent(
      hostBatch: mergeBatch,
      sourceBatches: [batches[parentA], batches[parentB]],
      timestamp: start.add(Duration(days: count + i, hours: random.nextInt(24))),
      type: MergeEventType.creation,
    );

    mergeBatch.mergeEvents = [mergeEvent];
    allMergeEvents.add(mergeEvent);

    batches[parentA].childBatchs.add(mergeBatch);
    batches[parentB].childBatchs.add(mergeBatch);

    batches.add(mergeBatch);
  }

  // Random ingredient-merge events (add entire batch as ingredient)
  for (int i = 0; i < count ~/ 2; i++) {
    var hostIdx = random.nextInt(batches.length);
    var sourceIdx = random.nextInt(batches.length);
    if (hostIdx == sourceIdx) continue;
    var host = batches[hostIdx];
    var source = batches[sourceIdx];

    addBatchAsIngredient(sourceBatch: source, destinationBatch: host, timestamp: DateTime.now());

    final mergeEvent = MergeEvent(
      hostBatch: host,
      sourceBatches: [source],
      timestamp: start.add(Duration(days: count * 2 + i)),
      type: MergeEventType.ingredient,
    );

    host.mergeEvents.add(mergeEvent);
    allMergeEvents.add(mergeEvent);

    source.childBatchs.add(host);
    host.parentBatchs.add(source);
  }

  return batches;
}

// Utility used by main.dart
List<Batch> findTerminalBatches(List<Batch> batches) => batches.where((b) => b.childBatchs.isEmpty).toList();

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

/// Public convenience used by `main.dart` to get a seeded random-ish dataset for UI.
List<Batch> generateBatchesForUi({int batchCount = 8}) {
  final clubs = generateClubs(3);
  final brewers = generateBrewers(5, clubs);
  final roomsByBrewer = generateRooms(brewers);
  final allMergeEvents = <MergeEvent>[];
  final batches = generateBatches(batchCount, DateTime(2025, 1, 1), brewers, roomsByBrewer, allMergeEvents);
  return batches;
}
