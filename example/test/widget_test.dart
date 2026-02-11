import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('App renders shop page', (WidgetTester tester) async {
    await tester.pumpWidget(const HappyShopApp());
    expect(find.text('Happy Shop'), findsOneWidget);
    expect(find.text('Complete a Purchase'), findsOneWidget);
  });
}
