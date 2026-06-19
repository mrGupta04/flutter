import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_app/main.dart';

void main() {
  testWidgets('Admin app smoke', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AdminApp()));
    expect(find.text('1mg Admin'), findsNothing);
  });
}
