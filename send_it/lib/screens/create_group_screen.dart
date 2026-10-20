import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/message_group.dart';
import '../widgets/group_form_screen.dart';

class CreateGroupScreen extends StatelessWidget {
  final List<Contact> allContacts;
  final Function(MessageGroup) onGroupCreated;

  const CreateGroupScreen({
    super.key,
    required this.allContacts,
    required this.onGroupCreated,
  });

  @override
  Widget build(BuildContext context) {
    return GroupFormScreen(
      title: 'New Group',
      submitLabel: 'Create',
      allContacts: allContacts,
      onSubmit: (name, members) async {
        onGroupCreated(MessageGroup.create(name: name, members: members));
        Navigator.pop(context);
      },
    );
  }
}
