import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/services/appearance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => AppearanceService.instance.resetForTesting());

  group('AppearanceService', () {
    test('fresh install follows the system and persists it', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AppearanceService.instance;

      await service.initialize();

      expect(service.mode, AppearanceMode.system);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppearanceService.prefsKey), 'system');
    });

    test('existing user (any stored data) defaults to dark', () async {
      SharedPreferences.setMockInitialValues({
        'message_groups': <String>['{}'],
      });
      final service = AppearanceService.instance;

      await service.initialize();

      expect(service.mode, AppearanceMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppearanceService.prefsKey), 'dark');
    });

    test('stored choice wins over the migration default', () async {
      SharedPreferences.setMockInitialValues({
        'message_groups': <String>['{}'],
        AppearanceService.prefsKey: 'light',
      });
      final service = AppearanceService.instance;

      await service.initialize();

      expect(service.mode, AppearanceMode.light);
    });

    test('unknown stored value falls back to the migration default', () async {
      SharedPreferences.setMockInitialValues({
        AppearanceService.prefsKey: 'sepia',
      });
      final service = AppearanceService.instance;

      await service.initialize();

      // The bad value itself counts as stored data, so this is an existing
      // user.
      expect(service.mode, AppearanceMode.dark);
    });

    test('setMode persists and notifies', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AppearanceService.instance;
      await service.initialize();
      var notified = 0;
      void listener() => notified++;
      service.addListener(listener);

      await service.setMode(AppearanceMode.light);

      service.removeListener(listener);
      expect(service.mode, AppearanceMode.light);
      expect(notified, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppearanceService.prefsKey), 'light');
    });

    test('modes map to theme brightness', () {
      expect(AppearanceMode.system.brightness, isNull);
      expect(AppearanceMode.light.brightness, Brightness.light);
      expect(AppearanceMode.dark.brightness, Brightness.dark);
    });
  });
}
