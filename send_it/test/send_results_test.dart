import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/screens/group_message/send_results_sheet.dart';
import 'package:send_it/theme/app_theme.dart';

void main() {
  const summary = SendSummary([
    (name: 'Ada Lovelace', outcome: SendOutcome.sent),
    (name: 'Grace Hopper', outcome: SendOutcome.skipped),
    (name: 'Alan Turing', outcome: SendOutcome.sent),
    (name: 'Edsger Dijkstra', outcome: SendOutcome.failed),
  ]);

  test('counts each outcome', () {
    expect(summary.sentCount, 2);
    expect(summary.skippedCount, 1);
    expect(summary.failedCount, 1);
    expect(summary.headline, 'Sent to 2 people 🎉');
    expect(
      const SendSummary([(name: 'A', outcome: SendOutcome.sent)]).headline,
      'Sent to 1 person 🎉',
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets('sheet lists every recipient ($brightness, large text)',
        (tester) async {
      await tester.pumpWidget(CupertinoApp(
        theme: AppTheme.cupertino(brightness: brightness),
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(2),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SendResultsSheet(summary: summary, buttonLabel: 'Done'),
          ),
        ),
      ));

      expect(find.text('Sent to 2 people 🎉'), findsOneWidget);
      expect(find.text('Sent'), findsNWidgets(2));
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
