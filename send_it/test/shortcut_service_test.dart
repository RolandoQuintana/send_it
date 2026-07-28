import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/services/shortcut_service.dart';

void main() {
  group('ShortcutService.buildShortcutPayload', () {
    test('personalizes first name and strips phone formatting', () {
      final payload = ShortcutService.buildShortcutPayload(
        recipients: [
          (phone: '(555) 010-0422', displayName: 'Scale042 Tester'),
        ],
        messageTemplate: 'Hi {firstname}!',
      );

      expect(payload, [
        {'number': '5550100422', 'message': 'Hi Scale042!'},
      ]);
    });

    test('includes mediaFile when mediaPath is set', () {
      final payload = ShortcutService.buildShortcutPayload(
        recipients: [
          (phone: '+15550100', displayName: 'Scale001 Tester'),
        ],
        messageTemplate: 'Hi {firstname}',
        mediaPath: 'blast_media.jpg',
      );

      expect(payload.first['mediaFile'], 'blast_media.jpg');
    });

    test('skips recipients with empty phone numbers', () {
      final payload = ShortcutService.buildShortcutPayload(
        recipients: [
          (phone: '', displayName: 'No Phone'),
          (phone: '+15550101', displayName: 'Scale002 Tester'),
        ],
        messageTemplate: 'Hi {firstname}',
      );

      expect(payload.length, 1);
      expect(payload.first['number'], '+15550101');
    });

    test('200-recipient payload stays under typical pasteboard limits', () {
      final recipients = List.generate(
        200,
        (i) => (
          phone: '+1555${(100 + i).toString().padLeft(4, '0')}',
          displayName: 'Scale${(i + 1).toString().padLeft(3, '0')} Tester',
        ),
      );

      final payload = ShortcutService.buildShortcutPayload(
        recipients: recipients,
        messageTemplate: 'Hi {firstname}, scale test.',
      );
      final bytes = utf8.encode(jsonEncode(payload));

      expect(payload.length, 200);
      expect(bytes.length, lessThan(500000));
    });
  });
}
