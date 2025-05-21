import 'package:flutter/cupertino.dart';
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
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Please enter a message'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    if (selectedContacts.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Please select at least one recipient'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
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
            final shouldContinue = await showCupertinoDialog<bool>(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Message Cancelled'),
                content: Text('Do you want to continue sending to the remaining $remainingCount recipients?'),
                actions: [
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Stop'),
                  ),
                  CupertinoDialogAction(
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
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Error: ${e.message}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _editGroup() async {
    final updatedGroup = await Navigator.push<MessageGroup>(
      context,
      CupertinoPageRoute(
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
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.group.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.pencil),
              onPressed: _editGroup,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.delete),
              onPressed: _deleteGroup,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.group.members.length,
                itemBuilder: (context, index) {
                  final contact = widget.group.members[index];
                  final isSelected = selectedContacts.contains(contact);
                  return CupertinoListTile(
                    leading: CircleAvatar(
                      backgroundColor: CupertinoColors.systemBlue,
                      child: Text(
                        contact.displayName[0],
                        style: const TextStyle(color: CupertinoColors.white),
                      ),
                    ),
                    title: Text(contact.displayName),
                    subtitle: Text(contact.phones.firstOrNull?.number ?? 'No phone number'),
                    trailing: CupertinoSwitch(
                      value: isSelected,
                      onChanged: (bool value) {
                        setState(() {
                          if (value) {
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
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: CupertinoColors.black,
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.systemGrey4,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  CupertinoTextField(
                    controller: _messageController,
                    placeholder: 'Enter your message',
                    maxLines: 3,
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton.filled(
                    onPressed: _sendMessages,
                    child: Text('Send to ${selectedContacts.length} Recipients'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}