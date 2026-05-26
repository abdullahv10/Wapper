import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'collection_provider.dart';

class ScheduleSwitchProvider extends ChangeNotifier {
  bool _isScheduleEnabled = false;
  
  static const String _schedulePrefKey = 'is_schedule_enabled'; 

  bool get isScheduleEnabled => _isScheduleEnabled;

  ScheduleSwitchProvider() {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    debugPrint('🚀 [ScheduleSwitchProvider] Loading initial state');
    try {
      final prefs = await SharedPreferences.getInstance();
      _isScheduleEnabled = prefs.getBool(_schedulePrefKey) ?? false;
      debugPrint('👀 [ScheduleSwitchProvider] Schedule enabled state: $_isScheduleEnabled');
      notifyListeners();
      debugPrint('✅ [ScheduleSwitchProvider] Initial state loaded successfully');
    } catch (e) {
      debugPrint('🛑 [ScheduleSwitchProvider] ERROR loading state: $e');
    }
  }

  String? tryEnableSchedule(CollectionProvider dataProvider) {
    debugPrint('🚀 [ScheduleSwitchProvider] Attempting to enable schedule mode...');
    
    if (dataProvider.collections.isEmpty) {
      debugPrint('🛑 [ScheduleSwitchProvider] Failed: No collections exist.');
      return "You need to create at least one collection first.";
    }
    if (dataProvider.schedules.isEmpty) {
      debugPrint('🛑 [ScheduleSwitchProvider] Failed: No schedules exist.');
      return "Please tap the + button to create a schedule rule.";
    }
    
    final gaps = dataProvider.getMissingTimeGaps();
    if (gaps.isNotEmpty) {
      final gapText = gaps.join(', '); 
      debugPrint('🛑 [ScheduleSwitchProvider] Failed: Missing time gaps -> $gapText');
      return "Missing coverage for: $gapText"; 
    }

    _isScheduleEnabled = true;
    _saveStateToStorage(true); 
    notifyListeners();
    debugPrint('✅ [ScheduleSwitchProvider] Schedule mode successfully enabled.');
    return null;
  }

  void disableSchedule() {
    debugPrint('🚀 [ScheduleSwitchProvider] Disabling schedule mode.');
    _isScheduleEnabled = false;
    _saveStateToStorage(false); 
    notifyListeners();
    debugPrint('✅ [ScheduleSwitchProvider] Schedule mode disabled.');
  }

  void validateSwitchState(CollectionProvider dataProvider) {
    if (!_isScheduleEnabled) return; 
    
    debugPrint('🚀 [ScheduleSwitchProvider] Validating current switch state...');
    if (dataProvider.collections.isEmpty || 
        dataProvider.schedules.isEmpty || 
        dataProvider.getMissingTimeGaps().isNotEmpty) {
      debugPrint('🛑 [ScheduleSwitchProvider] State invalid. Auto-disabling schedule.');
      disableSchedule(); 
    } else {
      debugPrint('✅ [ScheduleSwitchProvider] State remains valid.');
    }
  }

  Future<void> _saveStateToStorage(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_schedulePrefKey, value);
      debugPrint('✅ [ScheduleSwitchProvider] Saved state to storage: $value');
    } catch (e) {
      debugPrint('🛑 [ScheduleSwitchProvider] ERROR saving state to storage: $e');
    }
  }
}