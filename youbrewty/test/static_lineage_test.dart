import 'package:test/test.dart';
import 'package:youbrewty/models/models.dart';
import 'package:youbrewty/utils/serialization.dart';

/// A small, deterministic static dataset and assertions so expected outcomes
/// are explicit and easy to review.
void main() {
  test('static deterministic lineage and merge structure', () {
    // Build deterministic batches
    final base = Batch(batchId: 'BA1', name: 'Base', capacity: 100.0,
      ingredientEvents: [IngredientEvent(ingredient: Ingredient(ingredientType: 'lemon', introducesStrain: false), quantity: 100.0, action: IngredientAction.add, timestamp: DateTime(2025,1,1))]
    );

    final other = Batch(batchId: 'BA2', name: 'Other', capacity: 120.0,
      ingredientEvents: [IngredientEvent(ingredient: Ingredient(ingredientType: 'water', introducesStrain: false), quantity: 200.0, action: IngredientAction.add, timestamp: DateTime(2025,1,2))]
    );

    final merged = Batch(batchId: 'BA3', name: 'Merged', capacity: 300.0,
      parentBatchs: [base, other],
      ingredientEvents: [IngredientEvent(ingredient: Ingredient(ingredientType: 'sugar', introducesStrain: false), quantity: 50.0, action: IngredientAction.add, timestamp: DateTime(2025,1,3))]
    );

    // Add merge event explicitly
    merged.mergeEvents.add(MergeEvent(hostBatch: merged, sourceBatches: [base, other], timestamp: DateTime(2025,1,3), type: MergeEventType.creation));

    final serialized = [batchToJson(base), batchToJson(other), batchToJson(merged)];
    final deserialized = deserializeBatches(serialized);
    final map = { for (var b in deserialized) b.batchId : b };

    // Basic structure checks
    expect(map.length, equals(3));
    expect(map['BA3']!.parentBatchs.map((p) => p.batchId).toSet(), equals({'BA1','BA2'}));

    // Merge event persisted
    final merges = map['BA3']!.mergeEvents;
    expect(merges.length, equals(1));
    expect(merges.first.sourceBatches.map((b) => b.batchId).toSet(), equals({'BA1','BA2'}));

    // Ingredient events preserved
    expect(map['BA1']!.ingredientEvents.first.ingredient.ingredientType, equals('lemon'));
    expect(map['BA2']!.ingredientEvents.first.ingredient.ingredientType, equals('water'));
    expect(map['BA3']!.ingredientEvents.first.ingredient.ingredientType, equals('sugar'));
  });
}
