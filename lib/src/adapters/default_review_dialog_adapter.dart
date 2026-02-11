import 'package:flutter/material.dart';

import '../models/feedback_result.dart';
import '../models/pre_dialog_result.dart';
import 'review_dialog_adapter.dart';

/// Configuration for the default pre-dialog appearance.
class DefaultPreDialogConfig {
  final String title;
  final String positiveLabel;
  final String negativeLabel;
  final bool dismissible;

  const DefaultPreDialogConfig({
    this.title = 'Are you enjoying the app?',
    this.positiveLabel = 'Yes!',
    this.negativeLabel = 'Not really',
    this.dismissible = true,
  });
}

/// Configuration for the default feedback dialog appearance.
class DefaultFeedbackDialogConfig {
  final String title;
  final String hint;
  final String submitLabel;
  final String cancelLabel;
  final String thankYouMessage;
  final List<String> categories;
  final bool showContactOption;
  final String contactLabel;
  final String contactHint;

  const DefaultFeedbackDialogConfig({
    this.title = 'What could we improve?',
    this.hint = 'Tell us about your experience...',
    this.submitLabel = 'Submit',
    this.cancelLabel = 'Cancel',
    this.thankYouMessage = 'Thanks for your feedback!',
    this.categories = const [],
    this.showContactOption = false,
    this.contactLabel = 'Want us to follow up?',
    this.contactHint = 'Your email (optional)',
  });
}

/// A ready-to-use [ReviewDialogAdapter] with sensible defaults.
///
/// Uses Material Design dialogs. Customize text and behavior through
/// [DefaultPreDialogConfig] and [DefaultFeedbackDialogConfig], or
/// implement [ReviewDialogAdapter] directly for full control.
class DefaultReviewDialogAdapter extends ReviewDialogAdapter {
  final DefaultPreDialogConfig preDialogConfig;
  final DefaultFeedbackDialogConfig feedbackConfig;

  DefaultReviewDialogAdapter({
    this.preDialogConfig = const DefaultPreDialogConfig(),
    this.feedbackConfig = const DefaultFeedbackDialogConfig(),
  });

  @override
  Future<PreDialogResult> showPreDialog(BuildContext context) async {
    final result = await showDialog<PreDialogResult>(
      context: context,
      barrierDismissible: preDialogConfig.dismissible,
      builder: (_) => _PreDialog(config: preDialogConfig),
    );
    return result ?? PreDialogResult.dismissed;
  }

  @override
  Future<FeedbackResult?> showFeedbackDialog(BuildContext context) async {
    final result = await showDialog<FeedbackResult>(
      context: context,
      builder: (_) => _FeedbackDialog(config: feedbackConfig),
    );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedbackConfig.thankYouMessage)),
      );
    }

    return result;
  }
}

class _PreDialog extends StatelessWidget {
  final DefaultPreDialogConfig config;

  const _PreDialog({required this.config});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(config.title),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(PreDialogResult.negative),
          child: Text(config.negativeLabel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(PreDialogResult.positive),
          child: Text(config.positiveLabel),
        ),
      ],
    );
  }
}

class _FeedbackDialog extends StatefulWidget {
  final DefaultFeedbackDialogConfig config;

  const _FeedbackDialog({required this.config});

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final _commentController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedCategory;

  DefaultFeedbackDialogConfig get config => widget.config;

  @override
  void dispose() {
    _commentController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(config.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (config.categories.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                children: config.categories.map((category) {
                  final selected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        _selectedCategory = value ? category : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: config.hint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (config.showContactOption) ...[
              const SizedBox(height: 12),
              Text(
                config.contactLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: config.contactHint,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(config.cancelLabel),
        ),
        FilledButton(
          onPressed: () {
            final result = FeedbackResult(
              comment: _commentController.text.isNotEmpty
                  ? _commentController.text
                  : null,
              category: _selectedCategory,
              contactEmail: _emailController.text.isNotEmpty
                  ? _emailController.text
                  : null,
            );
            Navigator.of(context).pop(result);
          },
          child: Text(config.submitLabel),
        ),
      ],
    );
  }
}
