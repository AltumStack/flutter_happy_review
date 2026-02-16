import 'package:flutter/material.dart';
import 'package:happy_review/happy_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_storage_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  await HappyReview.instance.configure(
    storageAdapter: SharedPreferencesStorageAdapter(prefs),
    triggers: [
      // Trigger after 3 successful purchases.
      const HappyTrigger(eventName: 'purchase_completed', minOccurrences: 3),
    ],
    prerequisites: [
      // User must have completed onboarding before any trigger fires.
      const HappyTrigger(eventName: 'onboarding_finished', minOccurrences: 1),
    ],
    conditions: [
      const MinDaysAfterInstall(days: 0), // Set to 0 for demo purposes.
    ],
    platformPolicy: const PlatformPolicy(
      // Relaxed for demo — in production use defaults or stricter values.
      android: PlatformRules(
        cooldown: Duration(seconds: 10),
        maxPrompts: 99,
        maxPromptsPeriod: Duration(days: 365),
      ),
      ios: PlatformRules(
        cooldown: Duration(seconds: 10),
        maxPrompts: 99,
        maxPromptsPeriod: Duration(days: 365),
      ),
      macOS: PlatformRules(
        cooldown: Duration(seconds: 10),
        maxPrompts: 99,
        maxPromptsPeriod: Duration(days: 365),
      ),
    ),
    dialogAdapter: DefaultReviewDialogAdapter(
      preDialogConfig: const DefaultPreDialogConfig(
        title: 'Enjoying Happy Shop?',
        positiveLabel: 'Love it!',
        negativeLabel: 'Not really',
        remindLaterLabel: 'Maybe later',
      ),
      feedbackConfig: const DefaultFeedbackDialogConfig(
        title: 'What could we improve?',
        hint: 'Tell us about your experience...',
        categories: ['Performance', 'Design', 'Features', 'Other'],
        showContactOption: true,
        thankYouMessage: 'Thanks! Your feedback helps us improve.',
      ),
    ),
    debugMode: true,
    onPreDialogShown: () => debugPrint('[HappyReview] Pre-dialog shown'),
    onPreDialogPositive: () => debugPrint('[HappyReview] User is happy!'),
    onPreDialogNegative: () => debugPrint('[HappyReview] User is not happy'),
    onPreDialogRemindLater: () => debugPrint('[HappyReview] Remind later'),
    onPreDialogDismissed: () => debugPrint('[HappyReview] Dialog dismissed'),
    onReviewRequested: () => debugPrint('[HappyReview] OS review requested'),
    onFeedbackSubmitted: (feedback) =>
        debugPrint('[HappyReview] Feedback: $feedback'),
  );

  runApp(const HappyShopApp());
}

class HappyShopApp extends StatelessWidget {
  const HappyShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Happy Shop Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ShopPage(),
    );
  }
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final _debugPanelKey = GlobalKey<State>();
  String _lastResult = 'No events logged yet.';
  bool _onboarded = false;
  int _purchaseCount = 0;

  /// Forces the debug panel to rebuild and refresh its snapshot.
  void _refreshDebugPanel() {
    // Trigger a rebuild so the panel re-fetches the snapshot.
    setState(() {});
  }

  Future<void> _completeOnboarding() async {
    final result = await HappyReview.instance.logEvent(
      context,
      'onboarding_finished',
    );
    setState(() {
      _onboarded = true;
      _lastResult = 'Onboarding → $result';
    });
    _refreshDebugPanel();
  }

  Future<void> _simulatePurchase() async {
    setState(() => _purchaseCount++);

    final result = await HappyReview.instance.logEvent(
      context,
      'purchase_completed',
    );

    if (mounted) {
      setState(() => _lastResult = 'Purchase #$_purchaseCount → $result');
      _refreshDebugPanel();
    }
  }

  void _toggleEnabled() {
    final newValue = !HappyReview.instance.isEnabled;
    HappyReview.instance.setEnabled(newValue);
    setState(() {
      _lastResult = 'Library ${newValue ? 'enabled' : 'disabled'} (kill switch)';
    });
    _refreshDebugPanel();
  }

  Future<void> _resetState() async {
    await HappyReview.instance.reset();
    setState(() {
      _purchaseCount = 0;
      _onboarded = false;
      _lastResult = 'State reset. Start over!';
    });
    _refreshDebugPanel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Happy Shop'),
        actions: [
          IconButton(
            icon: Icon(
              HappyReview.instance.isEnabled
                  ? Icons.toggle_on
                  : Icons.toggle_off,
            ),
            tooltip: 'Toggle kill switch',
            onPressed: _toggleEnabled,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset state',
            onPressed: _resetState,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.shopping_bag, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Purchases: $_purchaseCount',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Onboarded: ${_onboarded ? "Yes" : "No"}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prerequisite: onboarding. Trigger: 3 purchases.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _onboarded ? null : _completeOnboarding,
              child: Text(
                _onboarded
                    ? 'Onboarding completed'
                    : 'Complete Onboarding (prerequisite)',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _simulatePurchase,
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete a Purchase'),
            ),
            const SizedBox(height: 32),
            Text('Last result:', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastResult,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 24),
            HappyReviewDebugPanel(key: _debugPanelKey),
          ],
        ),
      ),
    );
  }
}
