import 'package:happy_review/happy_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Example [ReviewStorageAdapter] backed by SharedPreferences.
///
/// All keys are prefixed with `happy_review_` to avoid collisions.
class SharedPreferencesStorageAdapter extends ReviewStorageAdapter {
  static const _prefix = 'happy_review_';

  @override
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$key') ?? defaultValue;
  }

  @override
  Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$key', value);
  }

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$key') ?? defaultValue;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', value);
  }

  @override
  Future<DateTime?> getDateTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('$_prefix$key');
    return millis != null
        ? DateTime.fromMillisecondsSinceEpoch(millis)
        : null;
  }

  @override
  Future<void> setDateTime(String key, DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$key', value.millisecondsSinceEpoch);
  }

  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$key');
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', value);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
