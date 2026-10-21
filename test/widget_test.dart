import 'package:flutter_test/flutter_test.dart';

import 'package:new_project/main.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const CrmMobileApp());

    expect(find.text('Sign In'), findsAtLeastNWidgets(1));
    expect(find.text('INTERIOR CONCEPTS STUDIO'), findsOneWidget);
  });
}
