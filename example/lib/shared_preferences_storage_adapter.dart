import 'package:happy_review/happy_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Example [ReviewStorageAdapter] backed by SharedPreferences.
///
/// All keys are prefixed with `happy_review_` to avoid collisions.
///
/// Usage:
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// final storage = SharedPreferencesStorageAdapter(prefs);
/// ```
class SharedPreferencesStorageAdapter extends ReviewStorageAdapter {
  SharedPreferencesStorageAdapter(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'happy_review_';

  @override
  Future<int> getInt(String key, {int defaultValue = 0}) async =>
      _prefs.getInt('$_prefix$key') ?? defaultValue;

  @override
  Future<void> setInt(String key, int value) async =>
      _prefs.setInt('$_prefix$key', value);

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async =>
      _prefs.getBool('$_prefix$key') ?? defaultValue;

  @override
  Future<void> setBool(String key, bool value) async =>
      _prefs.setBool('$_prefix$key', value);

  @override
  Future<DateTime?> getDateTime(String key) async {
    final millis = _prefs.getInt('$_prefix$key');
    return millis != null
        ? DateTime.fromMillisecondsSinceEpoch(millis)
        : null;
  }

  @override
  Future<void> setDateTime(String key, DateTime value) async =>
      _prefs.setInt('$_prefix$key', value.millisecondsSinceEpoch);

  @override
  Future<String?> getString(String key) async =>
      _prefs.getString('$_prefix$key');

  @override
  Future<void> setString(String key, String value) async =>
      _prefs.setString('$_prefix$key', value);

  @override
  Future<void> clear() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
