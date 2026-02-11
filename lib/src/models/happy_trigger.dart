/// Defines a satisfaction event that can trigger the review flow.
///
/// A trigger activates when the named event has been recorded
/// at least [minOccurrences] times.
class HappyTrigger {
  /// Identifier for the event (e.g., "purchase_completed").
  final String eventName;

  /// Minimum number of times the event must occur before
  /// this trigger activates.
  final int minOccurrences;

  const HappyTrigger({
    required this.eventName,
    this.minOccurrences = 1,
  }) : assert(minOccurrences > 0, 'minOccurrences must be at least 1');

  @override
  String toString() =>
      'HappyTrigger(eventName: $eventName, minOccurrences: $minOccurrences)';
}
