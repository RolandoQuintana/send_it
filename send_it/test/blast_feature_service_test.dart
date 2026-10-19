import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/services/blast_feature_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BlastFeatureService.instance.resetForTesting();
  });

  group('BlastFeatureService', () {
    test('defaults to disabled after init with empty prefs', () async {
      final service = BlastFeatureService.instance;
      await service.initialize();

      expect(service.isEnabled, isFalse);
    });

    test('setEnabled(true) persists and updates getter', () async {
      final service = BlastFeatureService.instance;
      await service.initialize();

      await service.setEnabled(true);

      expect(service.isEnabled, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('blast_experimental_enabled'), isTrue);
    });

    test('setEnabled(false) persists', () async {
      final service = BlastFeatureService.instance;
      await service.initialize();
      await service.setEnabled(true);

      await service.setEnabled(false);

      expect(service.isEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('blast_experimental_enabled'), isFalse);
    });

    test('acknowledgeAndEnable persists both flags', () async {
      final service = BlastFeatureService.instance;
      await service.initialize();

      await service.acknowledgeAndEnable();

      expect(service.isEnabled, isTrue);
      expect(service.hasAcknowledgedWarning, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('blast_experimental_enabled'), isTrue);
      expect(prefs.getBool('blast_experimental_warning_acknowledged'), isTrue);
    });

    test('already-enabled users are auto-acknowledged on init', () async {
      SharedPreferences.setMockInitialValues({
        'blast_experimental_enabled': true,
      });
      BlastFeatureService.instance.resetForTesting();

      final service = BlastFeatureService.instance;
      await service.initialize();

      expect(service.isEnabled, isTrue);
      expect(service.hasAcknowledgedWarning, isTrue);
    });
  });
}
