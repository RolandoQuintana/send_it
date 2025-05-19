import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/message_group.dart';

class CreateGroupScreen extends StatefulWidget {
  final List<Contact> allContacts;
  final Function(MessageGroup) onGroupCreated;

  const CreateGroupScreen({
    super.key,
    required this.allContacts,
    required this.onGroupCreated,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Contact> selectedContacts = [];
  List<Contact> filteredContacts = [];

  @override
  void initState() {
    super.initState();
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

  void _createGroup() {
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

    final group = MessageGroup.create(
      name: _nameController.text,
      members: selectedContacts,
    );

    widget.onGroupCreated(group);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Group'),
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: const Text('Create'),
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