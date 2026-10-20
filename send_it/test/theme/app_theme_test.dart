import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/theme/app_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('nav bar push transition is clean (${brightness.name})',
        (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(CupertinoApp(
        navigatorKey: navigator,
        theme: AppTheme.cupertino(brightness: brightness),
        home: const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(middle: Text('Sent It')),
          child: SizedBox(),
        ),
      ));

      navigator.currentState!.push(CupertinoPageRoute<void>(
        builder: (_) => const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(middle: Text('More')),
          child: SizedBox(),
        ),
      ));
      // Pump mid-transition, where the title lerps into the back label.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('More'), findsOneWidget);
    });
  }
}
