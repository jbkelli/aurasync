// AuraSync Widget Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aurasync/main.dart';

void main() {
  testWidgets('App launches and shows AuraSync title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AuraSyncApp()));

    // Wait for initial build
    await tester.pumpAndSettle();

    // Verify that AuraSync title appears
    expect(find.textContaining('AuraSync'), findsWidgets);
  });
}
