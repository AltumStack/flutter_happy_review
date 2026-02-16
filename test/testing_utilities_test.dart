import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_review/happy_review.dart';
import 'package:happy_review/testing.dart';

void main() {
  group('FakeStorageAdapter', () {
    late FakeStorageAdapter storage;

    setUp(() {
      storage = FakeStorageAdapter();
    });

    test('getInt returns defaultValue when key does not exist', () async {
      expect(await storage.getInt('missing'), equals(0));
      expect(await storage.getInt('missing', defaultValue: 42), equals(42));
    });

    test('setInt and getInt round-trip', () async {
      await storage.setInt('count', 5);
      expect(await storage.getInt('count'), equals(5));
    });

    test('getBool returns defaultValue when key does not exist', () async {
      expect(await storage.getBool('missing'), isFalse);
      expect(await storage.getBool('missing', defaultValue: true), isTrue);
    });

    test('setBool and getBool round-trip', () async {
      await storage.setBool('flag', true);
      expect(await storage.getBool('flag'), isTrue);
    });

    test('getDateTime returns null when key does not exist', () async {
      expect(await storage.getDateTime('missing'), isNull);
    });

    test('setDateTime and getDateTime round-trip', () async {
      final now = DateTime.now();
      await storage.setDateTime('date', now);
      expect(await storage.getDateTime('date'), equals(now));
    });

    test('getString returns null when key does not exist', () async {
      expect(await storage.getString('missing'), isNull);
    });

    test('setString and getString round-trip', () async {
      await storage.setString('name', 'hello');
      expect(await storage.getString('name'), equals('hello'));
    });

    test('clear removes all stored data', () async {
      await storage.setInt('a', 1);
      await storage.setString('b', 'two');
      await storage.clear();

      expect(await storage.getInt('a'), equals(0));
      expect(await storage.getString('b'), isNull);
    });
  });

  group('FakeDialogAdapter', () {
    testWidgets('defaults to PreDialogResult.positive', (tester) async {
      final adapter = FakeDialogAdapter();

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final context = tester.element(find.byType(Scaffold));

      final result = await adapter.showPreDialog(context);
      expect(result, equals(PreDialogResult.positive));
    });

    testWidgets('returns configured preDialogResult', (tester) async {
      final adapter = FakeDialogAdapter(
        preDialogResult: PreDialogResult.negative,
      );

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final context = tester.element(find.byType(Scaffold));

      final result = await adapter.showPreDialog(context);
      expect(result, equals(PreDialogResult.negative));
    });

    testWidgets('returns configured remindLater', (tester) async {
      final adapter = FakeDialogAdapter(
        preDialogResult: PreDialogResult.remindLater,
      );

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final context = tester.element(find.byType(Scaffold));

      final result = await adapter.showPreDialog(context);
      expect(result, equals(PreDialogResult.remindLater));
    });

    testWidgets('showFeedbackDialog returns null by default', (tester) async {
      final adapter = FakeDialogAdapter();

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final context = tester.element(find.byType(Scaffold));

      final result = await adapter.showFeedbackDialog(context);
      expect(result, isNull);
    });

    testWidgets('showFeedbackDialog returns configured result',
        (tester) async {
      const feedback = FeedbackResult(
        comment: 'Too slow',
        category: 'Performance',
      );
      final adapter = FakeDialogAdapter(
        preDialogResult: PreDialogResult.negative,
        feedbackResult: feedback,
      );

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final context = tester.element(find.byType(Scaffold));

      final result = await adapter.showFeedbackDialog(context);
      expect(result, isNotNull);
      expect(result!.comment, equals('Too slow'));
      expect(result.category, equals('Performance'));
    });
  });
}
