import 'package:flutter_test/flutter_test.dart';

import 'package:happy_review/happy_review.dart';

void main() {
  test('HappyTrigger stores event name and minOccurrences', () {
    const trigger = HappyTrigger(
      eventName: 'purchase_completed',
      minOccurrences: 3,
    );
    expect(trigger.eventName, 'purchase_completed');
    expect(trigger.minOccurrences, 3);
  });
}
