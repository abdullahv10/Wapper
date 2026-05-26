import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

// Local database helper import
import '../data/local/database_helper.dart';

class CollectionProvider extends ChangeNotifier {
  // ==========================================
  // --- CHANNEL & SIGNAL CONFIG ---
  // ==========================================
  static const MethodChannel _channel = MethodChannel(
    'com.wapper.app/wallpaper',
  );

  // ==========================================
  // --- STATE VARIABLES ---
  // ==========================================
  List<Map<String, dynamic>> collections = [];
  List<Map<String, dynamic>> schedules = [];
  bool isScheduleEnabled = true;
  bool isInitialized = false;
  String? _currentWallpaperPath;
  String _timeLeftStr = "";

  String? get currentWallpaperPath => _currentWallpaperPath;
  String get timeLeftStr => _timeLeftStr;

  final ReceivePort _port = ReceivePort();
  Timer? _ticker;

  // ==========================================
  // --- SETUP & TEARDOWN ---
  // ==========================================
  CollectionProvider() {
    debugPrint('🚀 [CollectionProvider] Booting up and loading data...');
    _initializeChannelListener();
    loadData();
    updateActiveWallpaperHomeDetails();

    try {
      IsolateNameServer.removePortNameMapping('wapper_update_port');
      IsolateNameServer.registerPortWithName(
        _port.sendPort,
        'wapper_update_port',
      );
      debugPrint(
        '✅ [CollectionProvider] Ghost Walkie-Talkie port registered successfully',
      );

      _port.listen((dynamic data) {
        if (data == 'RELOAD') {
          debugPrint(
            "🚨 [CollectionProvider] GHOST SIGNAL RECEIVED: Refreshing screen instantly.",
          );
          updateActiveWallpaperHomeDetails();
        }
      });
    } catch (e) {
      debugPrint('🛑 [CollectionProvider] ERROR setting up Isolate port: $e');
    }

    // Physical clock to tick time down
    _ticker = Timer.periodic(const Duration(minutes: 1), (timer) {
      updateActiveWallpaperHomeDetails();
    });
  }

  @override
  void dispose() {
    debugPrint('🛑 [CollectionProvider] Disposing and cleaning up ports...');
    IsolateNameServer.removePortNameMapping('wapper_update_port');
    _port.close();
    _ticker?.cancel();
    super.dispose();
  }

  // ==========================================
  // --- NATIVE INTERACTION LISTENER ---
  // ==========================================
  void _initializeChannelListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWallpaperChanged') {
        final String newPath = call.arguments as String;
        debugPrint(
          "📱 [CollectionProvider] MethodChannel 'onWallpaperChanged' triggered by Native Service: $newPath",
        );

        _currentWallpaperPath = newPath;

        try {
          // Persist back to DB via your helper
          await DatabaseHelper.instance.saveLastAppliedWallpaper(newPath);
        } catch (e) {
          debugPrint(
            "🛑 [CollectionProvider] Failed to save last applied wallpaper to DB: $e",
          );
        }

