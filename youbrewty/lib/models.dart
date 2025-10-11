/// Represents a brewing batch, which may be composed of ingredients,
/// one or more parent batches (in case of merges), and may itself become
/// an ingredient or parent for other batches.
class Batch {
   /// Unique identifier for this batch.
  final String batchId;
    /// Human-readable name for the batch.
  String name;
    /// Maximum capacity of the batch in milliliters.
  double capacity;
    /// List of events where ingredients were added, removed, or modified.
  List<IngredientEvent> ingredientEvents;
  List<TransferEvent> transferEvents;
    /// History of which rooms this batch was kept in, with timestamps.
  List<RoomEvent> roomHistory;
  List<ActivityEvent> activityHistory;
  List<SamplingEvent> samplingEvents;
  List<NoteEvent> noteEvents;
    /// List of batch IDs that are direct parents of this batch (merge ancestry).
  List<String> parentBatchIds;
  /// List of batch IDs that are direct children of this batch (batches that inherit from this one).
  List<String> childBatchIds;
  bool isConsumed;
    /// List of brewer IDs with whom this batch is shared.
  List<String> sharedWithBrewers;
  List<BatchReview> reviews;
  /// List of merge events that occurred for this batch (either at creation or during its lifecycle).
  List<MergeEvent> mergeEvents;

  List<Strain> strains;

  /// Creates a new [Batch] instance.
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
  List<MergeEvent>? mergeEvents,
  List<Strain>? strains,
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
      isConsumed = isConsumed,
      mergeEvents = mergeEvents ?? [];
      strains = strains ?? []

}
/// Represents an event where an ingredient was added, removed, or otherwise acted upon in a batch.
class IngredientEvent {
   /// Type/name of the ingredient (e.g., "honey", "batch:BA1234").
  final String ingredientType;
   /// Quantity (in milliliters) of the ingredient used in this event.
  final double quantity;
    /// The action performed (add, remove, etc.).
  final IngredientAction action;
  /// Timestamp when this ingredient event occurred.
  final DateTime timestamp;

    /// Indicates if this ingredient is expected to introduce a microbial strain (e.g., yeast, bacteria).
  /// If true, the system should ensure a corresponding Strain object is added to the batch's strainHistory.
  final bool introducesStrain;

  /// Creates a new [IngredientEvent] instance.
  IngredientEvent({
    required this.ingredientType,
    required this.quantity,
    required this.action,
    required this.timestamp,
    this.introducesStrain = false,
  });
}


/// Enum representing an action performed on an ingredient in a batch.
enum IngredientAction { 
  add, /// Ingredient was added to the batch.
  remove, /// Ingredient was removed from the batch.
   custom, /// Ingredient was otherwise manipulated (custom).
  }


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

/// Represents an event where a batch is moved to a different room.
class RoomEvent {
  final String roomId;/// The room's unique identifier.
  final DateTime timestamp; /// The timestamp when the batch entered this room.
 
 /// Creates a new [RoomEvent] instance.
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

class Strain{
  final Strin ingrediant; //source ingrediant reference
  Final DateTime initialDate;
  final string brewerId;
  final string description;
  final List<StrainTransferHistory> strainTransferHistory;

  Strain({
    required this.ingrediant, //source ingrediant reference
    required this.initialDate,
    required this.brewerId,
    required this.description,
    List<StrainTransferHistory>? strainTransferHistory,
  }) : strainTransferHistory = strainTransferHistory ?? [];
}

class StrainTransferHistory{
  final String batchId;
  final DateTime dateStart;
  final DateTime dateEnd;
  final String transferId;

  StrainTransferHistory ({
    required this.batchId,
    required this.dateStart,
    required this.dateEnd,
    required this.transferId,
  });

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
  List<Prompt> prompts;


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
  List<Prompt>? prompts,
})  : ownedBatchIds = ownedBatchIds ?? [],
      memberClubIds = memberClubIds ?? [],
      favoriteBrewerIds = favoriteBrewerIds ?? [],
      favoriteClubIds = favoriteClubIds ?? [],
      notificationPreferences = notificationPreferences ?? {}, 
      prompts = prompts ?? [];
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
  List<Prompt>? prompts;

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
  List<Prompt>? prompts,
})  : memberBrewerIds = memberBrewerIds ?? [],
      favoriteByBrewers = favoriteByBrewers ?? [],
      reviewAttributes = reviewAttributes ?? [],
      notificationPreferences = notificationPreferences ?? {}, 
      prompts = prompts ?? [];
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

/// Enum representing the type of merge event that can occur in a batch.
enum MergeEventType { 
  /// Merge occurred during batch creation (multiple parents specified at creation).
  creation, 
  /// Merge occurred by adding another batch as an ingredient during the batch's lifecycle.
  ingredient 
  }

/// Represents an event where multiple batches are merged into a host batch,
/// either at creation or as an ingredient event during the batch's life.
class MergeEvent {
  final String hostBatchId;              // The batch receiving the merge
  final List<String> sourceBatchIds;     // The batch IDs being merged in  (sources).
  final DateTime timestamp;               /// Timestamp when the merge event occurred.
  final MergeEventType type;            /// The type of merge event (creation or ingredient).

  MergeEvent({
    required this.hostBatchId,
    required this.sourceBatchIds,
    required this.timestamp,
    required this.type,
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

