import 'adapters/review_storage_adapter.dart';
import 'models/platform_policy.dart';

/// Internal helper that evaluates platform-specific frequency rules.
class PlatformPolicyChecker {
  static const _lastPromptKey = 'platform_last_prompt';
  static const _promptTimestampsKey = 'platform_prompt_timestamps';

  final PlatformRules rules;
  final ReviewStorageAdapter storage;

  PlatformPolicyChecker({required this.rules, required this.storage});

  /// Returns `true` if the platform policy allows showing a prompt now.
  Future<bool> canShow() async {
    if (!await _checkCooldown()) return false;
    if (!await _checkMaxPrompts()) return false;
    return true;
  }

  /// Records that a prompt was shown.
  Future<void> recordPrompt() async {
    final now = DateTime.now();
    await storage.setDateTime(_lastPromptKey, now);

    // Append timestamp to the list.
    final raw = await storage.getString(_promptTimestampsKey);
    final timestamps = raw != null && raw.isNotEmpty
        ? raw.split(',').map(int.parse).toList()
        : <int>[];
    timestamps.add(now.millisecondsSinceEpoch);
    await storage.setString(
      _promptTimestampsKey,
      timestamps.join(','),
    );
  }

  Future<bool> _checkCooldown() async {
    final lastPrompt = await storage.getDateTime(_lastPromptKey);
    if (lastPrompt == null) return true;

    final elapsed = DateTime.now().difference(lastPrompt);
    return elapsed >= rules.cooldown;
  }

  Future<bool> _checkMaxPrompts() async {
    final raw = await storage.getString(_promptTimestampsKey);
    if (raw == null || raw.isEmpty) return true;

    final now = DateTime.now();
    final cutoff = now.subtract(rules.maxPromptsPeriod);

    final timestamps = raw
        .split(',')
        .map(int.parse)
        .map(DateTime.fromMillisecondsSinceEpoch)
        .where((t) => t.isAfter(cutoff))
        .toList();

    return timestamps.length < rules.maxPrompts;
  }
}
