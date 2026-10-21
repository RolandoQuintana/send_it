import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/message_group.dart';
import '../services/contacts_access_service.dart';
import '../services/group_storage.dart';
import '../widgets/group_form_screen.dart';

class EditGroupScreen extends StatelessWidget {
  final MessageGroup group;
  final List<Contact> allContacts;
  final ContactsAccess contactsAccess;
  final Future<ContactsLoad> Function({required bool request})? loadContacts;
  final Function(MessageGroup) onGroupUpdated;

  const EditGroupScreen({
    super.key,
    required this.group,
    required this.allContacts,
    this.contactsAccess = ContactsAccess.granted,
    this.loadContacts,
    required this.onGroupUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return GroupFormScreen(
      title: 'Edit Group',
      submitLabel: 'Save',
      allContacts: allContacts,
      contactsAccess: contactsAccess,
      loadContacts: loadContacts,
      initialName: group.name,
      initialMembers: group.members,
      onSubmit: (name, members) async {
        final updatedGroup = MessageGroup(
          id: group.id,
          name: name,
          members: members,
          createdAt: group.createdAt,
        );
        await GroupStorage.updateGroup(updatedGroup);
        onGroupUpdated(updatedGroup);
        if (context.mounted) Navigator.pop(context, updatedGroup);
      },
    );
  }
}
