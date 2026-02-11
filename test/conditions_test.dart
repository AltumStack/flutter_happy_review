import 'package:flutter_test/flutter_test.dart';
import 'package:happy_review/happy_review.dart';

import 'mocks.dart';

void main() {
  late FakeStorageAdapter storage;

  setUp(() {
    storage = FakeStorageAdapter();
  });

  group('MinDaysAfterInstall', () {
    test(
      'Given no install date recorded, '
      'When evaluate is called, '
      'Then returns false',
      () async {
        // Given
        const condition = MinDaysAfterInstall(days: 7);

        // When
        final result = await condition.evaluate(storage);

        // Then
        expect(result, isFalse);
      },
    );

    test(
      'Given install date is 3 days ago and minimum is 7, '
      'When evaluate is called, '
      'Then returns false',
      () async {
        // Given
        const condition = MinDaysAfterInstall(days: 7);
        await storage.setDateTime(
          'install_date',
          DateTime.now().subtract(const Duration(days: 3)),
        );

        // When
        final result = await condition.evaluate(storage);

        // Then
        expect(result, isFalse);
      },
    );

    test(
      'Given install date is 10 days ago and minimum is 7, '
      'When evaluate is called, '
      'Then returns true',
      () async {
        // Given
        const condition = MinDaysAfterInstall(days: 7);
        await storage.setDateTime(
          'install_date',
          DateTime.now().subtract(const Duration(days: 10)),
        );

        // When
        final result = await condition.evaluate(storage);

        // Then
        expect(result, isTrue);
      },
    );

    test(
      'Given no install date exists, '
      'When recordInstallIfNeeded is called, '
      'Then records current date',
      () async {
        // Given
        expect(await storage.getDateTime('install_date'), isNull);

        // When
        await MinDaysAfterInstall.recordInstallIfNeeded(storage);

        // Then
        expect(await storage.getDateTime('install_date'), isNotNull);
      },
    );

    test(
      'Given install date already exists, '
      'When recordInstallIfNeeded is called, '
      'Then does not overwrite it',
      () async {
        // Given
        final originalDate =
            DateTime.now().subtract(const Duration(days: 30));
        await storage.setDateTime('install_date', originalDate);

        // When
        await MinDaysAfterInstall.recordInstallIfNeeded(storage);

        // Then
        final stored = await storage.getDateTime('install_date');
        expect(stored, equals(originalDate));
      },
    );
  });

  group('CooldownPeriod', () {
    test(
      'Given no previous prompt, '
      'When evaluate is called, '
      'Then returns true',
      () async {
        // Given
        const condition = CooldownPeriod(days: 90);

        // When
        final result = await condition.evaluate(storage);

        // Then
        expect(result, isTrue);
      },
    );

    test(
      'Given last prompt was 30 days ago and cooldown is 90, '
      'When evaluate is called, '
      'Then returns false',
      () async {
        // Given
        const condition = CooldownPeriod(days: 90);
        await storage.setDateTime(
          'last_prompt_date',
          DateTime.now().subtract(const Duration(days: 30)),
        );

        // When
        final result = await condition.evaluate(storage);

        // Then
        expect(result, isFalse);
      },
    );

    test(
      'Given last prompt was 100 days ago and cooldown is 90, '
      'When evaluate is called, '
      'Then returns true',
      () async {
        // Given
        const condition = CooldownPeriod(days: 90);
        await storage.setDateTime(
          'last_prompt_date',
          DateTime.now().subtract(const Duration(days: 100)),
        );

        // When
        final result = await condition.evaluate(storage);

        // Then
        expect(result, isTrue);
      },
    );

    test(
      'Given recordPrompt is called, '
      'When reading last_prompt_date, '
      'Then returns a recent date',
      () async {
        // Given / When
        await CooldownPeriod.recordPrompt(storage);

        // Then
        final stored = await storage.getDateTime('last_prompt_date');
        expect(stored, isNotNull);
        expect(
          DateTime.now().difference(stored!).inSeconds,
          lessThan(2),
        );
      },
    );
  });

  group('MaxPromptsShown', () {
    test(
      'Given no prompts shown and max is 3, '
      'When evaluate is called, '
      'Then returns true',
      () async {
        // Given
        const condition = MaxPromptsShown(maxPrompts: 3);

        // When
        final result = await condition.evaluate(storage);

        // Then
        expect(result, isTrue);
      },
    );

    test(
      'Given 2 prompts shown and max is 3, '
      'When evaluate is called, '
      'Then returns true',
      () async {
        // Given
        const condition = MaxPromptsShown(maxPrompts: 3);
        await storage.setInt('prompts_shown_count', 2);

        // When
        final result = await condition.evaluate(storage);

        // Then
        expect(result, isTrue);
      },
    );

    test(
      'Given 3 prompts shown and max is 3, '
      'When evaluate is called, '
      'Then returns false',
      () async {
        // Given
        const condition = MaxPromptsShown(maxPrompts: 3);
        await storage.setInt('prompts_shown_count', 3);

        // When
        final result = await condition.evaluate(storage);

        // Then
        expect(result, isFalse);
      },
    );

    test(
      'Given incrementCount is called, '
      'When reading prompts_shown_count, '
      'Then count increases by 1',
      () async {
        // Given
        await storage.setInt('prompts_shown_count', 5);

        // When
        await MaxPromptsShown.incrementCount(storage);

        // Then
        final count = await storage.getInt('prompts_shown_count');
        expect(count, equals(6));
      },
    );
  });

  group('CustomCondition', () {
    test(
      'Given callback returns true, '
      'When evaluate is called, '
      'Then returns true',
      () async {
        // Given
        final condition = CustomCondition(
          name: 'always_true',
          evaluate: () async => true,
        );

        // When
        final result = await condition.evaluate(storage);

        // Then
        expect(result, isTrue);
      },
    );

    test(
      'Given callback returns false, '
      'When evaluate is called, '
      'Then returns false',
      () async {
        // Given
        final condition = CustomCondition(
          name: 'always_false',
          evaluate: () async => false,
        );

        // When
        final result = await condition.evaluate(storage);

        // Then
        expect(result, isFalse);
      },
    );
  });
}
