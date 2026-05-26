import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:isolate';
import 'dart:ui';

import '../data/local/database_helper.dart';

class _Keys {
  static const scheduleEnabled = 'is_schedule_enabled';
  static const timerMode = 'mode_is_time_interval';
  static const pauseOnLowBattery = 'pause_on_low_battery';
  static const currentCollIndex = 'current_collection_index';
  static const currentImageIndex = 'current_image_index';
  static const isShuffleMode = 'is_shuffle_mode';
}

class BackgroundEngine {
  static const _channel = MethodChannel('com.wapper.app/wallpaper');

  // ─────────────────────────────────────────────
  //  PUBLIC ENTRY POINT
  // ─────────────────────────────────────────────
  static Future<void> triggerWallpaperChange() async {
    debugPrint('🚀 [BackgroundEngine] triggerWallpaperChange() called');

    try {
      final prefs = await SharedPreferences.getInstance();

      if (_shouldPauseDueToLowBattery(prefs)) {
        debugPrint('👀 [BackgroundEngine] Low battery pause active. Skipping.');
        return;
      }

      final String? collectionId = await _resolveActiveCollection(prefs);
      if (collectionId == null) {
        debugPrint(
          '🛑 [BackgroundEngine] No active collection found. Skipping.',
        );
        return;
      }
      debugPrint('✅ [BackgroundEngine] Active collection: $collectionId');

      final String? filePath = await _getNextWallpaper(prefs, collectionId);
      if (filePath == null) {
        debugPrint(
          '🛑 [BackgroundEngine] No wallpaper found in collection. Skipping.',
        );
        return;
      }
      debugPrint('✅ [BackgroundEngine] Next wallpaper: $filePath');

      await _applyWallpaper(filePath);

      // After writing pending_wallpaper_path to prefs,
      // tell Kotlin to apply it immediately
      try {
        await _channel.invokeMethod('applyPending');
        debugPrint('✅ [BackgroundEngine] applyPending called successfully');
      } on MissingPluginException {
        debugPrint(
          '👀 [BackgroundEngine] applyPending channel not ready — will apply on next resume',
        );
      } on PlatformException catch (e) {
        debugPrint('🛑 [BackgroundEngine] applyPending error: ${e.message}');
      }
    } catch (e) {
      debugPrint(
        '🛑 [BackgroundEngine] FATAL ERROR in triggerWallpaperChange: $e',
      );
    }
  }

  // ─────────────────────────────────────────────
  //  MODULE 1 + 2 — COLLECTION RESOLVER
  // ─────────────────────────────────────────────
  static Future<String?> _resolveActiveCollection(
    SharedPreferences prefs,
  ) async {
    final isScheduleEnabled = prefs.getBool(_Keys.scheduleEnabled) ?? false;
    if (isScheduleEnabled) {
      return await _resolveBySchedule();
    } else {
      return await _resolveBySequence(prefs);
    }
  }

  // Module 1: Time-of-day schedule
  static Future<String?> _resolveBySchedule() async {
    debugPrint('🚀 [BackgroundEngine] Module 1: resolving by schedule');

    final schedules = await DatabaseHelper.instance.fetchSchedules();
    if (schedules.isEmpty) {
      debugPrint('👀 [BackgroundEngine] Schedule table empty.');
      return null;
    }

    final now = DateTime.now();
    final currentMinutes = (now.hour * 60) + now.minute;

    for (final rule in schedules) {
      final timeRange = rule['timeRange'] as String;
      final parts = timeRange.split(' - ');
      if (parts.length != 2) continue;

      final startMins = _timeStringToMinutes(parts[0]);
      final endMins = _timeStringToMinutes(parts[1]);

      final bool matches;
      if (endMins <= startMins) {
        matches = currentMinutes >= startMins || currentMinutes < endMins;
      } else {
        matches = currentMinutes >= startMins && currentMinutes < endMins;
      }

      if (matches) {
        debugPrint(
          '✅ [BackgroundEngine] Schedule match: ${rule['collectionId']}',
        );
        return rule['collectionId'] as String;
      }
    }

    debugPrint('👀 [BackgroundEngine] No schedule rule matched current time.');
    return null;
  }

  // Module 2: Ordered sequence
  static Future<String?> _resolveBySequence(SharedPreferences prefs) async {
    debugPrint('🚀 [BackgroundEngine] Module 2: resolving by sequence');

    final collections = await DatabaseHelper.instance.fetchCollections();
    if (collections.isEmpty) {
      debugPrint('👀 [BackgroundEngine] No collections found.');
      return null;
    }

    int collIndex = prefs.getInt(_Keys.currentCollIndex) ?? 0;
    if (collIndex >= collections.length) {
      collIndex = 0;
      await prefs.setInt(_Keys.currentCollIndex, 0);
      await prefs.setInt(_Keys.currentImageIndex, 0);
    }

    final collection = collections[collIndex];
    final collectionId = collection['id'] as String;

    final images = await DatabaseHelper.instance.fetchWallpapers(collectionId);
    if (images.isEmpty) {
      debugPrint(
        '👀 [BackgroundEngine] Collection $collectionId is empty. Skipping to next.',
      );
      final nextIndex = (collIndex + 1) % collections.length;
      await prefs.setInt(_Keys.currentCollIndex, nextIndex);
      await prefs.setInt(_Keys.currentImageIndex, 0);
      return collections[nextIndex]['id'] as String;
    }

    debugPrint(
      '✅ [BackgroundEngine] Sequence: using collection $collectionId (index $collIndex)',
    );
    return collectionId;
  }

