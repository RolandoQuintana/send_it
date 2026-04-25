import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/message_group.dart';
import '../services/group_storage.dart';
import '../services/contact_search_service.dart';

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
  bool searchName = true;
  bool searchCompany = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    selectedContacts = List.from(widget.group.members);
    filteredContacts = widget.allContacts;
    _searchController.addListener(_filterContacts);
  }

  void _filterContacts() {
    final query = _searchController.text;
    setState(() {
      filteredContacts = ContactSearchService.searchContacts(
        widget.allContacts,
        query,
        searchName: searchName,
        searchCompany: searchCompany,
      );
    });
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Please enter a group name'),
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
          content: const Text('Please select at least one contact'),
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Edit Group'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Save'),
          onPressed: _saveChanges,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoTextField(
                controller: _nameController,
                placeholder: 'Group Name',
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search contacts...',
              ),
            ),
            // Search filter options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            searchName ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                            size: 16,
                            color: searchName ? CupertinoColors.systemBlue : CupertinoColors.systemGrey,
                          ),
                          const SizedBox(width: 4),
                          const Text('Name', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      onPressed: () {
                        setState(() {
                          searchName = !searchName;
                          _filterContacts();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            searchCompany ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                            size: 16,
                            color: searchCompany ? CupertinoColors.systemBlue : CupertinoColors.systemGrey,
                          ),
                          const SizedBox(width: 4),
                          const Text('Company', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      onPressed: () {
                        setState(() {
                          searchCompany = !searchCompany;
                          _filterContacts();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = filteredContacts[index];
                  final isSelected = selectedContacts.contains(contact);
                  final searchResult = _searchController.text.isNotEmpty
                      ? ContactSearchService.getSearchResult(contact, _searchController.text)
                      : null;

                  // Get company info for display
                  String companyInfo = '';
                  if (contact.organizations.isNotEmpty) {
                    final org = contact.organizations.first;
                    if (org.company.isNotEmpty) {
                      companyInfo = org.company;
                      if (org.title.isNotEmpty) {
                        companyInfo += ' • ${org.title}';
                      }
                    }
                  }

                  return CupertinoListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0fa0ab),
                      child: Text(
                        contact.displayName[0],
                        style: const TextStyle(color: CupertinoColors.white),
                      ),
                    ),
                    title: Text(contact.displayName),
                    subtitle: companyInfo.isNotEmpty
                        ? Text(
                            companyInfo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (searchResult != null && searchResult.matchSummary.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              searchResult.matchSummary,
                              style: const TextStyle(
                                fontSize: 10,
                                color: CupertinoColors.systemBlue,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        CupertinoSwitch(
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
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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