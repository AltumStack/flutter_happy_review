import 'package:flutter/widgets.dart';
import 'package:happy_review/happy_review.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mocktail/mocktail.dart';

// Re-export so existing test imports keep working.
export 'package:happy_review/testing.dart' show FakeStorageAdapter;

class MockStorageAdapter extends Mock implements ReviewStorageAdapter {}

class MockDialogAdapter extends Mock implements ReviewDialogAdapter {}

class MockBuildContext extends Mock implements BuildContext {}

class MockInAppReview extends Mock implements InAppReview {}
