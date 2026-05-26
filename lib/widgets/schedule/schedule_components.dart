import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

// 🚀 NEW IMPORT PATHS
import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/providers/collection_provider.dart';
import 'package:wappar/providers/schedule_switch_provider.dart';

class ScheduleMasterSwitchCard extends StatelessWidget {
  final ScheduleSwitchProvider switchProv;

  const ScheduleMasterSwitchCard({super.key, required this.switchProv});

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    final providerData = context.read<CollectionProvider>();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: wapperColors.settingtilecolor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Enable Schedule", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: wapperColors.primarytextcolor)),
                  SizedBox(height: 4.h),
                  Text("Automate wallpaper changes throughout the day", style: TextStyle(fontSize: 13.sp, color: wapperColors.secondarytextcolor, height: 1.4)),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Switch(
              value: switchProv.isScheduleEnabled,
              onChanged: (value) {
                debugPrint('🚀 [ScheduleUI] Master switch toggled to: $value');
                if (value == true) {
                  final errorMessage = switchProv.tryEnableSchedule(providerData);
                  if (errorMessage != null) {
                    debugPrint('🛑 [ScheduleUI] Enable failed: $errorMessage');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        backgroundColor: wapperColors.rederror,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        margin: EdgeInsets.only(bottom: 20.h, left: 20.w, right: 20.w),
                        duration: const Duration(seconds: 4), 
                      ),
                    );
                  }
                } else {
                  switchProv.disableSchedule();
                }
              },
              activeTrackColor: wapperColors.accentcolor,
              activeThumbColor: Colors.white,
              inactiveThumbColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleRulesList extends StatelessWidget {
  const ScheduleRulesList({super.key});

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    final providerData = context.watch<CollectionProvider>();
    final switchProv = context.read<ScheduleSwitchProvider>();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 22.w),
      itemCount: providerData.schedules.length,
      itemBuilder: (context, index) {
        final rule = providerData.schedules[index];
        final linkedCollection = providerData.getCollectionForSchedule(rule['collectionId']);
        
        if (linkedCollection == null) return const SizedBox.shrink();

        return Dismissible(
          key: Key(rule['id']),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.only(right: 24.w),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(color: wapperColors.rederror, borderRadius: BorderRadius.circular(20.r)),
            child: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 32),
          ),
          onDismissed: (direction) {
            debugPrint('🚀 [ScheduleUI] Swipe-to-delete triggered for rule: ${rule['id']}');
            providerData.deleteRule(rule['id']);
            switchProv.validateSwitchState(providerData);
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: wapperColors.settingtilecolor,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.file(
                    File(linkedCollection['image']), 
                    width: 56.w, 
                    height: 56.w, 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 56.w,
                      height: 56.w,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rule['timeRange'], style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: wapperColors.primarytextcolor)),
                      SizedBox(height: 4.h),
                      Text(linkedCollection['title'], style: TextStyle(color: wapperColors.secondarytextcolor, fontSize: 13.sp, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class EmptyRulesState extends StatelessWidget {
  const EmptyRulesState({super.key});

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.schedule_rounded, size: 80.w, color: wapperColors.secondarytextcolor?.withValues(alpha: 0.5)),
            SizedBox(height: 20.h),
            Text(
              "No automation rules set. Tap + to\nschedule your wallpapers.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, color: wapperColors.secondarytextcolor, height: 1.5),
            ),
            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }
}