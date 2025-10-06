// Core Batch and Related Entities

class Batch {
  final String batchId;
  String name;
  double capacity;
  List<IngredientEvent> ingredientEvents;
  List<TransferEvent> transferEvents;
  List<RoomEvent> roomHistory;
  List<ActivityEvent> activityHistory;
  List<SamplingEvent> samplingEvents;
  List<NoteEvent> noteEvents;
  List<String> parentBatchIds;
  List<String> childBatchIds;
  bool isConsumed;
  List<String> sharedWithBrewers;
  List<BatchReview> reviews;

  Batch({
  required this.batchId,
  required this.name,
  required this.capacity,
  List<IngredientEvent>? ingredientEvents,
  List<TransferEvent>? transferEvents,
  List<RoomEvent>? roomHistory,
  List<ActivityEvent>? activityHistory,
  List<SamplingEvent>? samplingEvents,
  List<NoteEvent>? noteEvents,
  List<String>? parentBatchIds,
  List<String>? childBatchIds,
  bool isConsumed = false,
  List<String>? sharedWithBrewers,
  List<BatchReview>? reviews,
})  : ingredientEvents = ingredientEvents ?? [],
      transferEvents = transferEvents ?? [],
      roomHistory = roomHistory ?? [],
      activityHistory = activityHistory ?? [],
      samplingEvents = samplingEvents ?? [],
      noteEvents = noteEvents ?? [],
      parentBatchIds = parentBatchIds ?? [],
      childBatchIds = childBatchIds ?? [],
      sharedWithBrewers = sharedWithBrewers ?? [],
      reviews = reviews ?? [],
      isConsumed = isConsumed;

}

class IngredientEvent {
  final String ingredientType;
  final double quantity;
  final IngredientAction action;
  final DateTime timestamp;

  IngredientEvent({
    required this.ingredientType,
    required this.quantity,
    required this.action,
    required this.timestamp,
  });
}

enum IngredientAction { add, remove }


class TransferEvent {
  final TransferDirection direction;
  final double volume;
  final String? targetBatchId;
  final DateTime timestamp;

  TransferEvent({
    required this.direction,
    required this.volume,
    this.targetBatchId,
    required this.timestamp,
  });
}

enum TransferDirection { TransferIn, TransferOut }

class RoomEvent {
  final String roomId;
  final DateTime timestamp;

  RoomEvent({required this.roomId, required this.timestamp});
}

class Room {
  final String roomId;
  String name;
  double? temperature;
  String? light;

  Room({
    required this.roomId,
    required this.name,
    this.temperature,
    this.light,
  });
}

class ActivityEvent {
  final String? activityLevel;
  final String? clarity;
  final String? color;
  final String? sedimentLevel;
  final DateTime timestamp;

  ActivityEvent({
    this.activityLevel,
    this.clarity,
    this.color,
    this.sedimentLevel,
    required this.timestamp,
  });
}

class SamplingEvent {
  final String type; // taste, smell, photo, etc.
  final String? notes;
  final String? photoPath; // Local or remote URI
  final DateTime timestamp;

  SamplingEvent({
    required this.type,
    this.notes,
    this.photoPath,
    required this.timestamp,
  });
}

class NoteEvent {
  final String note;
  final DateTime timestamp;

  NoteEvent({required this.note, required this.timestamp});
}

// Brewer, Club, Notification

class Brewer {
  final String brewerId;
  String name;
  String? description;
  String? photo;
  List<String> ownedBatchIds;
  List<String> memberClubIds;
  List<String> favoriteBrewerIds;
  List<String> favoriteClubIds;
  Map<String, NotificationPreference> notificationPreferences;

  Brewer({
  required this.brewerId,
  required this.name,
  this.description,
  this.photo,
  List<String>? ownedBatchIds,
  List<String>? memberClubIds,
  List<String>? favoriteBrewerIds,
  List<String>? favoriteClubIds,
  Map<String, NotificationPreference>? notificationPreferences,
})  : ownedBatchIds = ownedBatchIds ?? [],
      memberClubIds = memberClubIds ?? [],
      favoriteBrewerIds = favoriteBrewerIds ?? [],
      favoriteClubIds = favoriteClubIds ?? [],
      notificationPreferences = notificationPreferences ?? {};
}

class Club {
  final String clubId;
  String name;
  String? description;
  String? photo;
  String ownerBrewerId;
  List<String> memberBrewerIds;
  List<String> favoriteByBrewers;
  List<ClubReviewAttribute> reviewAttributes;
  Map<String, NotificationPreference> notificationPreferences;

  Club({
  required this.clubId,
  required this.name,
  this.description,
  this.photo,
  required this.ownerBrewerId,
  List<String>? memberBrewerIds,
  List<String>? favoriteByBrewers,
  List<ClubReviewAttribute>? reviewAttributes,
  Map<String, NotificationPreference>? notificationPreferences,
})  : memberBrewerIds = memberBrewerIds ?? [],
      favoriteByBrewers = favoriteByBrewers ?? [],
      reviewAttributes = reviewAttributes ?? [],
      notificationPreferences = notificationPreferences ?? {};
}

enum NotificationPreference { all, silent, none }

// Review and Attribute System

class BatchReview {
  final String reviewId;
  final String batchId;
  final String reviewerBrewerId;
  final DateTime timestamp;
  final double? overallRating; // 1–5 stars
  final List<AttributeRating>? attributeRatings; // Flexible per club
  final String? notes;

  BatchReview({
    required this.reviewId,
    required this.batchId,
    required this.reviewerBrewerId,
    required this.timestamp,
    this.overallRating,
    this.attributeRatings,
    this.notes,
  });
}

class AttributeRating {
  final String attributeId;
  final String attributeName;
  final double stars; // 1–5

  AttributeRating({
    required this.attributeId,
    required this.attributeName,
    required this.stars,
  });
}

class ClubReviewAttribute {
  final String attributeId;
  final String clubId;
  final String name;
  final String? description;
  final int order;

  ClubReviewAttribute({
    required this.attributeId,
    required this.clubId,
    required this.name,
    this.description,
    required this.order,
  });
}


enum PromptType { tastingNote, labelDescription, review, custom }
enum ThemeType { poetic, concise, playful, classic, custom }
enum StructureType { ingredientLineage, reviewAttributes, batchInfo, custom }

class Prompt {
  final String promptId;
  final PromptType promptType;
  final ThemeType themeType;
  final StructureType structureType;
  final String instruction;
  final String? creatorBrewerId; // null if system/default prompt
  final String? clubId; // null if not club-specific

  Prompt({
    required this.promptId,
    required this.promptType,
    required this.themeType,
    required this.structureType,
    required this.instruction,
    this.creatorBrewerId,
    this.clubId,
  });
}

// Add a List<Prompt> to Club
class Club {
  // ...existing fields...
  List<Prompt> prompts;

  Club({
    // ...existing parameters...
    List<Prompt>? prompts,
    // ...other named params...
  }) : prompts = prompts ?? [];
  // ...existing constructor body...
}

// Add a List<Prompt> to Brewer
class Brewer {
  // ...existing fields...
  List<Prompt> prompts;

  Brewer({
    // ...existing parameters...
    List<Prompt>? prompts,
    // ...other named params...
  }) : prompts = prompts ?? [];
  // ...existing constructor body...
}