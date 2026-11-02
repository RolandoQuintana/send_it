import 'package:flutter_contacts/flutter_contacts.dart';

/// What we keep about a member besides the contact ID. Contact IDs are local
/// to a phone, so on a new phone members are matched by phone number instead.
class MemberSnapshot {
  final String id;
  final String name;
  final List<String> phones;

  const MemberSnapshot({
    required this.id,
    this.name = '',
    this.phones = const [],
  });

  factory MemberSnapshot.fromContact(Contact contact) => MemberSnapshot(
        id: contact.id,
        name: contact.displayName,
        phones: contact.phones.map((phone) => phone.number).toList(),
      );

  factory MemberSnapshot.fromJson(Map<String, dynamic> json) => MemberSnapshot(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phones: List<String>.from(json['phones'] as List? ?? const []),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phones': phones};

  /// Last 10 digits, so "+1 (555) 123-4567" and "5551234567" match.
  static String phoneKey(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }
}

class MessageGroup {
  final String id;
  final String name;
  final List<Contact> members;
  final DateTime createdAt;

  /// Members with no matching contact on this phone (no Contacts access yet,
  /// or not in this phone's contacts). Kept so saving doesn't drop them.
  final List<MemberSnapshot> unmatched;

  MessageGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
    this.unmatched = const [],
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
    final snapshots = [
      ...members.map(MemberSnapshot.fromContact),
      ...unmatched,
    ];
    return {
      'id': id,
      'name': name,
      'memberIds': snapshots.map((member) => member.id).toList(),
      'members': snapshots.map((member) => member.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON. Members match by contact ID first, then by phone number.
  factory MessageGroup.fromJson(Map<String, dynamic> json, List<Contact> allContacts) {
    final snapshots = json['members'] is List
        ? (json['members'] as List)
            .map((member) => MemberSnapshot.fromJson(member as Map<String, dynamic>))
            .toList()
        // Saved before snapshots existed: IDs only.
        : List<String>.from(json['memberIds'])
            .map((id) => MemberSnapshot(id: id))
            .toList();

    final byId = {for (final contact in allContacts) contact.id: contact};
    final byPhone = <String, Contact>{};
    for (final contact in allContacts) {
      for (final phone in contact.phones) {
        final key = MemberSnapshot.phoneKey(phone.number);
        if (key.isNotEmpty) byPhone.putIfAbsent(key, () => contact);
      }
    }

    final members = <Contact>[];
    final unmatched = <MemberSnapshot>[];
    for (final snapshot in snapshots) {
      final contact = byId[snapshot.id] ??
          snapshot.phones
              .map((phone) => byPhone[MemberSnapshot.phoneKey(phone)])
              .firstWhere((contact) => contact != null, orElse: () => null);
      if (contact == null) {
        unmatched.add(snapshot);
      } else if (!members.any((member) => member.id == contact.id)) {
        members.add(contact);
      }
    }

    return MessageGroup(
      id: json['id'],
      name: json['name'],
      members: members,
      createdAt: DateTime.parse(json['createdAt']),
      unmatched: unmatched,
    );
  }
}
