import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' show canLaunchUrl, launchUrl;

import '../constants/diagnostic_constants.dart';

const _channel = MethodChannel('com.sendit/messages');

enum ShortcutLaunchResult { launched, notInstalled, noValidContacts }

class ShortcutService {
  static const String _productionShortcutName = 'Sent It Blast';
  static const String _shortcutNameOverride = String.fromEnvironment(
    'BLAST_SHORTCUT_NAME',
  );
  static const String _installedKey = 'blast_shortcut_installed';
  static const String _diagnosticInstalledKey =
      'blast_diagnostic_shortcut_installed';

  static bool get isBlastDiagnosticsEnabled =>
      DiagnosticConstants.blastDiagnosticsEnabled;

  /// Shortcut launched by Blast. Diagnostics builds use the diagnostic name
  /// unless [BLAST_SHORTCUT_NAME] is set (local dev override).
  static String get shortcutName {
    if (_shortcutNameOverride.isNotEmpty) return _shortcutNameOverride;
    if (isBlastDiagnosticsEnabled) {
      return DiagnosticConstants.diagnosticShortcutName;
    }
    return _productionShortcutName;
  }

  static Future<bool> isBlastInstalled() async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        isBlastDiagnosticsEnabled ? _diagnosticInstalledKey : _installedKey;
    return prefs.getBool(key) ?? false;
  }

  static Future<void> markBlastInstalled() async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        isBlastDiagnosticsEnabled ? _diagnosticInstalledKey : _installedKey;
    await prefs.setBool(key, true);
  }

  static String personalizeMessage(String template, Contact contact) {
    final firstName = contact.displayName.trim().split(' ').first;
    return template.replaceAll('{firstname}', firstName);
  }

  /// Builds the JSON array written to the clipboard for Blast.
  @visibleForTesting
  static List<Map<String, dynamic>> buildShortcutPayload({
    required Iterable<({String phone, String displayName})> recipients,
    required String messageTemplate,
    String? mediaPath,
  }) {
    return recipients
        .map((recipient) {
          final number = recipient.phone.replaceAll(RegExp(r'[^0-9+]'), '');
          if (number.isEmpty) return null;
          final firstName = recipient.displayName.trim().split(' ').first;
          final message = messageTemplate.replaceAll('{firstname}', firstName);
          final item = <String, dynamic>{'number': number, 'message': message};
          if (mediaPath != null) item['mediaFile'] = mediaPath;
          return item;
        })
        .whereType<Map<String, dynamic>>()
        .toList();
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
  /// opens the Blast shortcut via the Shortcuts URL scheme.
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

    final payload = buildShortcutPayload(
      recipients: contacts.map(
        (contact) => (
          phone: contact.phones.firstOrNull?.number ?? '',
          displayName: contact.displayName,
        ),
      ),
      messageTemplate: messageTemplate,
      mediaPath: mediaPath,
    );

    if (payload.isEmpty) return ShortcutLaunchResult.noValidContacts;

    final encoded = jsonEncode(payload);
    if (kDebugMode || isBlastDiagnosticsEnabled) {
      debugPrint(
        '[Blast] payload: ${payload.length} recipients, '
        '${encoded.length} UTF-8 bytes, shortcut: $shortcutName',
      );
    }

    await Clipboard.setData(ClipboardData(text: encoded));

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

  /// Extracts the bundled production shortcut and opens it via the share sheet.
  static Future<void> openInstallPage() async {
    await _openBundledShortcut(
      assetPath: 'assets/sent_it_blast.shortcut',
      fileName: 'Sent It Blast.shortcut',
    );
  }

  /// Extracts the bundled diagnostic shortcut (TestFlight builds only).
  static Future<void> openDiagnosticInstallPage() async {
    await _openBundledShortcut(
      assetPath: DiagnosticConstants.diagnosticShortcutAsset,
      fileName: '${DiagnosticConstants.diagnosticShortcutName}.shortcut',
    );
  }

  static Future<void> _openBundledShortcut({
    required String assetPath,
    required String fileName,
  }) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await _channel.invokeMethod('openShortcutFile', {'filePath': file.path});
  }
}
