import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SendItApp());
}

class SendItApp extends StatelessWidget {
  const SendItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Send It',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
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

  @override
  void initState() {
    super.initState();
    _requestContactsPermission();
    _searchController.addListener(_filterContacts);
    _testMethodChannel();
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
      _loadContacts();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission is required')),
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
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    }
  }

  Future<void> _sendMessages() async {
    if (selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact')),
      );
      return;
    }

    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    for (final contact in selectedContacts) {
      final phoneNumber = contact.phones.firstOrNull?.number;
      if (phoneNumber == null) continue;

      // Clean up phone number format
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      print('Sending message to: ${contact.displayName}');
      print('Phone number: $cleanNumber');
      print('Message: ${_messageController.text}');

      try {
        final args = {
          'recipient': cleanNumber,
          'message': _messageController.text,
        };
        print('Arguments: $args');

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

  Future<void> _testMethodChannel() async {
    try {
      await platform.invokeMethod('test');
      print('Method channel is working');
    } catch (e) {
      print('Method channel error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send It'),
      ),
      body: Column(
        children: [
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
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
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
                  child: const Text('Send Messages'),
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
