import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/screens/group_message/composer.dart';
import 'package:send_it/services/shortcut_service.dart';
import 'package:send_it/theme/app_theme.dart';

void main() {
  final nick = Contact(displayName: 'Nick Fury', phones: [Phone('555-0100')]);
  final ada = Contact(displayName: 'Ada Lovelace', phones: [Phone('555-0101')]);

  Future<List<int>> pump(
    WidgetTester tester,
    String message,
    List<Contact> recipients,
  ) async {
    final inserts = <int>[];
    await tester.pumpWidget(CupertinoApp(
      theme: AppTheme.cupertino(brightness: Brightness.light),
      home: CupertinoPageScaffold(
        child: Center(
          child: PersonalizationBar(
            message: message,
            recipients: recipients,
            onInsertFirstName: () => inserts.add(1),
          ),
        ),
      ),
    ));
    return inserts;
  }

  testWidgets('previews the first recipient with the sent text',
      (tester) async {
    const message = 'Hey {firstname}! Free Friday?';
    await pump(tester, message, [nick, ada]);

    final sent = ShortcutService.personalizeMessage(message, nick);
    expect(find.textContaining('Nick will get: $sent'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(find.text('What each person gets'), findsOneWidget);
    expect(
      find.text(ShortcutService.personalizeMessage(message, ada)),
      findsOneWidget,
    );
  });

  testWidgets('without the token offers a one-tap first name chip',
      (tester) async {
    final inserts = await pump(tester, 'Hello all', [nick]);
    expect(find.textContaining('will get'), findsNothing);

    await tester.tap(find.text('First name'));
    expect(inserts, hasLength(1));
  });
}
