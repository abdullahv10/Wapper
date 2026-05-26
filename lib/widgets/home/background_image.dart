import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// 🚀 NEW IMPORT PATHS
import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/providers/collection_provider.dart';
import 'package:wappar/providers/schedule_switch_provider.dart'; // Add this!
import 'package:wappar/providers/automation_time_provider.dart'; // Add this!

class BackgroundImage extends StatefulWidget {
  const BackgroundImage({super.key});

  @override
  State<BackgroundImage> createState() => _BackgroundImageState();
}

class _BackgroundImageState extends State<BackgroundImage> {
  @override
  void initState() {
    super.initState();
    debugPrint(
      '🚀 [BackgroundImageUI] Screen mounted. Forcing UI state refresh.',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectionProvider>().updateActiveWallpaperHomeDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. WATCH ALL THREE PROVIDERS SO THE UI REACTS INSTANTLY
    final providerData = context.watch<CollectionProvider>();
    final scheduleProvider = context.watch<ScheduleSwitchProvider>();
    final automationProvider = context.watch<AutomationTimeProvider>();

    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    final currentWallpaperPath = providerData.currentWallpaperPath;

    // 2. THE FIX: ONLY SHOW TIME LEFT IF THE SCHEDULE SWITCH IS ACTUALLY ON
    final bool isScheduleOn = scheduleProvider.isScheduleEnabled;
    final String collectionTimeLeft =
        (isScheduleOn &&
            providerData.timeLeftStr.isNotEmpty &&
            providerData.timeLeftStr != "No active schedule slot")
        ? providerData.timeLeftStr
        : ""; // If the switch is off, this becomes completely empty, hiding the chip.

    // 3. WALLPAPER AUTOMATION STATUS
    final bool isTimerMode = automationProvider.isTimerMode;
    final String wallpaperInterval = automationProvider.changeInterval;
    final String wallpaperStatus = isTimerMode
        ? "Wallpaper: Every $wallpaperInterval"
        : "Wallpaper: Changes on wake";

    return Stack(
      children: [
        // --- 1. BACKGROUND WALLPAPER LAYER ---
        Positioned.fill(
          child:
              currentWallpaperPath != null &&
                  File(currentWallpaperPath).existsSync()
              ? Image.file(File(currentWallpaperPath), fit: BoxFit.cover)
              : Container(
                  color:
                      wapperColors.backgroundColor ?? const Color(0xFF0F172A),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wallpaper_rounded,
                          color: Colors.grey,
                          size: 48,
                        ),
                        SizedBox(height: 8.h),
                        const Text(
                          "No active wallpaper found.\nAdd a collection or configure a schedule.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
        ),

        // --- 2. THE UI STYLING OVERLAY ---
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.35)),
        ),

        // --- 3. DYNAMIC STATUS CHIPS ---
        if (currentWallpaperPath != null)
          Positioned(
            top: 50.h,
            right: 20.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // CHIP A: Schedule Time Left (Disappears instantly if switch is turned off)
                if (collectionTimeLeft.isNotEmpty) ...[
                  _buildStatusChip(
                    icon: Icons.hourglass_top_rounded,
                    text: collectionTimeLeft,
                    accentColor: wapperColors.accentcolor ?? Colors.blue,
                  ),
                  SizedBox(height: 8.h),
                ],

                // CHIP B: Wallpaper Change Status (Always shows current automation rule)
                _buildStatusChip(
                  icon: isTimerMode
                      ? Icons.timer_outlined
                      : Icons.screen_lock_portrait_outlined,
                  text: wallpaperStatus,
                  accentColor: Colors.tealAccent,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Helper method to keep your Stack clean
  Widget _buildStatusChip({
    required IconData icon,
    required String text,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 14.sp),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
