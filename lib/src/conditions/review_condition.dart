import '../adapters/review_storage_adapter.dart';

/// Base class for conditions that must be satisfied before the
/// review flow can start.
///
/// Implement [evaluate] to define custom business rules. The library
/// provides several built-in conditions:
/// - [MinDaysAfterInstall]
/// - [CooldownPeriod]
/// - [MaxPromptsShown]
/// - [CustomCondition]
abstract class ReviewCondition {
  const ReviewCondition();

  /// Returns `true` if this condition is satisfied.
  ///
  /// [storage] is provided so conditions can read persisted state.
  Future<bool> evaluate(ReviewStorageAdapter storage);
}
