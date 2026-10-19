import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlastFeatureService extends ChangeNotifier {
  BlastFeatureService._();

  static final BlastFeatureService instance = BlastFeatureService._();

  static const experimentalDisclaimer =
      'This feature is experimental. It may not work reliably for large groups or with certain types of media.';

  static const _prefsKey = 'blast_experimental_enabled';
  static const _warningAckKey = 'blast_experimental_warning_acknowledged';

  bool _enabled = false;
  bool _warningAcknowledged = false;
  bool _initialized = false;

  bool get isEnabled => _enabled;
  bool get hasAcknowledgedWarning => _warningAcknowledged;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsKey) ?? false;
    _warningAcknowledged = prefs.getBool(_warningAckKey) ?? false;

    // Users who enabled Blast before the acknowledgement gate shipped.
    if (_enabled && !_warningAcknowledged) {
      _warningAcknowledged = true;
      await prefs.setBool(_warningAckKey, true);
    }

    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;

    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    notifyListeners();
  }

  /// Enables Blast and records that the user confirmed the experimental warning.
  Future<void> acknowledgeAndEnable() async {
    if (_enabled && _warningAcknowledged) return;

    _enabled = true;
    _warningAcknowledged = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    await prefs.setBool(_warningAckKey, true);
    notifyListeners();
  }

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _enabled = false;
    _warningAcknowledged = false;
  }
}
