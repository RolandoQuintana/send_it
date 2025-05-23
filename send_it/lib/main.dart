import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'models/message_group.dart';
import 'screens/create_group_screen.dart';
import 'screens/group_message_screen.dart';
import 'services/group_storage.dart';

void main() {
  runApp(const SendItApp());
}

class SendItApp extends StatelessWidget {
  const SendItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Sent It',
      theme: const CupertinoThemeData(
        primaryColor: Color(0xFF0fa0ab),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: CupertinoColors.black,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(color: CupertinoColors.white),
        ),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Contact> selectedContacts = [];
  List<Contact> allContacts = [];
  List<Contact> filteredContacts = [];
  bool isLoading = false;
  bool isComposing = false;
  Contact? currentContact;
  static const platform = MethodChannel('com.sendit/messages');
  List<MessageGroup> groups = [];

  @override
  void initState() {
    super.initState();
    _requestContactsPermission();
    _searchController.addListener(_filterContacts);
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredContacts = allContacts.where((contact) {
        return contact.displayName.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _requestContactsPermission() async {
    final granted = await FlutterContacts.requestPermission();
    if (granted) {
      await _loadContacts();
    } else {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Permission Required'),
            content: const Text('Contacts permission is required to use this app.'),
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

  Future<void> _loadContacts() async {
    setState(() => isLoading = true);
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      setState(() {
        allContacts = contacts;
        filteredContacts = contacts;
        isLoading = false;
      });
      await _loadGroups();
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Error loading contacts: $e'),
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

  Future<void> _loadGroups() async {
    try {
      final loadedGroups = await GroupStorage.loadGroups(allContacts);
      setState(() {
        groups = loadedGroups;
      });
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Error loading groups: $e'),
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

  Future<void> _createNewGroup() async {
    final group = await Navigator.push<MessageGroup>(
      context,
      CupertinoPageRoute(
        builder: (context) => CreateGroupScreen(
          allContacts: allContacts,
          onGroupCreated: (group) async {
            await GroupStorage.addGroup(group);
            await _loadGroups();
          },
        ),
      ),
    );
  }

  void _openGroup(MessageGroup group) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => GroupMessageScreen(
          group: group,
          allContacts: allContacts,
          onGroupUpdated: (updatedGroup) async {
            await GroupStorage.updateGroup(updatedGroup);
            await _loadGroups();
          },
          onGroupDeleted: (groupId) async {
            await GroupStorage.deleteGroup(groupId);
            await _loadGroups();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Sent It'),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : groups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No groups yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create one to get started!',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CupertinoButton.filled(
                              onPressed: _createNewGroup,
                              child: const Text('Create Group'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return CupertinoListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF0fa0ab),
                              child: Text(
                                group.name[0],
                                style: const TextStyle(color: CupertinoColors.white),
                              ),
                            ),
                            title: Text(group.name),
                            subtitle: Text('${group.members.length} members'),
                            trailing: const CupertinoListTileChevron(),
                            onTap: () => _openGroup(group),
                          );
                        },
                      ),
            if (groups.isNotEmpty)
              Positioned(
                right: 16,
                bottom: 16,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0fa0ab),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.add,
                      color: CupertinoColors.white,
                      size: 30,
                    ),
                  ),
                  onPressed: _createNewGroup,
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
    _searchController.dispose();
    super.dispose();
  }
}

class MessageComposer extends StatelessWidget {
  final Contact contact;
  final String message;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const MessageComposer({
    super.key,
    required this.contact,
    required this.message,
    required this.onSend,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(contact.displayName[0]),
            ),
            title: Text(contact.displayName),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: onSend,
                child: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
