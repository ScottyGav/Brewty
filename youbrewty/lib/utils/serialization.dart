import '../models.dart';

/// Lightweight (de)serialization helpers to map object references to IDs for
/// persistence or network transport, and to rehydrate objects into memory.
///
/// Note: these helpers are intentionally conservative — they serialize the
/// primary fields and event references needed for lineage/traversal. They
/// perform a two-pass deserialization: first create Batch shells, then
/// resolve references (parents, children, event batch refs).

Map<String, dynamic> ingredientEventToJson(IngredientEvent e) => {
  'ingredientType': e.ingredient.ingredientType,
  'quantity': e.quantity,
  'action': e.action.toString().split('.').last,
  'timestamp': e.timestamp.toIso8601String(),
};

IngredientEvent ingredientEventFromJson(Map<String, dynamic> j) => IngredientEvent(
      ingredient: Ingredient(ingredientType: j['ingredientType'] as String),
      quantity: (j['quantity'] as num).toDouble(),
      action: IngredientAction.values.firstWhere((a) => a.toString().endsWith(j['action'] as String)),
      timestamp: DateTime.parse(j['timestamp'] as String),
    );

Map<String, dynamic> roomEventToJson(RoomEvent r) => {
  'roomId': r.room.roomId,
  'timestamp': r.timestamp.toIso8601String(),
};

Map<String, dynamic> transferEventToJson(TransferEvent t) => {
  'direction': t.direction.toString().split('.').last,
  'volume': t.volume,
  'targetBatchId': t.targetBatch?.batchId,
  'timestamp': t.timestamp.toIso8601String(),
};

Map<String, dynamic> strainToJson(Strain s) => {
  'strainId': s.strainId,
  'strainName': s.strainName,
  'ingredientType': s.ingrediant.ingredientType,
  'initialDate': s.initialDate.toIso8601String(),
  'brewerId': s.brewerId,
  'description': s.description,
};

Map<String, dynamic> strainTransferEventToJson(StrainTransferEvent e) => {
  'eventId': e.eventId,
  'previousEventIds': e.previousStrainTransferEvents.map((p) => p?.eventId).toList(),
  'strainId': e.strain.strainId,
  'sourceBatchId': e.sourceBatch?.batchId,
  'destinationBatchId': e.destinationBatch.batchId,
  'timestamp': e.timestamp.toIso8601String(),
};

Map<String, dynamic> mergeEventToJson(MergeEvent m) => {
  'hostBatchId': m.hostBatch.batchId,
  'sourceBatchIds': m.sourceBatches.map((b) => b.batchId).toList(),
  'timestamp': m.timestamp.toIso8601String(),
  'type': m.type.toString().split('.').last,
};

Map<String, dynamic> batchReviewToJson(BatchReview r) => {
  'reviewId': r.reviewId,
  'batchId': r.batch.batchId,
  'reviewerBrewerId': r.reviewerBrewerId,
  'timestamp': r.timestamp.toIso8601String(),
  'overallRating': r.overallRating,
  'notes': r.notes,
};

Map<String, dynamic> batchToJson(Batch b) => {
  'batchId': b.batchId,
  'name': b.name,
  'capacity': b.capacity,
  'ingredientEvents': b.ingredientEvents.map(ingredientEventToJson).toList(),
  'transferEvents': b.transferEvents.map(transferEventToJson).toList(),
  'strainTransferEvents': b.strainTransferEvents.map(strainTransferEventToJson).toList(),
  'roomHistory': b.roomHistory.map(roomEventToJson).toList(),
  'parentBatchIds': b.parentBatchs.map((p) => p.batchId).toList(),
  'childBatchIds': b.childBatchs.map((c) => c.batchId).toList(),
  'isConsumed': b.isConsumed,
  'sharedWithBrewers': b.sharedWithBrewers,
  'reviews': b.reviews.map(batchReviewToJson).toList(),
  'mergeEvents': b.mergeEvents.map(mergeEventToJson).toList(),
  'strains': b.strains.map(strainToJson).toList(),
};

