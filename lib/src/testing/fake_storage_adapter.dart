import '../adapters/review_storage_adapter.dart';

/// An in-memory [ReviewStorageAdapter] for testing.
///
/// Behaves like a real storage backend without any external dependencies.
///
/// ```dart
/// import 'package:happy_review/testing.dart';
///
/// final storage = FakeStorageAdapter();
/// await HappyReview.instance.configure(storageAdapter: storage, ...);
/// ```
class FakeStorageAdapter extends ReviewStorageAdapter {
  final Map<String, dynamic> _store = {};

  @override
  Future<int> getInt(String key, {int defaultValue = 0}) async =>
      (_store[key] as int?) ?? defaultValue;

  @override
  Future<void> setInt(String key, int value) async => _store[key] = value;

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async =>
      (_store[key] as bool?) ?? defaultValue;

  @override
  Future<void> setBool(String key, bool value) async => _store[key] = value;

  @override
  Future<DateTime?> getDateTime(String key) async =>
      _store[key] as DateTime?;

  @override
  Future<void> setDateTime(String key, DateTime value) async =>
      _store[key] = value;

  @override
  Future<String?> getString(String key) async => _store[key] as String?;

  @override
  Future<void> setString(String key, String value) async =>
      _store[key] = value;

  @override
  Future<void> clear() async => _store.clear();
}
