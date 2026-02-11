import '../adapters/review_storage_adapter.dart';
import 'review_condition.dart';

/// Requires a minimum number of days since the library was first initialized.
class MinDaysAfterInstall extends ReviewCondition {
  static const _key = 'install_date';

  final int days;

  const MinDaysAfterInstall({required this.days});

  @override
  Future<bool> evaluate(ReviewStorageAdapter storage) async {
    final installDate = await storage.getDateTime(_key);
    if (installDate == null) return false;

    final elapsed = DateTime.now().difference(installDate);
    return elapsed.inDays >= days;
  }

  /// Records the install date if not already set.
  /// Called internally by [HappyReview.configure].
  static Future<void> recordInstallIfNeeded(
    ReviewStorageAdapter storage,
  ) async {
    final existing = await storage.getDateTime(_key);
    if (existing == null) {
      await storage.setDateTime(_key, DateTime.now());
    }
  }
}
