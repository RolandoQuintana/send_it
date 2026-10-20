import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/message_group.dart';
import '../services/contacts_access_service.dart';
import '../widgets/group_form_screen.dart';

class CreateGroupScreen extends StatelessWidget {
  final List<Contact> allContacts;
  final ContactsAccess contactsAccess;
  final Future<ContactsLoad> Function({required bool request})? loadContacts;
  final Function(MessageGroup) onGroupCreated;

  const CreateGroupScreen({
    super.key,
    required this.allContacts,
    this.contactsAccess = ContactsAccess.granted,
    this.loadContacts,
    required this.onGroupCreated,
  });

  @override
  Widget build(BuildContext context) {
    return GroupFormScreen(
      title: 'New Group',
      submitLabel: 'Create',
      allContacts: allContacts,
      contactsAccess: contactsAccess,
      loadContacts: loadContacts,
      onSubmit: (name, members) async {
        onGroupCreated(MessageGroup.create(name: name, members: members));
        Navigator.pop(context);
      },
    );
  }
}
