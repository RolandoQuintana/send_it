import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/message_group.dart';
import '../services/group_storage.dart';

class EditGroupScreen extends StatefulWidget {
  final MessageGroup group;
  final List<Contact> allContacts;
  final Function(MessageGroup) onGroupUpdated;

  const EditGroupScreen({
    super.key,
    required this.group,
    required this.allContacts,
    required this.onGroupUpdated,
  });

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  late TextEditingController _nameController;
  late List<Contact> selectedContacts;
  late List<Contact> filteredContacts;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    selectedContacts = List.from(widget.group.members);
    filteredContacts = widget.allContacts;
    _searchController.addListener(_filterContacts);
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredContacts = widget.allContacts.where((contact) {
        return contact.displayName.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact')),
      );
      return;
    }

    final updatedGroup = MessageGroup(
      id: widget.group.id,
      name: _nameController.text,
      members: selectedContacts,
      createdAt: widget.group.createdAt,
    );

    await GroupStorage.updateGroup(updatedGroup);
    widget.onGroupUpdated(updatedGroup);
    if (mounted) {
      Navigator.pop(context, updatedGroup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Group'),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = filteredContacts[index];
                final isSelected = selectedContacts.contains(contact);
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(contact.displayName[0]),
                  ),
                  title: Text(contact.displayName),
                  trailing: IconButton(
                    icon: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? Colors.blue : null,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          selectedContacts.remove(contact);
                        } else {
                          selectedContacts.add(contact);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}