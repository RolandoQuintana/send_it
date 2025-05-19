import 'package:flutter_contacts/flutter_contacts.dart';

class MessageGroup {
  final String id;
  final String name;
  final List<Contact> members;
  final DateTime createdAt;

  MessageGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
  });

  // Create a new group
  factory MessageGroup.create({
    required String name,
    required List<Contact> members,
  }) {
    return MessageGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      members: members,
      createdAt: DateTime.now(),
    );
  }

  // Convert to/from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'memberIds': members.map((contact) => contact.id).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory MessageGroup.fromJson(Map<String, dynamic> json, List<Contact> allContacts) {
    final memberIds = List<String>.from(json['memberIds']);
    final members = allContacts.where((contact) => memberIds.contains(contact.id)).toList();

    return MessageGroup(
      id: json['id'],
      name: json['name'],
      members: members,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}