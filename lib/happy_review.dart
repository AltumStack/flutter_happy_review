/// A strategic in-app review library for Flutter.
///
/// Triggers review prompts at proven moments of user satisfaction,
/// not arbitrary launch counts.
library;

// Core
export 'src/happy_review_instance.dart';

// Models
export 'src/models/feedback_result.dart';
export 'src/models/happy_trigger.dart';
export 'src/models/platform_policy.dart';
export 'src/models/pre_dialog_result.dart';
export 'src/models/review_flow_result.dart';

// Adapters
export 'src/adapters/review_dialog_adapter.dart';
export 'src/adapters/default_review_dialog_adapter.dart';
export 'src/adapters/review_storage_adapter.dart';

// Conditions
export 'src/conditions/review_condition.dart';
export 'src/conditions/min_days_after_install.dart';
export 'src/conditions/cooldown_period.dart';
export 'src/conditions/max_prompts_shown.dart';
export 'src/conditions/custom_condition.dart';
