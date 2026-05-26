import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/providers/automation_time_provider.dart';
import 'package:wappar/providers/settings_provider.dart';
import 'package:wappar/widgets/appbars/secondary_appbar.dart';
import 'package:wappar/widgets/settings/settings_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final List<String> timeIntervals = const [
    '15 minutes',
    '30 minutes',
    '1 hour',
    '2 hours',
    '4 hours',
    '8 hours',
  ];

  static const MethodChannel _channel = MethodChannel(
    'com.wapper.app/wallpaper',
  );

  // The function to call the native background settings bridge
  Future<void> _fixBackgroundAutomation() async {
    try {
      await _channel.invokeMethod('openAutoStartSettings');
    } catch (e) {
      debugPrint("Could not open settings: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    final settings = context.watch<SettingsProvider>();
    final automationTimeProvider = context.watch<AutomationTimeProvider>();

    final String automationTrigger = automationTimeProvider.isTimerMode
        ? 'Time interval'
        : 'Screen awake';

    return Scaffold(
      backgroundColor: wapperColors.backgroundColor,
      appBar: const SecondaryAppBar(title: "Settings"),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── GENERAL ──────────────────────────────
            const SectionHeader(title: "GENERAL"),
            SizedBox(height: 12.h),
            MasterSwitchCard(batteryProvider: settings),

            SizedBox(height: 32.h),

            // ── WALLPAPER AUTOMATION ─────────────────
            const SectionHeader(title: "WALLPAPER AUTOMATION"),
            SizedBox(height: 12.h),
            SettingsCard(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Change wallpaper on",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: wapperColors.primarytextcolor,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: AutomationToggleButton(
                            label: "Time interval",
                            currentTrigger: automationTrigger,
                            provider: automationTimeProvider,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: AutomationToggleButton(
                            label: "Screen awake",
                            currentTrigger: automationTrigger,
                            provider: automationTimeProvider,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      automationTrigger == 'Time interval'
                          ? "Wallpaper changes every set time period"
                          : "Wallpaper changes each time screen turns off",
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: wapperColors.secondarytextcolor,
                      ),
                    ),

                    // Interval chips — timer mode only
                    if (automationTrigger == 'Time interval') ...[
                      SizedBox(height: 24.h),
                      Text(
                        "Change every",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: wapperColors.primarytextcolor,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 12.h,
                        children: timeIntervals
                            .map(
                              (time) => IntervalChip(
                                label: time,
                                provider: automationTimeProvider,
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    // ── SHUFFLE TOGGLE ───────────────
                    SizedBox(height: 24.h),
                    const Divider(),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Shuffle wallpapers",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: wapperColors.primarytextcolor,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                settings.isShuffleMode
                                    ? "Picks a random wallpaper each time"
                                    : "Cycles through wallpapers in order",
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: wapperColors.secondarytextcolor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: settings.isShuffleMode,
                          onChanged: (val) {
                            debugPrint(
                              '🚀 [SettingsUI] Shuffle mode toggled: $val',
                            );
                            settings.toggleShuffleMode(val);
                          },
                          activeColor: wapperColors.accentcolor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // ── DEVICE SETTINGS ──────────────────────────
            const SectionHeader(title: "DEVICE SETTINGS"),
            SizedBox(height: 12.h),
            SettingsCard(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Background Automation",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: wapperColors.primarytextcolor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Ensure your wallpaper continues to change automatically even when the app is completely closed.",
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: wapperColors.secondarytextcolor,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      onPressed: _fixBackgroundAutomation,
                      icon: const Icon(Icons.auto_awesome, color: Colors.white),
                      label: Text(
                        "Allow Background Magic ✨",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: wapperColors.accentcolor,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // ── STORAGE ──────────────────────────────
            const SectionHeader(title: "STORAGE"),
            SizedBox(height: 12.h),
            SettingsCard(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Clear Saved Images",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: wapperColors.primarytextcolor,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Free up 150 MB of storage",
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: wapperColors.secondarytextcolor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        debugPrint(
                          '🚀 [SettingsUI] Clear Saved Images triggered',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saved images cleared!'),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: wapperColors.accentcolor,
                        textStyle: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text("Clear"),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }
}
