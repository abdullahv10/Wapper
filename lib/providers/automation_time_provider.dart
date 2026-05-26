import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutomationTimeProvider extends ChangeNotifier {
  bool _isTimerMode = true;
  String _changeInterval = '30 minutes';

  static const String _modePrefKey = 'mode_is_time_interval';
  static const String _intervalPrefKey = 'automation_interval';
  static const _channel = MethodChannel('com.wapper.app/wallpaper');

  bool get isTimerMode => _isTimerMode;
  String get changeInterval => _changeInterval;

  AutomationTimeProvider() {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isTimerMode = prefs.getBool(_modePrefKey) ?? true;
      _changeInterval = prefs.getString(_intervalPrefKey) ?? '30 minutes';
      notifyListeners();
    } catch (e) {
      debugPrint('🛑 ERROR loading state: $e');
    }
  }

  Future<void> toggleSwitch(bool value) async {
    _isTimerMode = value;
    await _saveBoolToStorage(_modePrefKey, value);
    notifyListeners();

    // 🚀 THE FIX: We NO LONGER call stopService().
    // Both modes use the Foreground Service now to survive swipes!
    await _invokeService('refreshService');
  }

  void setInterval(String interval) {
    _changeInterval = interval;
    _saveStringToStorage(_intervalPrefKey, interval);
    notifyListeners();

    if (_isTimerMode) {
      // Tell Kotlin the time changed so it restarts its loop
      _invokeService('refreshService');
    }
  }

  Future<void> _invokeService(String method) async {
    try {
      await _channel.invokeMethod(method);
    } catch (e) {
      debugPrint('🛑 Channel call failed: $e');
    }
  }

  Future<void> _saveBoolToStorage(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveStringToStorage(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