        // Instantly force-recalculate schedule slots and notify the BackgroundImage layout
        await updateActiveWallpaperHomeDetails();
      }
    });
  }

  // ==========================================
  // --- CORE DATA OPERATIONS ---
  // ==========================================
  Future<void> loadData() async {
    debugPrint('🚀 [CollectionProvider] Fetching DB data...');
    try {
      collections = await DatabaseHelper.instance.fetchCollections();
      schedules = await DatabaseHelper.instance.fetchSchedules();
      _validateMasterSwitch();
      isInitialized = true;
      notifyListeners();
      debugPrint(
        '✅ [CollectionProvider] Data loaded: ${collections.length} collections, ${schedules.length} schedules',
      );
    } catch (e) {
      debugPrint('🛑 [CollectionProvider] ERROR loading data: $e');
    }
  }

  Future<void> addCollection(
    String title,
    String imagePath,
    bool active,
  ) async {
    debugPrint('🚀 [CollectionProvider] Adding new collection: $title');
    await DatabaseHelper.instance.insertCollection({
      'id': 'c_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'image': imagePath,
      'active': active,
    });
    await loadData();
  }

  Future<void> deleteCollection(String id) async {
    debugPrint('🚀 [CollectionProvider] Deleting collection: $id');
    await DatabaseHelper.instance.deleteCollection(id);
    await loadData();
  }

  // ==========================================
  // --- BATCH & WALLPAPER MANAGEMENT ---
  // ==========================================
  List<Map<String, dynamic>> currentWallpapers = [];

  Future<void> loadWallpapersForCollection(String collectionId) async {
    debugPrint(
      '🚀 [CollectionProvider] Loading wallpapers for collection: $collectionId',
    );
    currentWallpapers = await DatabaseHelper.instance.fetchWallpapers(
      collectionId,
    );
    notifyListeners();
  }

  Future<void> pickAndSaveWallpapers(String collectionId) async {
    debugPrint('🚀 [CollectionProvider] Opening Image Picker...');
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isEmpty) {
      debugPrint('👀 [CollectionProvider] No images selected. Aborting.');
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    int uniqueCounter = 0;

    for (var file in pickedFiles) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${uniqueCounter}_${file.name}';
      final savedImagePath = '${directory.path}/$fileName';

      final newFile = await File(file.path).copy(savedImagePath);

      await DatabaseHelper.instance.insertWallpaper({
        'id': 'w_${timestamp}_$uniqueCounter',
        'collectionId': collectionId,
        'filePath': newFile.path,
      });

      uniqueCounter++;
    }
    debugPrint('✅ [CollectionProvider] Saved $uniqueCounter new wallpapers.');
    await loadWallpapersForCollection(collectionId);
  }

  Future<void> deleteWallpaper(String wallpaperId, String collectionId) async {
    debugPrint('🚀 [CollectionProvider] Deleting wallpaper: $wallpaperId');
    await DatabaseHelper.instance.deleteWallpaper(wallpaperId);
    await loadWallpapersForCollection(collectionId);
  }

  Future<void> createCollectionWithWallpapers(
    String title,
    String coverPath,
    List<String> wallpaperPaths,
  ) async {
    debugPrint(
      '🚀 [CollectionProvider] Batch creating collection with ${wallpaperPaths.length} wallpapers...',
    );
    final newColId = 'c_${DateTime.now().millisecondsSinceEpoch}';
    final directory = await getApplicationDocumentsDirectory();

    // 1. Copy the Cover Photo
    final coverExt = coverPath.split('.').last;
    final savedCoverPath = '${directory.path}/cover_$newColId.$coverExt';
    await File(coverPath).copy(savedCoverPath);

    // 2. Save Collection to DB
    await DatabaseHelper.instance.insertCollection({
      'id': newColId,
      'title': title,
      'image': savedCoverPath,
      'active': true,
    });

    // 3. Copy wallpapers safely using a counter loop
    int uniqueCounter = 0;
    for (var path in wallpaperPaths) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${uniqueCounter}_${path.split('/').last}';
      final savedWallPath = '${directory.path}/$fileName';

      await File(path).copy(savedWallPath);
      await DatabaseHelper.instance.insertWallpaper({
        'id': 'w_${timestamp}_$uniqueCounter',
        'collectionId': newColId,
        'filePath': savedWallPath,
      });
      uniqueCounter++;
    }

    debugPrint('✅ [CollectionProvider] Batch creation complete.');
    await loadData();
  }

  Future<void> updateActiveWallpaperHomeDetails() async {
    debugPrint("🚀 [CollectionProvider] Re-calculating Home Screen UI Data...");
    _currentWallpaperPath = await DatabaseHelper.instance
        .getLastAppliedWallpaper();

    if (schedules.isEmpty) {
      _timeLeftStr = "";
      debugPrint("👀 [CollectionProvider] Schedules empty. Time left cleared.");
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final currentMinutes = (now.hour * 60) + now.minute;
    Map<String, dynamic>? activeRule;

    for (var rule in schedules) {
      final times = (rule['timeRange'] as String).split(' - ');
      final startMins = _timeToMinutes(times[0]);
      final endMins = _timeToMinutes(times[1]);

      bool isMatch = false;
      if (endMins <= startMins) {
        isMatch =
            (currentMinutes >= startMins && currentMinutes < 1440) ||
            (currentMinutes >= 0 && currentMinutes < endMins);
      } else {
        isMatch = currentMinutes >= startMins && currentMinutes < endMins;
      }

      if (isMatch) {
        activeRule = rule;
        break;
      }
    }

    if (activeRule != null) {
      final times = (activeRule['timeRange'] as String).split(' - ');
      final endMins = _timeToMinutes(times[1]);
      int remainingMinutes = endMins <= currentMinutes
          ? (1440 - currentMinutes) + endMins
          : endMins - currentMinutes;

      final hoursLeft = remainingMinutes ~/ 60;
      final minsLeft = remainingMinutes % 60;

      _timeLeftStr = hoursLeft > 0
          ? "${hoursLeft}h ${minsLeft}m left"
          : "$minsLeft min left";
    } else {
      _timeLeftStr = "No active schedule slot";
    }

    debugPrint("✅ [CollectionProvider] Calculation complete: $_timeLeftStr");
    notifyListeners();
  }

  // ==========================================
  // --- SCHEDULE LOGIC & MATH ---
  // ==========================================
  Future<String?> tryAddRule(String collectionId, String timeRange) async {
    debugPrint('🚀 [CollectionProvider] Attempting to add rule: $timeRange');
    final newIntervals = _getIntervals(timeRange);

    for (var rule in schedules) {
      final existingIntervals = _getIntervals(rule['timeRange']);
      for (var newInt in newIntervals) {
        for (var existInt in existingIntervals) {
          if (newInt[0] < existInt[1] && newInt[1] > existInt[0]) {
            final crashedCollection = getCollectionForSchedule(
              rule['collectionId'],
            );
            final title = crashedCollection != null
                ? crashedCollection['title']
                : 'another rule';
            debugPrint('🛑 [CollectionProvider] Rule overlaps with $title');
            return "This overlaps with $title (${rule['timeRange']})";
          }
        }
      }
    }

    await DatabaseHelper.instance.insertSchedule({
      'id': 's_${DateTime.now().millisecondsSinceEpoch}',
      'collectionId': collectionId,
      'timeRange': timeRange,
    });
    debugPrint('✅ [CollectionProvider] Rule added successfully.');
    await loadData();
    return null;
  }

  Future<void> deleteRule(String ruleId) async {
    debugPrint('🚀 [CollectionProvider] Deleting rule: $ruleId');
    await DatabaseHelper.instance.deleteSchedule(ruleId);
    await loadData();
  }

  Map<String, dynamic>? getCollectionForSchedule(String collectionId) {
    try {
      return collections.firstWhere((c) => c['id'] == collectionId);
    } catch (e) {
      return null;
    }
  }

  String? getCollectionTitle(String collectionId) {
    final collection = getCollectionForSchedule(collectionId);
    return collection != null ? collection['title'] : null;
  }

  String? getScheduledTimeForCollection(String collectionId) {
    try {
      final rule = schedules.firstWhere(
        (r) => r['collectionId'] == collectionId,
      );
      return rule['timeRange'];
    } catch (e) {
      return null;
    }
  }

  List<List<int>> _getIntervals(String timeRange) {
    final times = timeRange.split(' - ');
    int start = _timeToMinutes(times[0]);
    int end = _timeToMinutes(times[1]);
    if (end <= start)
      return [
        [start, 1440],
        [0, end],
      ];
    return [
      [start, end],
    ];
  }

  void _validateMasterSwitch() {
    if (!isScheduleEnabled) return;
    if (collections.isEmpty ||
        schedules.isEmpty ||
        getMissingTimeGaps().isNotEmpty) {
      isScheduleEnabled = false;
      debugPrint(
        '👀 [CollectionProvider] Master switch auto-disabled due to invalid state.',
      );
    }
  }

  int _timeToMinutes(String timeString) {
    final parts = timeString.trim().split(' ');
    final timeParts = parts[0].split(':');
    int hours = int.parse(timeParts[0]);
    int minutes = int.parse(timeParts[1]);
    final isPM = parts[1] == 'PM';
    if (isPM && hours != 12) hours += 12;
    if (!isPM && hours == 12) hours = 0;
    return (hours * 60) + minutes;
  }

  String _minutesToTime(int minutes) {
    if (minutes == 1440 || minutes == 0) return "12:00 AM";

    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    String period = hours >= 12 ? 'PM' : 'AM';

    int displayHour = hours % 12;
    if (displayHour == 0) displayHour = 12;

    String hh = displayHour.toString().padLeft(2, '0');
    String mm = mins.toString().padLeft(2, '0');

    return '$hh:$mm $period';
  }

  List<String> getMissingTimeGaps() {
    if (schedules.isEmpty) return ["12:00 AM - 12:00 AM (Full Day)"];

    List<List<int>> intervals = [];
    for (var rule in schedules) {
      intervals.addAll(_getIntervals(rule['timeRange']));
    }

    intervals.sort((a, b) => a[0].compareTo(b[0]));
    List<List<int>> merged = [intervals.first];

    for (int i = 1; i < intervals.length; i++) {
      int currentStart = intervals[i][0];
      int currentEnd = intervals[i][1];
      int lastMergedEnd = merged.last[1];

      if (currentStart <= lastMergedEnd) {
        merged.last[1] = currentEnd > lastMergedEnd
            ? currentEnd
            : lastMergedEnd;
      } else {
        merged.add([currentStart, currentEnd]);
      }
    }

    List<String> missingGaps = [];

    if (merged.first[0] > 0) {
      missingGaps.add(
        '${_minutesToTime(0)} to ${_minutesToTime(merged.first[0])}',
      );
    }

    for (int i = 0; i < merged.length - 1; i++) {
      int gapStart = merged[i][1];
      int gapEnd = merged[i + 1][0];
      missingGaps.add(
        '${_minutesToTime(gapStart)} to ${_minutesToTime(gapEnd)}',
      );
    }

    if (merged.last[1] < 1440) {
      missingGaps.add(
        '${_minutesToTime(merged.last[1])} to ${_minutesToTime(1440)}',
      );
    }

    return missingGaps;
  }
}
