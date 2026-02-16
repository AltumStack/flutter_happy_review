import 'dart:io' show Platform;

/// Platform-specific rules that guard review prompt frequency.
///
/// These rules act as a safety layer aligned with the OS-level
/// restrictions from Apple and Google.
class PlatformPolicy {
  final PlatformRules android;
  final PlatformRules ios;
  final PlatformRules macOS;

  const PlatformPolicy({
    this.android = const PlatformRules.androidDefaults(),
    this.ios = const PlatformRules.iosDefaults(),
    this.macOS = const PlatformRules.iosDefaults(),
  });

  /// Returns the rules for the current platform.
  PlatformRules get current {
    if (Platform.isIOS) return ios;
    if (Platform.isMacOS) return macOS;
    return android;
  }
}

/// Frequency rules for a single platform.
class PlatformRules {
  /// Minimum time between review prompts.
  final Duration cooldown;

  /// Maximum number of prompts allowed within [maxPromptsPeriod].
  final int maxPrompts;

  /// The rolling window in which [maxPrompts] is enforced.
  final Duration maxPromptsPeriod;

  const PlatformRules({
    required this.cooldown,
    required this.maxPrompts,
    required this.maxPromptsPeriod,
  });

  /// Conservative defaults for iOS.
  /// Apple limits to 3 prompts per 365 days.
  const PlatformRules.iosDefaults()
      : cooldown = const Duration(days: 120),
        maxPrompts = 3,
        maxPromptsPeriod = const Duration(days: 365);

  /// Defaults for Android.
  /// Google does not publish its quota, so we stay prudent.
  const PlatformRules.androidDefaults()
      : cooldown = const Duration(days: 60),
        maxPrompts = 3,
        maxPromptsPeriod = const Duration(days: 365);
}
