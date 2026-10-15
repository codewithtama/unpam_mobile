import 'package:flutter_test/flutter_test.dart';
import 'package:unpam_mobile/main.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UnpamMobileApp(initialLoggedIn: false));
    expect(find.text('UNPAM LMS MOBILE'), findsOneWidget);
  });
}
