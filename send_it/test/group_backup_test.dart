import 'dart:convert';

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/models/message_group.dart';
import 'package:send_it/services/group_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Contact _contact(String id, String name, String phone) => Contact(
      id: id,
      displayName: name,
      phones: [Phone(phone)],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MessageGroup members', () {
    test('match by phone number when contact IDs differ', () {
      final oldPhone = [_contact('a1', 'Ana', '+1 (555) 123-4567')];
      final json = MessageGroup(
        id: 'g1',
        name: 'Family',
        members: oldPhone,
        createdAt: DateTime(2026),
      ).toJson();

      final newPhone = [_contact('z9', 'Ana R', '555-123-4567')];
      final group = MessageGroup.fromJson(json, newPhone);

      expect(group.members.map((c) => c.id), ['z9']);
      expect(group.unmatched, isEmpty);
    });

    test('unmatched members survive a save', () {
      final json = MessageGroup(
        id: 'g1',
        name: 'Family',
        members: [_contact('a1', 'Ana', '5551234567')],
        createdAt: DateTime(2026),
      ).toJson();

      final noContacts = MessageGroup.fromJson(json, const []);
      expect(noContacts.members, isEmpty);

      final resaved = MessageGroup.fromJson(
        noContacts.toJson(),
        [_contact('b2', 'Ana', '5551234567')],
      );
      expect(resaved.members.map((c) => c.id), ['b2']);
    });

    test('groups saved before snapshots still load by ID', () {
      final group = MessageGroup.fromJson({
        'id': 'g1',
        'name': 'Old',
        'memberIds': ['a1'],
        'createdAt': DateTime(2026).toIso8601String(),
      }, [_contact('a1', 'Ana', '5551234567')]);

      expect(group.members.map((c) => c.id), ['a1']);
    });
  });

  group('GroupStorage backup', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      GroupStorage.setContacts(const []);
    });

    test('export then import on a new phone restores the groups', () async {
      GroupStorage.setContacts([_contact('a1', 'Ana', '5551234567')]);
      await GroupStorage.addGroup(MessageGroup(
        id: 'g1',
        name: 'Family',
        members: [_contact('a1', 'Ana', '5551234567')],
        createdAt: DateTime(2026),
      ));
      final backup = await GroupStorage.exportBackup();

      // New phone: empty store, different contact IDs.
      SharedPreferences.setMockInitialValues({});
      final newContacts = [_contact('z9', 'Ana', '+15551234567')];
      GroupStorage.setContacts(newContacts);
      final result = await GroupStorage.importBackup(backup);

      expect(result.added, 1);
      expect(result.unmatchedMembers, 0);
      final groups = await GroupStorage.loadGroups(newContacts);
      expect(groups.single.name, 'Family');
      expect(groups.single.members.single.id, 'z9');
    });

    test('importing the same file twice adds nothing the second time',
        () async {
      final backup = jsonEncode({
        'format': 'sent-it-groups',
        'version': 1,
        'groups': [
          MessageGroup(
            id: 'g1',
            name: 'Team',
            members: [_contact('a1', 'Ana', '5551234567')],
            createdAt: DateTime(2026),
          ).toJson(),
        ],
      });

      final first = await GroupStorage.importBackup(backup);
      final second = await GroupStorage.importBackup(backup);

      expect(first.added, 1);
      expect(first.unmatchedMembers, 1);
      expect(second.added, 0);
      expect(second.skipped, 1);
      expect(await GroupStorage.loadGroups(const []), hasLength(1));
    });

    test('rejects a file that is not a backup', () async {
      expect(
        () => GroupStorage.importBackup('{"hello": "world"}'),
        throwsFormatException,
      );
      expect(() => GroupStorage.importBackup('not json'), throwsFormatException);
    });
  });
}
