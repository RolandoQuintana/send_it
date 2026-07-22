import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/message_group.dart';
import '../services/contact_search_service.dart';

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
  bool searchName = true;
  bool searchCompany = true;

  @override
  void initState() {
    super.initState();
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

  void _createGroup() {
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

    final group = MessageGroup.create(
      name: _nameController.text,
      members: selectedContacts,
    );

    widget.onGroupCreated(group);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Create New Group'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Create'),
          onPressed: _createGroup,
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