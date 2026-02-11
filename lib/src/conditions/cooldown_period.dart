import '../adapters/review_storage_adapter.dart';
import 'review_condition.dart';

/// Requires a minimum number of days since the last review prompt.
class CooldownPeriod extends ReviewCondition {
  static const _key = 'last_prompt_date';

  final int days;

  const CooldownPeriod({required this.days});

  @override
  Future<bool> evaluate(ReviewStorageAdapter storage) async {
    final lastPrompt = await storage.getDateTime(_key);
    if (lastPrompt == null) return true; // Never prompted before.

    final elapsed = DateTime.now().difference(lastPrompt);
    return elapsed.inDays >= days;
  }

  /// Records the current time as the last prompt date.
  /// Called internally after the review flow is shown.
  static Future<void> recordPrompt(ReviewStorageAdapter storage) async {
    await storage.setDateTime(_key, DateTime.now());
  }
}
