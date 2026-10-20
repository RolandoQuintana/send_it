import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppearanceMode {
  system('System'),
  light('Light'),
  dark('Dark');

  const AppearanceMode(this.label);

  final String label;

  /// Brightness to force on the theme; null follows the system.
  Brightness? get brightness => switch (this) {
        AppearanceMode.system => null,
        AppearanceMode.light => Brightness.light,
        AppearanceMode.dark => Brightness.dark,
      };
}

/// Persisted **Appearance** (More → Appearance).
///
/// The app shipped dark-only, so installs that already have data default
/// to [AppearanceMode.dark]; fresh installs follow the system. The resolved
/// default is written on first run so it never flips later.
class AppearanceService extends ChangeNotifier {
  AppearanceService._();

  static final AppearanceService instance = AppearanceService._();

  static const prefsKey = 'appearance_mode';

  AppearanceMode _mode = AppearanceMode.system;
  bool _initialized = false;

  AppearanceMode get mode => _mode;

  /// Call before any other service writes to SharedPreferences: an empty
  /// store is how a fresh install is told apart from an existing user.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final stored = _parse(prefs.getString(prefsKey));
    if (stored != null) {
      _mode = stored;
    } else {
      final existingUser = prefs.getKeys().isNotEmpty;
      _mode = existingUser ? AppearanceMode.dark : AppearanceMode.system;
      await prefs.setString(prefsKey, _mode.name);
    }

    notifyListeners();
  }

  Future<void> setMode(AppearanceMode mode) async {
    if (mode == _mode) return;

    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, mode.name);
  }

  static AppearanceMode? _parse(String? stored) {
    for (final mode in AppearanceMode.values) {
      if (mode.name == stored) return mode;
    }
    return null;
  }

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _mode = AppearanceMode.system;
  }
}
