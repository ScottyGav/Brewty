import 'package:test/test.dart';
import 'package:youbrewty/models.dart';
//--import 'youbrewty_models.dart';

void main() {
  test('Create a Batch and add events', () {
    final batch = Batch(
      batchId: 'B001',
      name: 'Pineapple Pandemic',
      capacity: 20.0,
    );
    batch.ingredientEvents.add(IngredientEvent(
      ingredientType: 'pineapple',
      quantity: 2.0,
      action: IngredientAction.add,
      timestamp: DateTime(2025,10,1),
    ));
    batch.roomHistory.add(RoomEvent(roomId: 'cellar', timestamp: DateTime(2025,10,1)));
    batch.activityHistory.add(ActivityEvent(
      activityLevel: 'high',
      clarity: 'cloudy',
      color: 'yellow',
      sedimentLevel: 'medium',
      timestamp: DateTime(2025,10,2),
    ));
    expect(batch.ingredientEvents.length, 1);
    expect(batch.activityHistory.length, 1);
    expect(batch.roomHistory.first.roomId, 'cellar');
  });

  test('Brewer can favorite clubs and brewers', () {
    final brewer = Brewer(
      brewerId: 'U1',
      name: 'Scotty',
      favoriteBrewerIds: ['U2'],
      favoriteClubIds: ['C1'],
    );
    expect(brewer.favoriteBrewerIds.contains('U2'), true);
    expect(brewer.favoriteClubIds.contains('C1'), true);
  });

  test('Club manages review attributes', () {
    final club = Club(
      clubId: 'C1',
      name: 'Yeast Beasts',
      ownerBrewerId: 'U1',
      reviewAttributes: [
        ClubReviewAttribute(
          attributeId: 'A1',
          clubId: 'C1',
          name: 'Aroma',
          order: 1,
        ),
        ClubReviewAttribute(
          attributeId: 'A2',
          clubId: 'C1',
          name: 'Taste',
          order: 2,
        ),
      ],
    );
    expect(club.reviewAttributes.length, 2);
    expect(club.reviewAttributes[0].name, 'Aroma');
  });

  test('BatchReview supports flexible attributes', () {
    final review = BatchReview(
      reviewId: 'R1',
      batchId: 'B001',
      reviewerBrewerId: 'U2',
      timestamp: DateTime(2025,10,4),
      attributeRatings: [
        AttributeRating(attributeId: 'A1', attributeName: 'Aroma', stars: 4.5),
        AttributeRating(attributeId: 'A2', attributeName: 'Taste', stars: 5),
      ],
      notes: 'Fruity and delicious!',
    );
    expect(review.attributeRatings?.length, 2);
    expect(review.attributeRatings?.first.stars, 4.5);
  });

  test('Sampling event includes photo', () {
    final event = SamplingEvent(
      type: 'photo',
      notes: 'First bubbling!',
      photoPath: '/photos/bubble1.jpg',
      timestamp: DateTime(2025,10,2),
    );
    expect(event.photoPath, isNotNull);
    expect(event.type, 'photo');
  });

   test('Batch lineage: parent and child batches', () {
    final parent = Batch(batchId: 'P1', name: 'Base', capacity: 10);
    final child1 = Batch(batchId: 'C1', name: 'Split1', capacity: 5, parentBatchIds: ['P1']);
    final child2 = Batch(batchId: 'C2', name: 'Split2', capacity: 5, parentBatchIds: ['P1']);
    parent.childBatchIds.addAll(['C1', 'C2']);
    expect(child1.parentBatchIds, contains('P1'));
    expect(parent.childBatchIds, containsAll(['C1', 'C2']));
  });

  test('Ingredient and transfer event history', () {
    final batch = Batch(batchId: 'B1', name: 'Mixer', capacity: 8);
    batch.ingredientEvents.addAll([
      IngredientEvent(ingredientType: 'honey', quantity: 2, action: IngredientAction.add, timestamp: DateTime(2025, 10, 2)),
      IngredientEvent(ingredientType: 'lemon', quantity: 1, action: IngredientAction.add, timestamp: DateTime(2025, 10, 3)),
    ]);
    batch.transferEvents.add(TransferEvent(direction: TransferDirection.TransferOut, volume: 3, targetBatchId: 'B2', timestamp: DateTime(2025, 10, 4)));
    expect(batch.ingredientEvents.length, 2);
    expect(batch.transferEvents.first.volume, 3);
  });

  test('Club review attribute changes are respected', () {
    final club = Club(
      clubId: 'C2',
      name: 'Detail Tasterz',
      ownerBrewerId: 'U3',
      reviewAttributes: [
        ClubReviewAttribute(attributeId: 'A1', clubId: 'C2', name: 'Clarity', order: 1),
        ClubReviewAttribute(attributeId: 'A2', clubId: 'C2', name: 'Mouthfeel', order: 2),
      ],
    );
    // Club changes attribute set
    club.reviewAttributes = [
      ClubReviewAttribute(attributeId: 'A3', clubId: 'C2', name: 'Color', order: 1),
    ];
    expect(club.reviewAttributes.length, 1);
    expect(club.reviewAttributes.first.name, 'Color');
  });

  test('Brewer favorites and notification settings', () {
    final brewer = Brewer(brewerId: 'U5', name: 'Alex');
    brewer.favoriteBrewerIds.add('U9');
    brewer.favoriteClubIds.add('C5');
    brewer.notificationPreferences['C5'] = NotificationPreference.all;
    expect(brewer.favoriteClubIds, contains('C5'));
    expect(brewer.notificationPreferences['C5'], NotificationPreference.all);
  });

  test('Batch review aggregation by attribute', () {
    final batch = Batch(batchId: 'B9', name: 'Big Review', capacity: 20);
    batch.reviews.addAll([
      BatchReview(
        reviewId: 'R1',
        batchId: 'B9',
        reviewerBrewerId: 'U1',
        timestamp: DateTime(2025, 10, 4),
        attributeRatings: [
          AttributeRating(attributeId: 'A1', attributeName: 'Taste', stars: 4),
        ],
      ),
      BatchReview(
        reviewId: 'R2',
        batchId: 'B9',
        reviewerBrewerId: 'U2',
        timestamp: DateTime(2025, 10, 5),
        attributeRatings: [
          AttributeRating(attributeId: 'A1', attributeName: 'Taste', stars: 2),
        ],
      ),
    ]);
    // Calculate average 'Taste'
    final tasteScores = batch.reviews
        .expand((r) => r.attributeRatings!)
        .where((ar) => ar.attributeName == 'Taste')
        .map((ar) => ar.stars)
        .toList();
    final avgTaste = tasteScores.reduce((a, b) => a + b) / tasteScores.length;
    expect(avgTaste, 3);
  });

  test('Room history tracks moves', () {
    final batch = Batch(batchId: 'B101', name: 'Travelin\' Brew', capacity: 5);
    batch.roomHistory.addAll([
      RoomEvent(roomId: 'kitchen', timestamp: DateTime(2025, 10, 1)),
      RoomEvent(roomId: 'cellar', timestamp: DateTime(2025, 10, 5)),
    ]);
    expect(batch.roomHistory.length, 2);
    expect(batch.roomHistory.last.roomId, 'cellar');
  });

  test('Strain tree: batch lineage, reviews, notifications, and ingredient aggregation', () {
  // Step 1: Create batch B1 and add ingredients
  final b1 = Batch(batchId: 'B1', name: 'Ginger Wild', capacity: 800.0);
  b1.ingredientEvents.addAll([
    IngredientEvent(
      ingredientType: 'water',
      quantity: 500,
      action: IngredientAction.add,
      timestamp: DateTime(2025, 1, 1),
    ),
    IngredientEvent(
      ingredientType: 'sugar',
      quantity: 250,
      action: IngredientAction.add,
      timestamp: DateTime(2025, 1, 1),
    ),
    IngredientEvent(
      ingredientType: 'chopped ginger',
      quantity: 1, // 1 tablespoon, could use unit field in a real model
      action: IngredientAction.add,
      timestamp: DateTime(2025, 1, 1),
    ),
    IngredientEvent(
      ingredientType: 'wild yeast',
      quantity: 50,
      action: IngredientAction.add,
      timestamp: DateTime(2025, 1, 1),
    ),
  ]);
  expect(b1.ingredientEvents.length, 4);

  // Step 2: 3 days later, create batch B2 by splitting from B1 and adding more ingredients
  final b2 = Batch(batchId: 'B2', name: 'Ginger Child', capacity: 1250.0, parentBatchIds: ['B1']);
  b2.ingredientEvents.addAll([
    IngredientEvent(
      ingredientType: 'water',
      quantity: 500,
      action: IngredientAction.add,
      timestamp: DateTime(2025, 1, 4),
    ),
    IngredientEvent(
      ingredientType: 'sugar',
      quantity: 250,
      action: IngredientAction.add,
      timestamp: DateTime(2025, 1, 4),
    ),
    IngredientEvent(
      ingredientType: 'B1_batch_liquid',
      quantity: 500,
      action: IngredientAction.add,
      timestamp: DateTime(2025, 1, 4),
    ),
  ]);
  // Link child to parent
  b1.childBatchIds.add('B2');
  expect(b2.parentBatchIds, contains('B1'));
  expect(b1.childBatchIds, contains('B2'));

  // Step 3: 5 days after B2 creation, update B1 with a tasting, review, and rating
  final review = BatchReview(
    reviewId: 'R1',
    batchId: 'B1',
    reviewerBrewerId: 'BrewerA',
    timestamp: DateTime(2025, 1, 9), // 5 days after B2 creation
    overallRating: 4.5,
    attributeRatings: [
      AttributeRating(attributeId: 'A1', attributeName: 'Taste', stars: 5),
      AttributeRating(attributeId: 'A2', attributeName: 'Aroma', stars: 4),
    ],
    notes: 'Very lively! Ginger aroma is strong.',
  );
  b1.reviews.add(review);

  // Simulate notification logic: if B2 is a child of B1 and B1 gets a review, B2 should have a notification
  // (In a real app, this would be a notification object or queue; here we simulate with a flag)
  bool b2HasNotification = false;
  if (b1.childBatchIds.contains('B2') && b1.reviews.isNotEmpty) {
    b2HasNotification = true;
  }
  expect(b2HasNotification, isTrue);

  // Step 4: Get all ratings for the strain tree B2 (i.e., B2 and its ancestors)
  // (For demonstration, only B1 has reviews, but logic should aggregate up the tree)
  List<BatchReview> strainReviews = [];
  // Collect reviews from B2 and from its parent B1
  strainReviews.addAll(b2.reviews);
  if (b2.parentBatchIds.contains(b1.batchId)) {
    strainReviews.addAll(b1.reviews);
  }
  // Report all ratings
  expect(strainReviews.length, 1);
  expect(strainReviews.first.overallRating, 4.5);

  // Step 5: Report the ingredient lineage for B2 in an AI-friendly format
  // We trace up the lineage and collect all ingredient events
  List<IngredientEvent> allIngredients = [];
  // Add B2's own ingredient events
  allIngredients.addAll(b2.ingredientEvents);
  // Also add B1's, since B2 is a child of B1
  allIngredients.addAll(b1.ingredientEvents);
  // Create a simple map for AI input
  final ingredientLineage = allIngredients.map((e) => {
    'ingredient': e.ingredientType,
    'quantity': e.quantity,
    'action': e.action.toString().split('.').last,
    'timestamp': e.timestamp.toIso8601String(),
  }).toList();

  // Print or return this for AI use (for test, just check structure)
  expect(ingredientLineage.where((i) => i['ingredient'] == 'water').length, 2); // water used twice
  expect(ingredientLineage.length, 7);

  // Optionally print for human/AI readability (remove/comment out in production tests)
   print(ingredientLineage);
});

}