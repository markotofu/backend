import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _prefKey = 'pref_is_dark_mode';

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_prefKey) ?? false;
    _mode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    _mode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }
}

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'ThemeControllerScope not found in widget tree');
    return scope!.notifier!;
  }
}
