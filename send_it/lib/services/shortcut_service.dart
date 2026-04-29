import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' show canLaunchUrl, launchUrl;

const _channel = MethodChannel('com.sendit/messages');

enum ShortcutLaunchResult { launched, notInstalled, noValidContacts }

class ShortcutService {

  static const String shortcutName = 'Sent It Blast';
  static const String _installedKey = 'blast_shortcut_installed';

  static Future<bool> isBlastInstalled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_installedKey) ?? false;
  }

  static Future<void> markBlastInstalled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_installedKey, true);
  }

  static String personalizeMessage(String template, Contact contact) {
    final firstName = contact.displayName.trim().split(' ').first;
    return template.replaceAll('{firstname}', firstName);
  }

  /// Copies [mediaFile] into the app's Documents directory as
  /// `blast_media.<ext>`.
  ///
  /// Because UIFileSharingEnabled is set, this folder is visible in the Files
  /// app under "On My iPhone → Sent It", which Shortcuts can reach via
  /// "Get File from [On My iPhone/Sent It] at Path [filename]".
  ///
  /// Returns just the filename (e.g. `blast_media.jpg`), or null if no file.
  static Future<String?> _stageMediaFile(File? mediaFile) async {
    if (mediaFile == null) return null;
    final ext = mediaFile.path.split('.').last.toLowerCase();
    final filename = 'blast_media.$ext';
    final docsDir = await getApplicationDocumentsDirectory();
    await mediaFile.copy('${docsDir.path}/$filename');
    return filename;
  }

  /// Builds a personalized JSON payload, copies it to the clipboard, then
  /// opens the "Sent It Blast" shortcut via the Shortcuts URL scheme.
  ///
  /// Payload format (array written to clipboard):
  /// [{"number": "+15551234567", "message": "Hey John, ...", "mediaFile": "blast_media.jpg"}, ...]
  ///
  /// `mediaFile` is only included when [mediaFile] is provided. The shortcut
  /// uses "Get File from [On My iPhone/Sent It] at Path [mediaFile]" to attach
  /// the staged file to each Send Message action.
  static Future<ShortcutLaunchResult> sendViaShortcut({
    required List<Contact> contacts,
    required String messageTemplate,
    File? mediaFile,
  }) async {
    final mediaPath = await _stageMediaFile(mediaFile);

    final payload = contacts
        .map((contact) {
          final raw = contact.phones.firstOrNull?.number;
          if (raw == null) return null;
          final number = raw.replaceAll(RegExp(r'[^0-9+]'), '');
          if (number.isEmpty) return null;
          final message = personalizeMessage(messageTemplate, contact);
          final item = <String, dynamic>{'number': number, 'message': message};
          if (mediaPath != null) item['mediaFile'] = mediaPath;
          return item;
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

  /// Extracts the bundled shortcut file to a temp directory and opens it
  /// via the system share sheet, which routes it directly to Shortcuts.app.
  static Future<void> openInstallPage() async {
    final data = await rootBundle.load('assets/sent_it_blast.shortcut');
    final bytes = data.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Sent It Blast.shortcut');
    await file.writeAsBytes(bytes, flush: true);
    await _channel.invokeMethod('openShortcutFile', {'filePath': file.path});
  }
}