/// Deserialize a list of batches previously serialized with [batchToJson].
/// Performs a two-pass approach: first create Batch shells, then resolve refs.
List<Batch> deserializeBatches(List<Map<String, dynamic>> serialized) {
  // First pass: create Batch shells and index by id
  final Map<String, Batch> batchMap = {};
  // collect all serialized strain transfer events so we can resolve previous-event pointers in a third pass
  final List<Map<String, dynamic>> _serializedStrainEvents = [];
  for (final m in serialized) {
    final b = Batch(
      batchId: m['batchId'] as String,
      name: m['name'] as String,
      capacity: (m['capacity'] as num).toDouble(),
      ingredientEvents: [],
      transferEvents: [],
      strainTransferEvents: [],
      roomHistory: [],
      parentBatchs: [],
      childBatchs: [],
      sharedWithBrewers: List<String>.from(m['sharedWithBrewers'] ?? []),
      reviews: [],
      mergeEvents: [],
      strains: [],
    );
    batchMap[b.batchId] = b;
  }

  // Second pass: populate lists and resolve references
  for (final m in serialized) {
    final b = batchMap[m['batchId'] as String]!;

    // ingredient events
    final ie = (m['ingredientEvents'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    b.ingredientEvents.addAll(ie.map(ingredientEventFromJson));

    // transfer events (resolve targetBatch by id)
    final te = (m['transferEvents'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    for (final t in te) {
      final targetId = t['targetBatchId'] as String?;
      b.transferEvents.add(TransferEvent(
        direction: TransferDirection.values.firstWhere((d) => d.toString().endsWith(t['direction'] as String)),
        volume: (t['volume'] as num).toDouble(),
        targetBatch: targetId != null ? batchMap[targetId] : null,
        timestamp: DateTime.parse(t['timestamp'] as String),
      ));
    }

    // room history
    final rh = (m['roomHistory'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    for (final r in rh) {
      b.roomHistory.add(RoomEvent(room: Room(roomId: r['roomId'] as String, name: ''), timestamp: DateTime.parse(r['timestamp'] as String)));
    }

    // strains
    final ss = (m['strains'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    for (final s in ss) {
      final strain = Strain(
        strainId: s['strainId'] as String,
        strainName: s['strainName'] as String,
        ingrediant: Ingredient(ingredientType: s['ingredientType'] as String),
        initialDate: DateTime.parse(s['initialDate'] as String),
        brewerId: s['brewerId'] as String,
        description: s['description'] as String,
      );
      b.strains.add(strain);
    }

  // Collect serialized strain transfer events for later (we resolve previous pointers in a 3rd pass)
  final st = (m['strainTransferEvents'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  _serializedStrainEvents.addAll(st);

    // merge events
    final me = (m['mergeEvents'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    for (final mme in me) {
      final host = batchMap[mme['hostBatchId'] as String]!;
      final sources = (mme['sourceBatchIds'] as List<dynamic>).cast<String>().map((id) => batchMap[id]!).toList();
      b.mergeEvents.add(MergeEvent(
        hostBatch: host,
        sourceBatches: sources,
        timestamp: DateTime.parse(mme['timestamp'] as String),
        type: MergeEventType.values.firstWhere((t) => t.toString().endsWith(mme['type'] as String)),
      ));
    }

    // parent/child relations
    final pids = (m['parentBatchIds'] as List<dynamic>? ?? []).cast<String>();
    b.parentBatchs.addAll(pids.map((id) => batchMap[id]!).toList());
    final cids = (m['childBatchIds'] as List<dynamic>? ?? []).cast<String>();
    b.childBatchs.addAll(cids.map((id) => batchMap[id]!).toList());

    // reviews
    final rv = (m['reviews'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    for (final rj in rv) {
      b.reviews.add(BatchReview(
        reviewId: rj['reviewId'] as String,
        batch: batchMap[rj['batchId'] as String]!,
        reviewerBrewerId: rj['reviewerBrewerId'] as String,
        timestamp: DateTime.parse(rj['timestamp'] as String),
        overallRating: (rj['overallRating'] as num?)?.toDouble(),
        notes: rj['notes'] as String?,
      ));
    }
  }
  // Third pass: construct StrainTransferEvent objects and resolve previous-event pointers
  final Map<String, StrainTransferEvent> _eventMap = {};

  // Build a global strain index (strainId -> Strain)
  final Map<String, Strain> _strainMap = {};
  for (final b in batchMap.values) {
    for (final s in b.strains) {
      _strainMap[s.strainId] = s;
    }
  }

  // 1) Create event objects with empty previous lists and index them
  for (final se in _serializedStrainEvents) {
    final eventId = se['eventId'] as String;
    final dstId = se['destinationBatchId'] as String;
    final dstBatch = batchMap[dstId]!;
    final strainId = se['strainId'] as String;
    final strain = _strainMap[strainId] ?? Strain(
      strainId: strainId,
      strainName: strainId,
      ingrediant: Ingredient(ingredientType: ''),
      initialDate: DateTime.now(),
      brewerId: '',
      description: '',
    );
    final srcId = se['sourceBatchId'] as String?;
    final srcBatch = srcId != null ? batchMap[srcId] : null;

    final evt = StrainTransferEvent(
      eventId: eventId,
      previousStrainTransferEvents: [],
      strain: strain,
      sourceBatch: srcBatch,
      destinationBatch: dstBatch,
      timestamp: DateTime.parse(se['timestamp'] as String),
    );

    dstBatch.strainTransferEvents.add(evt);
    strain.strainTransferEvents.add(evt);
    _eventMap[eventId] = evt;
  }

  // 2) Resolve previous-event pointers by recreating events with resolved references
  for (final se in _serializedStrainEvents) {
    final eventId = se['eventId'] as String;
    final prevIds = (se['previousEventIds'] as List<dynamic>? ?? []).cast<String?>();
    final resolved = prevIds.map((id) => id != null ? _eventMap[id] : null).toList();

    final oldEvt = _eventMap[eventId]!;
    final newEvt = StrainTransferEvent(
      eventId: oldEvt.eventId,
      previousStrainTransferEvents: resolved,
      strain: oldEvt.strain,
      sourceBatch: oldEvt.sourceBatch,
      destinationBatch: oldEvt.destinationBatch,
      timestamp: oldEvt.timestamp,
    );

    // Replace in destination batch list
    final dst = newEvt.destinationBatch;
    final idx = dst.strainTransferEvents.indexWhere((e) => e.eventId == eventId);
    if (idx != -1) dst.strainTransferEvents[idx] = newEvt;

    // Replace in strain's event list
    final sIdx = newEvt.strain.strainTransferEvents.indexWhere((e) => e.eventId == eventId);
    if (sIdx != -1) newEvt.strain.strainTransferEvents[sIdx] = newEvt;

    _eventMap[eventId] = newEvt;
  }

  return batchMap.values.toList();
}
