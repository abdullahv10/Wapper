import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _pauseOnLowBattery = true;
  bool _isShuffleMode = false;

  // Fixed: key now matches what BackgroundEngine reads
  static const String _lowBatteryPrefKey = 'pause_on_low_battery';
  static const String _shufflePrefKey = 'is_shuffle_mode';

  bool get pauseOnLowBattery => _pauseOnLowBattery;
  bool get isShuffleMode => _isShuffleMode;

  SettingsProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    debugPrint('🚀 [SettingsProvider] Loading settings from storage...');
    try {
      final prefs = await SharedPreferences.getInstance();
      _pauseOnLowBattery = prefs.getBool(_lowBatteryPrefKey) ?? true;
      _isShuffleMode = prefs.getBool(_shufflePrefKey) ?? false;
      debugPrint(
        '👀 [SettingsProvider] pauseOnLowBattery: $_pauseOnLowBattery, shuffle: $_isShuffleMode',
      );
      notifyListeners();
      debugPrint('✅ [SettingsProvider] Settings loaded successfully.');
    } catch (e) {
      debugPrint('🛑 [SettingsProvider] ERROR loading settings: $e');
    }
  }

  Future<void> toggleLowBattery(bool newValue) async {
    debugPrint(
      '🚀 [SettingsProvider] Toggling pauseOnLowBattery to: $newValue',
    );
    _pauseOnLowBattery = newValue;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lowBatteryPrefKey, newValue);
      debugPrint('✅ [SettingsProvider] pauseOnLowBattery saved.');
    } catch (e) {
      debugPrint('🛑 [SettingsProvider] ERROR saving pauseOnLowBattery: $e');
    }
  }

  // Keep old name as a passthrough so existing UI code doesn't break
  Future<void> toggleSwitch(bool newValue) => toggleLowBattery(newValue);

  Future<void> toggleShuffleMode(bool value) async {
    if (_isShuffleMode == value) return;
    debugPrint('🚀 [SettingsProvider] Toggling shuffleMode to: $value');
    _isShuffleMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_shufflePrefKey, value);
      debugPrint('✅ [SettingsProvider] shuffleMode saved.');
    } catch (e) {
      debugPrint('🛑 [SettingsProvider] ERROR saving shuffleMode: $e');
    }
  }

  Future<void> ensureBackgroundServiceIsRunning() async {
    const channel = MethodChannel('com.wapper.app/wallpaper');
    try {
      // Just tell Kotlin to wake up and check its own settings.
      // Because it's a Foreground Service, it will survive the next swipe!
      await channel.invokeMethod('refreshService');
      debugPrint("🚀 [Auto-Heal] Kotlin Foreground Service refreshed.");
    } catch (e) {
      debugPrint("🛑 [Auto-Heal] Failed to wake service: $e");
    }
  }
}
