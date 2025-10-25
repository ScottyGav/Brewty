import 'package:test/test.dart';
import 'package:youbrewty/models/models.dart';
import 'package:youbrewty/utils/serialization.dart';

void main() {
  test('circular ancestry is preserved and does not crash deserializer', () {
    // Create two batches with circular parent relations
    final a = Batch(batchId: 'A', name: 'A', capacity: 100.0);
    final b = Batch(batchId: 'B', name: 'B', capacity: 200.0);
    a.parentBatchs.add(b);
    b.parentBatchs.add(a);

    final serialized = [batchToJson(a), batchToJson(b)];
    final deserialized = deserializeBatches(serialized);
    final map = { for (var x in deserialized) x.batchId : x };

    expect(map.containsKey('A'), isTrue);
    expect(map.containsKey('B'), isTrue);
    expect(map['A']!.parentBatchs.map((p) => p.batchId).contains('B'), isTrue);
    expect(map['B']!.parentBatchs.map((p) => p.batchId).contains('A'), isTrue);
  });
}
