import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/services/contacts_access_service.dart';
import 'package:send_it/theme/app_theme.dart';
import 'package:send_it/widgets/group_form_screen.dart';

Contact _contact(String name, String phone) => Contact(
      displayName: name,
      phones: [Phone(phone)],
    );

void main() {
  final ada = _contact('Ada Lovelace', '555-0100');
  final grace = _contact('Grace Hopper', '555-0101');
  final contacts = [ada, grace];

  Future<List<(String, List<Contact>)>> pumpForm(
    WidgetTester tester, {
    String initialName = '',
    List<Contact> initialMembers = const [],
  }) async {
    final submissions = <(String, List<Contact>)>[];
    await tester.pumpWidget(CupertinoApp(
      theme: AppTheme.cupertino(brightness: Brightness.light),
      home: GroupFormScreen(
        title: 'New Group',
        submitLabel: 'Create',
        allContacts: contacts,
        initialName: initialName,
        initialMembers: initialMembers,
        onSubmit: (name, members) async {
          submissions.add((name, List.of(members)));
        },
      ),
    ));
    return submissions;
  }

  testWidgets('tapping a row toggles the member and the count', (tester) async {
    await pumpForm(tester);
    expect(find.text('0 contacts selected'), findsOneWidget);

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pump();
    expect(find.text('1 contact selected'), findsOneWidget);

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pump();
    expect(find.text('0 contacts selected'), findsOneWidget);
  });

  testWidgets('submit without a name shows a notice and does not submit',
      (tester) async {
    final submissions = await pumpForm(tester);
    await tester.tap(find.text('Ada Lovelace'));
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Name Your Group'), findsOneWidget);
    expect(submissions, isEmpty);
  });

  testWidgets('submit without members shows a notice and does not submit',
      (tester) async {
    final submissions = await pumpForm(tester, initialName: 'Book club');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Add Members'), findsOneWidget);
    expect(submissions, isEmpty);
  });

  testWidgets('submits the trimmed name and selected members', (tester) async {
    final submissions = await pumpForm(tester);
    await tester.enterText(find.byType(CupertinoTextField).first, '  Team  ');
    await tester.tap(find.text('Grace Hopper'));
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(submissions, hasLength(1));
    expect(submissions.single.$1, 'Team');
    expect(submissions.single.$2, [grace]);
  });

  testWidgets('edit starts from the existing name and members', (tester) async {
    await pumpForm(tester, initialName: 'Family', initialMembers: [ada]);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('1 contact selected'), findsOneWidget);
  });

  testWidgets('search narrows the list', (tester) async {
    await pumpForm(tester);
    await tester.enterText(find.byType(CupertinoSearchTextField), 'grace');
    await tester.pump();

    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsNothing);
  });

  group('contacts pre-prompt', () {
    Future<List<bool>> pumpWithAccess(
      WidgetTester tester,
      ContactsAccess access, {
      ContactsAccess grantsTo = ContactsAccess.granted,
    }) async {
      final requests = <bool>[];
      await tester.pumpWidget(CupertinoApp(
        theme: AppTheme.cupertino(brightness: Brightness.light),
        home: GroupFormScreen(
          title: 'New Group',
          submitLabel: 'Create',
          allContacts: const [],
          contactsAccess: access,
          loadContacts: ({required bool request}) async {
            requests.add(request);
            return (access: grantsTo, contacts: contacts);
          },
          onSubmit: (_, __) async {},
        ),
      ));
      return requests;
    }

    testWidgets('explains before asking, then shows contacts', (tester) async {
      final requests =
          await pumpWithAccess(tester, ContactsAccess.notDetermined);
      expect(find.text('Pick people from your contacts'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsNothing);
      expect(requests, isEmpty);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(requests, [true]);
      expect(find.text('Ada Lovelace'), findsOneWidget);
    });

    testWidgets('denied offers Settings instead of the prompt', (tester) async {
      await pumpWithAccess(tester, ContactsAccess.denied);
      expect(find.text('Contacts access is off'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('limited shows the shared contacts and a note', (tester) async {
      await tester.pumpWidget(CupertinoApp(
        theme: AppTheme.cupertino(brightness: Brightness.dark),
        home: GroupFormScreen(
          title: 'New Group',
          submitLabel: 'Create',
          allContacts: contacts,
          contactsAccess: ContactsAccess.limited,
          onSubmit: (_, __) async {},
        ),
      ));
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(
        find.text('Sent It can only see the contacts you shared.'),
        findsOneWidget,
      );
    });
  });
}
