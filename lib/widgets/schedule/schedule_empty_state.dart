import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 🚀 NEW IMPORT PATHS
import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/screens/create_collection_screen.dart'; 

class ScheduleEmptyState extends StatelessWidget {
  const ScheduleEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 100.w, color: wapperColors.secondarytextcolor),
            SizedBox(height: 10.h),
            Text(
              "No Collections Available",
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w700, color: wapperColors.secondarytextcolor),
            ),
            SizedBox(height: 12.h),
            Text(
              "To create an automation schedule, you need at least one wallpaper collection first.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, color: wapperColors.secondarytextcolor, height: 1.5),
            ),
            SizedBox(height: 32.h),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  debugPrint('🚀 [ScheduleEmptyState] Navigating to Create Collection Screen');
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateCollectionScreen()));
                },
                label: Text("Create New Collection", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: wapperColors.accentcolor,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}