import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_review/happy_review.dart';
import 'package:happy_review/src/platform_policy_checker.dart';

import 'mocks.dart';

void main() {
  late FakeStorageAdapter storage;

  const rules = PlatformRules(
    cooldown: Duration(days: 60),
    maxPrompts: 3,
    maxPromptsPeriod: Duration(days: 365),
  );

  setUp(() {
    storage = FakeStorageAdapter();
  });

  group('PlatformPolicyChecker - cooldown', () {
    test(
      'Given no previous prompt recorded, '
      'When canShow is called, '
      'Then returns true',
      () async {
        // Given
        final checker = PlatformPolicyChecker(
          rules: rules,
          storage: storage,
        );

        // When
        final result = await checker.canShow();

        // Then
        expect(result, isTrue);
      },
    );

    test(
      'Given last prompt was 10 days ago and cooldown is 60 days, '
      'When canShow is called, '
      'Then returns false',
      () async {
        // Given
        await storage.setDateTime(
          'platform_last_prompt',
          DateTime.now().subtract(const Duration(days: 10)),
        );
        final checker = PlatformPolicyChecker(
          rules: rules,
          storage: storage,
        );

        // When
        final result = await checker.canShow();

        // Then
        expect(result, isFalse);
      },
    );

    test(
      'Given last prompt was 90 days ago and cooldown is 60 days, '
      'When canShow is called, '
      'Then returns true',
      () async {
        // Given
        await storage.setDateTime(
          'platform_last_prompt',
          DateTime.now().subtract(const Duration(days: 90)),
        );
        final checker = PlatformPolicyChecker(
          rules: rules,
          storage: storage,
        );

        // When
        final result = await checker.canShow();

        // Then
        expect(result, isTrue);
      },
    );
  });

  group('PlatformPolicyChecker - maxPrompts', () {
    test(
      'Given no prompt timestamps recorded, '
      'When canShow is called, '
      'Then returns true',
      () async {
        // Given
        final checker = PlatformPolicyChecker(
          rules: rules,
          storage: storage,
        );

        // When
        final result = await checker.canShow();

        // Then
        expect(result, isTrue);
      },
    );

    test(
      'Given 2 prompts within period and max is 3, '
      'When canShow is called, '
      'Then returns true',
      () async {
        // Given
        final now = DateTime.now();
        final timestamps = [
          now.subtract(const Duration(days: 200)).millisecondsSinceEpoch,
          now.subtract(const Duration(days: 100)).millisecondsSinceEpoch,
        ].join(',');
        await storage.setString('platform_prompt_timestamps', timestamps);
        // Also need to set cooldown far enough.
        await storage.setDateTime(
          'platform_last_prompt',
          now.subtract(const Duration(days: 100)),
        );

        final checker = PlatformPolicyChecker(
          rules: rules,
          storage: storage,
        );

        // When
        final result = await checker.canShow();

        // Then
        expect(result, isTrue);
      },
    );

    test(
      'Given 3 prompts within period and max is 3, '
      'When canShow is called, '
      'Then returns false',
      () async {
        // Given
        final now = DateTime.now();
        final timestamps = [
          now.subtract(const Duration(days: 300)).millisecondsSinceEpoch,
          now.subtract(const Duration(days: 200)).millisecondsSinceEpoch,
          now.subtract(const Duration(days: 100)).millisecondsSinceEpoch,
        ].join(',');
        await storage.setString('platform_prompt_timestamps', timestamps);
        await storage.setDateTime(
          'platform_last_prompt',
          now.subtract(const Duration(days: 100)),
        );

        final checker = PlatformPolicyChecker(
          rules: rules,
          storage: storage,
        );

        // When
        final result = await checker.canShow();

        // Then
        expect(result, isFalse);
      },
    );

    test(
      'Given 3 prompts but all outside the period window, '
      'When canShow is called, '
      'Then returns true',
      () async {
        // Given
        final now = DateTime.now();
        final timestamps = [
          now.subtract(const Duration(days: 400)).millisecondsSinceEpoch,
          now.subtract(const Duration(days: 380)).millisecondsSinceEpoch,
          now.subtract(const Duration(days: 370)).millisecondsSinceEpoch,
        ].join(',');
        await storage.setString('platform_prompt_timestamps', timestamps);
        await storage.setDateTime(
          'platform_last_prompt',
          now.subtract(const Duration(days: 370)),
        );

        final checker = PlatformPolicyChecker(
          rules: rules,
          storage: storage,
        );

        // When
        final result = await checker.canShow();

        // Then
        expect(result, isTrue);
      },
    );
  });

  group('PlatformPolicy', () {
    test(
      'Given default PlatformPolicy, '
      'When accessing macOS rules, '
      'Then returns iOS defaults (Apple platform)',
      () {
        const policy = PlatformPolicy();
        final macRules = policy.macOS;
        final iosRules = policy.ios;

        expect(macRules.cooldown, equals(iosRules.cooldown));
        expect(macRules.maxPrompts, equals(iosRules.maxPrompts));
        expect(macRules.maxPromptsPeriod, equals(iosRules.maxPromptsPeriod));
      },
    );

    test(
      'Given custom macOS rules, '
      'When creating PlatformPolicy, '
      'Then macOS uses the custom rules',
      () {
        const customRules = PlatformRules(
          cooldown: Duration(days: 30),
          maxPrompts: 5,
          maxPromptsPeriod: Duration(days: 180),
        );
        const policy = PlatformPolicy(macOS: customRules);

        expect(policy.macOS.cooldown, equals(const Duration(days: 30)));
        expect(policy.macOS.maxPrompts, equals(5));
        expect(
            policy.macOS.maxPromptsPeriod, equals(const Duration(days: 180)));
      },
    );

    test(
      'Given running on macOS, '
      'When accessing current, '
      'Then returns macOS rules',
      () {
        const macRules = PlatformRules(
          cooldown: Duration(days: 45),
          maxPrompts: 7,
          maxPromptsPeriod: Duration(days: 200),
        );
        const policy = PlatformPolicy(macOS: macRules);

        if (Platform.isMacOS) {
          expect(policy.current.cooldown, equals(const Duration(days: 45)));
          expect(policy.current.maxPrompts, equals(7));
        }
      },
    );
  });

  group('PlatformPolicyChecker - recordPrompt', () {
    test(
      'Given no previous records, '
      'When recordPrompt is called, '
      'Then stores the timestamp and last prompt date',
      () async {
        // Given
        final checker = PlatformPolicyChecker(
          rules: rules,
          storage: storage,
        );

        // When
        await checker.recordPrompt();

        // Then
        final lastPrompt =
            await storage.getDateTime('platform_last_prompt');
        expect(lastPrompt, isNotNull);

        final raw =
            await storage.getString('platform_prompt_timestamps');
        expect(raw, isNotNull);
        expect(raw!.split(',').length, equals(1));
      },
    );

    test(
      'Given one existing record, '
      'When recordPrompt is called again, '
      'Then appends to the timestamp list',
      () async {
        // Given
        final checker = PlatformPolicyChecker(
          rules: rules,
          storage: storage,
        );
        await checker.recordPrompt();

        // When
        await checker.recordPrompt();

        // Then
        final raw =
            await storage.getString('platform_prompt_timestamps');
        expect(raw!.split(',').length, equals(2));
      },
    );
  });
}
