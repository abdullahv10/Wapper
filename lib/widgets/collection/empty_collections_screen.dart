import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wappar/core/theme/colors.dart'; // 🚀 NEW IMPORT PATH

class EmptyCollectionsScreen extends StatelessWidget {
  const EmptyCollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    // Removed the Scaffold wrapper!
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w), // ScreenUtil added
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 100.w, // ScreenUtil added
              color: wapperColors.secondarytextcolor,
            ),
            SizedBox(height: 10.h),
            Text(
              'You haven\'t created any collections yet. Tap + to start.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp, // ScreenUtil added
                color: wapperColors.secondarytextcolor,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}