import 'package:flutter/material.dart';
import 'package:happy_review/happy_review.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HappyReview.instance.configure(
    triggers: [
      // Trigger after 3 successful purchases.
      const HappyTrigger(eventName: 'purchase_completed', minOccurrences: 3),
      // Trigger after completing onboarding.
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
    ),
    dialogAdapter: DefaultReviewDialogAdapter(
      preDialogConfig: const DefaultPreDialogConfig(
        title: 'Enjoying Happy Shop?',
        positiveLabel: 'Love it!',
        negativeLabel: 'Not really',
      ),
      feedbackConfig: const DefaultFeedbackDialogConfig(
        title: 'What could we improve?',
        hint: 'Tell us about your experience...',
        categories: ['Performance', 'Design', 'Features', 'Other'],
        showContactOption: true,
        thankYouMessage: 'Thanks! Your feedback helps us improve.',
      ),
    ),
    onPreDialogShown: () => debugPrint('[HappyReview] Pre-dialog shown'),
    onPreDialogPositive: () => debugPrint('[HappyReview] User is happy!'),
    onPreDialogNegative: () => debugPrint('[HappyReview] User is not happy'),
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
  int _purchaseCount = 0;
  String _lastResult = 'No events logged yet.';

  Future<void> _simulatePurchase() async {
    setState(() => _purchaseCount++);

    // Log the happy event — the library handles the rest.
    final result = await HappyReview.instance.logEvent(
      context,
      'purchase_completed',
    );

    if (mounted) {
      setState(() => _lastResult = 'Purchase #$_purchaseCount → $result');
    }
  }

  Future<void> _resetState() async {
    await HappyReview.instance.reset();
    setState(() {
      _purchaseCount = 0;
      _lastResult = 'State reset. Start over!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Happy Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset state',
            onPressed: _resetState,
          ),
        ],
      ),
      body: Padding(
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
                      'Purchases completed: $_purchaseCount',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The review flow triggers after 3 purchases.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _simulatePurchase,
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete a Purchase'),
            ),
            const SizedBox(height: 32),
            Text(
              'Last result:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lastResult,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
