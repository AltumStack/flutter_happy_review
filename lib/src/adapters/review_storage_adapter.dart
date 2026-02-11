/// Contract for persisting the library's internal state.
///
/// Implement this to use your own storage backend (Hive,
/// flutter_secure_storage, SQLite, etc.).
///
/// The library provides [SharedPreferencesStorageAdapter] as a
/// default implementation.
abstract class ReviewStorageAdapter {
  /// Reads an integer value.
  Future<int> getInt(String key, {int defaultValue = 0});

  /// Writes an integer value.
  Future<void> setInt(String key, int value);

  /// Reads a boolean value.
  Future<bool> getBool(String key, {bool defaultValue = false});

  /// Writes a boolean value.
  Future<void> setBool(String key, bool value);

  /// Reads a DateTime value. Returns `null` if not set.
  Future<DateTime?> getDateTime(String key);

  /// Writes a DateTime value.
  Future<void> setDateTime(String key, DateTime value);

  /// Reads a string value. Returns `null` if not set.
  Future<String?> getString(String key);

  /// Writes a string value.
  Future<void> setString(String key, String value);

  /// Removes all data written by the library.
  Future<void> clear();
}
