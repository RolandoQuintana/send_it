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
  late List<Contact> selectedContacts;

  @override
  void initState() {
    super.initState();
    selectedContacts = List.from(widget.group.members);
  }

  Future<void> _sendMessages() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    if (selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipient')),
      );
      return;
    }

    for (final contact in selectedContacts) {
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
          // User cancelled, ask if they want to continue with remaining messages
          final remainingCount = selectedContacts.length - selectedContacts.indexOf(contact) - 1;
          if (remainingCount > 0) {
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Message Cancelled'),
                content: Text('Do you want to continue sending to the remaining $remainingCount recipients?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Stop'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );

            if (shouldContinue != true) {
              // User chose to stop sending
              break;
            }
          }
          // If user chose to continue or there are no more recipients, continue to next contact
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
        // Update selected contacts to match the new group members
        selectedContacts = List.from(updatedGroup.members);
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
                final isSelected = selectedContacts.contains(contact);
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(contact.displayName[0]),
                  ),
                  title: Text(contact.displayName),
                  subtitle: Text(contact.phones.firstOrNull?.number ?? 'No phone number'),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedContacts.add(contact);
                        } else {
                          selectedContacts.remove(contact);
                        }
                      });
                    },
                  ),
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
                  child: Text('Send to ${selectedContacts.length} Recipients'),
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