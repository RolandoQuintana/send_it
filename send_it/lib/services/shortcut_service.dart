import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

enum ShortcutLaunchResult { launched, notInstalled, noValidContacts }

class ShortcutService {
  // Update this URL once the shortcut is published to iCloud
  static const String shortcutInstallUrl =
      'https://www.icloud.com/shortcuts/PLACEHOLDER';

  // Must match the name the user gives the shortcut when installing
  static const String shortcutName = 'Sent It Blast';

  static String _personalizeMessage(String template, Contact contact) {
    final firstName = contact.displayName.trim().split(' ').first;
    return template.replaceAll('{firstname}', firstName);
  }

  /// Builds a personalized JSON payload, copies it to the clipboard, then
  /// opens the "Send It Blast" shortcut via the Shortcuts URL scheme.
  ///
  /// Payload format (array written to clipboard):
  /// [{"number": "+15551234567", "message": "Hey John, ..."}, ...]
  ///
  /// The shortcut reads clipboard input, iterates with "Repeat with Each",
  /// extracts "number" and "message" from each dictionary item, and calls
  /// the "Send Message" action — sending individual iMessages/SMS with no
  /// per-message confirmation required from the user.
  static Future<ShortcutLaunchResult> sendViaShortcut({
    required List<Contact> contacts,
    required String messageTemplate,
  }) async {
    final payload = contacts
        .map((contact) {
          final raw = contact.phones.firstOrNull?.number;
          if (raw == null) return null;
          final number = raw.replaceAll(RegExp(r'[^0-9+]'), '');
          if (number.isEmpty) return null;
          final message = _personalizeMessage(messageTemplate, contact);
          return {'number': number, 'message': message};
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    if (payload.isEmpty) return ShortcutLaunchResult.noValidContacts;

    await Clipboard.setData(ClipboardData(text: jsonEncode(payload)));

    final url = Uri.parse(
      'shortcuts://run-shortcut'
      '?name=${Uri.encodeComponent(shortcutName)}'
      '&input=clipboard',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return ShortcutLaunchResult.launched;
    }

    return ShortcutLaunchResult.notInstalled;
  }

  /// Opens the iCloud link to install the "Send It Blast" shortcut.
  static Future<void> openInstallPage() async {
    final url = Uri.parse(shortcutInstallUrl);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
