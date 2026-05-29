import 'package:flutter_test/flutter_test.dart';
import 'package:trueschoolapp/app/app.dart';

void main() {
  testWidgets('App renders role selection page', (WidgetTester tester) async {
    await tester.pumpWidget(const TrueSchoolApp(isLoggedIn: false));

    expect(find.text('TrueSchoolAI'), findsOneWidget);
    expect(find.text('Smart School Management'), findsOneWidget);
  });
}
