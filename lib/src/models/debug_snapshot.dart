/// A snapshot of the library's internal state for debugging.
///
/// Returned by [HappyReview.getDebugSnapshot]. Contains resolved
/// values for every pipeline stage so you can inspect state at a glance.
class DebugSnapshot {
  /// Whether the library is enabled (kill switch).
  final bool enabled;

  /// Whether debug mode is active.
  final bool debugMode;

  /// Whether a dialog adapter is configured.
  final bool hasDialogAdapter;

  /// Status of each configured trigger.
  final List<TriggerStatus> triggers;

  /// Status of each configured prerequisite.
  final List<TriggerStatus> prerequisites;

  /// Whether the platform policy allows showing a prompt now.
  final bool platformPolicyAllows;

  /// Status of each configured condition.
  final List<ConditionStatus> conditions;

  /// Total number of prompts shown.
  final int promptsShown;

  /// Date of the last prompt, or `null` if never shown.
  final DateTime? lastPromptDate;

  /// Date the library was first configured (install date).
  final DateTime? installDate;

  const DebugSnapshot({
    required this.enabled,
    required this.debugMode,
    required this.hasDialogAdapter,
    required this.triggers,
    required this.prerequisites,
    required this.platformPolicyAllows,
    required this.conditions,
    required this.promptsShown,
    required this.lastPromptDate,
    required this.installDate,
  });
}

/// Resolved status of a trigger or prerequisite.
class TriggerStatus {
  /// The event name.
  final String eventName;

  /// Required occurrences to activate.
  final int minOccurrences;

  /// Current count of this event.
  final int currentCount;

  /// Whether the requirement is met.
  bool get isMet => currentCount >= minOccurrences;

  const TriggerStatus({
    required this.eventName,
    required this.minOccurrences,
    required this.currentCount,
  });
}

/// Resolved status of a condition.
class ConditionStatus {
  /// Display name for the condition.
  final String name;

  /// Whether the condition currently passes.
  final bool isMet;

  const ConditionStatus({
    required this.name,
    required this.isMet,
  });
}
