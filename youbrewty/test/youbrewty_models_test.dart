import 'package:test/test.dart';
import 'youbrewty_models.dart';

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
}