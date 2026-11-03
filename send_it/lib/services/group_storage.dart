import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/message_group.dart';

class GroupStorage {
  static const String _storageKey = 'message_groups';
  static List<Contact>? _cachedContacts;
  static const String _backupFormat = 'sent-it-groups';

  /// Bumped when groups change outside the Groups tab (an import), so it
  /// can reload.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static void setContacts(List<Contact> contacts) {
    _cachedContacts = contacts;
  }

  static Future<List<MessageGroup>> loadGroups(List<Contact> allContacts) async {
    _cachedContacts = allContacts;
    return _readGroups(allContacts);
  }

  static Future<List<MessageGroup>> _readGroups(List<Contact> allContacts) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getStringList(_storageKey) ?? [];

    return groupsJson.map((json) {
      final Map<String, dynamic> groupData = jsonDecode(json);
      return MessageGroup.fromJson(groupData, allContacts);
    }).toList();
  }

  /// Every group as a backup file's contents, members with names and
  /// phone numbers so a new phone can match them to its own contacts.
  static Future<String> exportBackup() async {
    final groups = await _readGroups(_cachedContacts ?? const []);
    return const JsonEncoder.withIndent('  ').convert({
      'format': _backupFormat,
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'groups': groups.map((group) => group.toJson()).toList(),
    });
  }

  /// Adds a backup's groups. Groups already here (same ID) are skipped, so
  /// importing the same file twice is harmless. Nothing is saved unless the
  /// whole file reads; otherwise throws [FormatException].
  static Future<({int added, int skipped, int unmatchedMembers})> importBackup(
      String source) async {
    final contacts = _cachedContacts ?? const <Contact>[];
    final List<MessageGroup> imported;
    try {
      final data = jsonDecode(source) as Map<String, dynamic>;
      if (data['format'] != _backupFormat) throw const FormatException();
      imported = (data['groups'] as List)
          .map((group) => MessageGroup.fromJson(group as Map<String, dynamic>, contacts))
          .toList();
    } catch (_) {
      throw const FormatException("This file isn't a Sent It groups backup.");
    }

    final groups = await _readGroups(contacts);
    final ids = groups.map((group) => group.id).toSet();
    final added = imported.where((group) => ids.add(group.id)).toList();
    if (added.isNotEmpty) {
      await saveGroups([...groups, ...added]);
      revision.value++;
    }
    return (
      added: added.length,
      skipped: imported.length - added.length,
      unmatchedMembers:
          added.fold(0, (sum, group) => sum + group.unmatched.length),
    );
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