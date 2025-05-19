import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/message_group.dart';

class GroupStorage {
  static const String _storageKey = 'message_groups';
  static List<Contact>? _cachedContacts;

  static void setContacts(List<Contact> contacts) {
    _cachedContacts = contacts;
  }

  static Future<List<MessageGroup>> loadGroups(List<Contact> allContacts) async {
    _cachedContacts = allContacts;
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getStringList(_storageKey) ?? [];

    return groupsJson.map((json) {
      final Map<String, dynamic> groupData = jsonDecode(json);
      return MessageGroup.fromJson(groupData, allContacts);
    }).toList();
  }

  static Future<void> saveGroups(List<MessageGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = groups.map((group) => jsonEncode(group.toJson())).toList();
    await prefs.setStringList(_storageKey, groupsJson);
  }

  static Future<void> addGroup(MessageGroup group) async {
    if (_cachedContacts == null) {
      throw Exception('Contacts not initialized. Call loadGroups first.');
    }
    final groups = await loadGroups(_cachedContacts!);
    groups.add(group);
    await saveGroups(groups);
  }

  static Future<void> deleteGroup(String groupId) async {
    if (_cachedContacts == null) {
      throw Exception('Contacts not initialized. Call loadGroups first.');
    }
    final groups = await loadGroups(_cachedContacts!);
    groups.removeWhere((group) => group.id == groupId);
    await saveGroups(groups);
  }

  static Future<void> updateGroup(MessageGroup updatedGroup) async {
    if (_cachedContacts == null) {
      throw Exception('Contacts not initialized. Call loadGroups first.');
    }
    final groups = await loadGroups(_cachedContacts!);
    final index = groups.indexWhere((group) => group.id == updatedGroup.id);
    if (index != -1) {
      groups[index] = updatedGroup;
      await saveGroups(groups);
    }
  }
}