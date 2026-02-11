import '../adapters/review_storage_adapter.dart';
import 'review_condition.dart';

/// A condition defined by an arbitrary callback.
///
/// Use this when you need business logic that doesn't fit the
/// built-in conditions:
///
/// ```dart
/// CustomCondition(
///   name: 'no_recent_support_ticket',
///   evaluate: () async => !(await hasRecentTicket()),
/// )
/// ```
class CustomCondition extends ReviewCondition {
  /// A descriptive name for debugging and logging.
  final String name;

  final Future<bool> Function() _evaluate;

  const CustomCondition({
    required this.name,
    required Future<bool> Function() evaluate,
  }) : _evaluate = evaluate;

  @override
  Future<bool> evaluate(ReviewStorageAdapter storage) => _evaluate();
}
