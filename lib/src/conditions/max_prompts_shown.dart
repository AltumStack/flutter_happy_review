import '../adapters/review_storage_adapter.dart';
import 'review_condition.dart';

/// Limits the total number of times the review flow can be shown.
class MaxPromptsShown extends ReviewCondition {
  static const _key = 'prompts_shown_count';

  final int maxPrompts;

  const MaxPromptsShown({required this.maxPrompts});

  @override
  Future<bool> evaluate(ReviewStorageAdapter storage) async {
    final count = await storage.getInt(_key);
    return count < maxPrompts;
  }

  /// Increments the prompt counter.
  /// Called internally after the review flow is shown.
  static Future<void> incrementCount(ReviewStorageAdapter storage) async {
    final current = await storage.getInt(_key);
    await storage.setInt(_key, current + 1);
  }
}