  // ─────────────────────────────────────────────
  //  MODULE 3 + 4 — WALLPAPER PICKER
  // ─────────────────────────────────────────────
  static Future<String?> _getNextWallpaper(
    SharedPreferences prefs,
    String collectionId,
  ) async {
    debugPrint(
      '🚀 [BackgroundEngine] Getting next wallpaper for $collectionId',
    );

    final images = await DatabaseHelper.instance.fetchWallpapers(collectionId);
    if (images.isEmpty) {
      debugPrint('🛑 [BackgroundEngine] No images in collection $collectionId');
      return null;
    }

    final isShuffle = prefs.getBool(_Keys.isShuffleMode) ?? false;
    final String filePath;

    if (isShuffle) {
      final randomIndex = Random().nextInt(images.length);
      filePath = images[randomIndex]['filePath'] as String;
      debugPrint('✅ [BackgroundEngine] Shuffle picked index $randomIndex');
    } else {
      int imageIndex = prefs.getInt(_Keys.currentImageIndex) ?? 0;
      if (imageIndex >= images.length) imageIndex = 0;

      filePath = images[imageIndex]['filePath'] as String;
      debugPrint(
        '✅ [BackgroundEngine] Sequential picked index $imageIndex / ${images.length - 1}',
      );

      final nextImageIndex = imageIndex + 1;
      if (nextImageIndex >= images.length) {
        debugPrint(
          '👀 [BackgroundEngine] Collection exhausted. Advancing to next collection.',
        );
        await _advanceToNextCollection(prefs);
      } else {
        await prefs.setInt(_Keys.currentImageIndex, nextImageIndex);
      }
    }

    return filePath;
  }

  static Future<void> _advanceToNextCollection(SharedPreferences prefs) async {
    final collections = await DatabaseHelper.instance.fetchCollections();
    if (collections.isEmpty) return;

    final currentIndex = prefs.getInt(_Keys.currentCollIndex) ?? 0;
    final nextIndex = (currentIndex + 1) % collections.length;

    await prefs.setInt(_Keys.currentCollIndex, nextIndex);
    await prefs.setInt(_Keys.currentImageIndex, 0);

    debugPrint('✅ [BackgroundEngine] Advanced to collection index $nextIndex');
  }

  // ─────────────────────────────────────────────
  //  WALLPAPER APPLIER
  // ─────────────────────────────────────────────
  static Future<void> _applyWallpaper(String filePath) async {
    debugPrint('🚀 [BackgroundEngine] Applying wallpaper: $filePath');

    try {
      // Write path to prefs — Kotlin reads this via applyPending or onResume
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_wallpaper_path', filePath);
      debugPrint('✅ [BackgroundEngine] Wrote pending_wallpaper_path to prefs');

      // Try channel — only works when app is in foreground
      await _channel.invokeMethod('setWallpaper', {'filePath': filePath});
      debugPrint('✅ [BackgroundEngine] Native setWallpaper() succeeded.');
    } on MissingPluginException {
      debugPrint(
        '👀 [BackgroundEngine] Background isolate — Kotlin will apply from prefs',
      );
    } on PlatformException catch (e) {
      debugPrint('🛑 [BackgroundEngine] PlatformException: ${e.message}');
    }

    // Always save to DB and notify UI
    await DatabaseHelper.instance.saveLastAppliedWallpaper(filePath);
    debugPrint('✅ [BackgroundEngine] Saved last wallpaper to DB.');
    _notifyHomeScreen();
  }

  // ─────────────────────────────────────────────
  //  HOME SCREEN NOTIFIER
  // ─────────────────────────────────────────────
  static void _notifyHomeScreen() {
    final port = IsolateNameServer.lookupPortByName('wapper_update_port');
    if (port != null) {
      port.send('RELOAD');
      debugPrint(
        '✅ [BackgroundEngine] Sent RELOAD signal to CollectionProvider',
      );
    } else {
      debugPrint(
        '👀 [BackgroundEngine] wapper_update_port not found — app may be in background',
      );
    }
  }

  // ─────────────────────────────────────────────
  //  GUARD: LOW BATTERY
  // ─────────────────────────────────────────────
  static bool _shouldPauseDueToLowBattery(SharedPreferences prefs) {
    final pauseEnabled = prefs.getBool(_Keys.pauseOnLowBattery) ?? true;
    if (!pauseEnabled) return false;

    final batteryLevel = prefs.getInt('current_battery_level');
    if (batteryLevel == null) return false;

    final shouldPause = batteryLevel < 20;
    if (shouldPause) {
      debugPrint('👀 [BackgroundEngine] Battery at $batteryLevel%. Pausing.');
    }
    return shouldPause;
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────
  static int _timeStringToMinutes(String timeString) {
    final parts = timeString.trim().split(' ');
    final timeParts = parts[0].split(':');
    int hours = int.parse(timeParts[0]);
    int minutes = int.parse(timeParts[1]);
    final isPM = parts[1].toUpperCase() == 'PM';
    if (isPM && hours != 12) hours += 12;
    if (!isPM && hours == 12) hours = 0;
    return (hours * 60) + minutes;
  }
}
