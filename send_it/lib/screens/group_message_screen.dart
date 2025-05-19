import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/message_group.dart';
import '../services/group_storage.dart';
import 'edit_group_screen.dart';

class GroupMessageScreen extends StatefulWidget {
  final MessageGroup group;
  final List<Contact> allContacts;
  final Function(MessageGroup) onGroupUpdated;
  final Function(String) onGroupDeleted;

  const GroupMessageScreen({
    super.key,
    required this.group,
    required this.allContacts,
    required this.onGroupUpdated,
    required this.onGroupDeleted,
  });

  @override
  State<GroupMessageScreen> createState() => _GroupMessageScreenState();
}

class _GroupMessageScreenState extends State<GroupMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  static const platform = MethodChannel('com.sendit/messages');

  Future<void> _sendMessages() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    for (final contact in widget.group.members) {
      final phoneNumber = contact.phones.firstOrNull?.number;
      if (phoneNumber == null) continue;

      // Clean up phone number format
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      try {
        final args = {
          'recipient': cleanNumber,
          'message': _messageController.text,
        };

        final result = await platform.invokeMethod('sendMessage', args);

        if (result == "sent") {
          // Message was sent successfully, continue to next contact
          continue;
        } else if (result == "cancelled") {
          // User cancelled, skip this contact
          continue;
        }
      } on PlatformException catch (e) {
        print('Platform Exception: ${e.code} - ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  Future<void> _editGroup() async {
    final updatedGroup = await Navigator.push<MessageGroup>(
      context,
      MaterialPageRoute(
        builder: (context) => EditGroupScreen(
          group: widget.group,
          allContacts: widget.allContacts,
          onGroupUpdated: widget.onGroupUpdated,
        ),
      ),
    );

    if (updatedGroup != null && mounted) {
      setState(() {
        widget.group.members.clear();
        widget.group.members.addAll(updatedGroup.members);
      });
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GroupStorage.deleteGroup(widget.group.id);
      widget.onGroupDeleted(widget.group.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editGroup,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteGroup,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.group.members.length,
              itemBuilder: (context, index) {
                final contact = widget.group.members[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(contact.displayName[0]),
                  ),
                  title: Text(contact.displayName),
                  subtitle: Text(contact.phones.firstOrNull?.number ?? 'No phone number'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _sendMessages,
                  child: const Text('Send to Group'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}