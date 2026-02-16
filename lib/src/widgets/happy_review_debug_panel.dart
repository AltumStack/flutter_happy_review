import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../happy_review_instance.dart';
import '../models/debug_snapshot.dart';

/// A debug panel widget that displays the internal state of Happy Review.
///
/// Embed this in a debug screen or overlay during development to
/// inspect triggers, prerequisites, conditions, and platform policy
/// at a glance.
///
/// Only renders content in debug mode ([kDebugMode]). In release builds,
/// it renders an empty [SizedBox].
///
/// ```dart
/// // Add to any screen during development:
/// const HappyReviewDebugPanel()
/// ```
class HappyReviewDebugPanel extends StatefulWidget {
  const HappyReviewDebugPanel({super.key});

  @override
  State<HappyReviewDebugPanel> createState() => _HappyReviewDebugPanelState();
}

class _HappyReviewDebugPanelState extends State<HappyReviewDebugPanel> {
  DebugSnapshot? _snapshot;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final snapshot = await HappyReview.instance.getDebugSnapshot();
    if (mounted) {
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    if (_loading || _snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final snapshot = _snapshot!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Happy Review Debug',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _refresh,
                  tooltip: 'Refresh',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(),
            _buildRow(
              'Enabled',
              snapshot.enabled ? 'Yes' : 'No',
              snapshot.enabled ? Colors.green : Colors.red,
            ),
            _buildRow(
              'Debug mode',
              snapshot.debugMode ? 'On' : 'Off',
            ),
            _buildRow(
              'Dialog adapter',
              snapshot.hasDialogAdapter ? 'Configured' : 'None (direct review)',
            ),
            _buildRow(
              'Prompts shown',
              '${snapshot.promptsShown}',
            ),
            _buildRow(
              'Last prompt',
              snapshot.lastPromptDate?.toLocal().toString() ?? 'Never',
            ),
            _buildRow(
              'Install date',
              snapshot.installDate?.toLocal().toString() ?? 'Not recorded',
            ),
            if (snapshot.triggers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Triggers (OR)', style: theme.textTheme.labelLarge),
              for (final t in snapshot.triggers)
                _buildRow(
                  t.eventName,
                  '${t.currentCount}/${t.minOccurrences}',
                  t.isMet ? Colors.green : null,
                ),
            ],
            if (snapshot.prerequisites.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Prerequisites (AND)', style: theme.textTheme.labelLarge),
              for (final p in snapshot.prerequisites)
                _buildRow(
                  p.eventName,
                  '${p.currentCount}/${p.minOccurrences}',
                  p.isMet ? Colors.green : Colors.orange,
                ),
            ],
            const SizedBox(height: 8),
            _buildRow(
              'Platform policy',
              snapshot.platformPolicyAllows ? 'Allows' : 'Blocked',
              snapshot.platformPolicyAllows ? Colors.green : Colors.red,
            ),
            if (snapshot.conditions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Conditions', style: theme.textTheme.labelLarge),
              for (final c in snapshot.conditions)
                _buildRow(
                  c.name,
                  c.isMet ? 'Pass' : 'Fail',
                  c.isMet ? Colors.green : Colors.red,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
