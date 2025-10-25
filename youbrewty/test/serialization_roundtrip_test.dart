import 'package:test/test.dart';
import 'package:youbrewty/models/models.dart';
import 'package:youbrewty/utils/serialization.dart';
import 'package:youbrewty/utils/test_data.dart';

void main() {
  test('serialize -> deserialize roundtrip preserves structure and event links', () {
    // Generate a deterministic-ish dataset for the roundtrip test
    final batches = generateBatchesForUi(batchCount: 12);
    final origMap = { for (var b in batches) b.batchId : b };

    // Serialize
    final serialized = batches.map(batchToJson).toList();

    // Deserialize (round-trip)
    final roundtrip = deserializeBatches(serialized);
    final rtMap = { for (var b in roundtrip) b.batchId : b };

    // Basic checks
    expect(roundtrip.length, equals(batches.length));
    expect(rtMap.keys.toSet(), equals(origMap.keys.toSet()));

    // Parents / children should match by id
    for (final id in origMap.keys) {
      final o = origMap[id]!;
      final r = rtMap[id]!;
      expect(r.parentBatchs.map((p) => p.batchId).toSet(), equals(o.parentBatchs.map((p) => p.batchId).toSet()));
      expect(r.childBatchs.map((c) => c.batchId).toSet(), equals(o.childBatchs.map((c) => c.batchId).toSet()));
    }

    // Merge events: host and sources should match
    for (final id in origMap.keys) {
      final o = origMap[id]!;
      final r = rtMap[id]!;
      expect(r.mergeEvents.length, equals(o.mergeEvents.length));
      for (int i = 0; i < o.mergeEvents.length; i++) {
        final om = o.mergeEvents[i];
        final rm = r.mergeEvents[i];
        // host batch id
        expect(rm.hostBatch.batchId, equals(om.hostBatch.batchId));
        // source batches set
        expect(rm.sourceBatches.map((b) => b.batchId).toSet(), equals(om.sourceBatches.map((b) => b.batchId).toSet()));
      }
    }

    // StrainTransferEvent graph: event ids and previous pointers should be preserved
    final Map<String, StrainTransferEvent> origEvents = {};
    final Map<String, StrainTransferEvent> rtEvents = {};
    for (final b in batches) {
      for (final e in b.strainTransferEvents) origEvents[e.eventId] = e;
    }
    for (final b in roundtrip) {
      for (final e in b.strainTransferEvents) rtEvents[e.eventId] = e;
    }

    expect(rtEvents.keys.toSet(), equals(origEvents.keys.toSet()));

    for (final id in origEvents.keys) {
      final oe = origEvents[id]!;
      final re = rtEvents[id]!;
      final origPrev = oe.previousStrainTransferEvents.map((p) => p?.eventId).toList();
      final rtPrev = re.previousStrainTransferEvents.map((p) => p?.eventId).toList();
      expect(rtPrev, equals(origPrev));
      // source/destination batch ids preserved
      expect(re.destinationBatch.batchId, equals(oe.destinationBatch.batchId));
      expect(re.sourceBatch?.batchId, equals(oe.sourceBatch?.batchId));
    }
  });
}
