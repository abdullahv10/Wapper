import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wappar/core/theme/colors.dart';

class MissingGapsTip extends StatelessWidget {
  final List<String> missingGaps;

  const MissingGapsTip({super.key, required this.missingGaps});

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    if (missingGaps.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: wapperColors.settingtilecolor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.tips_and_updates_outlined, color: wapperColors.tertiarytextcolor, size: 22.w),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                "Tip: You need to cover ${missingGaps.join(', ')} to complete your 24-hour schedule.",
                style: TextStyle(
                  color: wapperColors.tertiarytextcolor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeSelectionCard extends StatelessWidget {
  final String label;
  final String formattedTime;
  final VoidCallback onTap;

  const TimeSelectionCard({
    super.key,
    required this.label,
    required this.formattedTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: wapperColors.settingtilecolor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 16.w, color: const Color(0xFF94A3B8)),
                SizedBox(width: 8.w),
                Text(label, style: TextStyle(color: wapperColors.secondarytextcolor, fontSize: 13.sp, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              formattedTime,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: wapperColors.primarytextcolor),
            ),
          ],
        ),
      ),
    );
  }
}

class CollectionSelectionCard extends StatelessWidget {
  final Map<String, dynamic> collection;
  final bool isSelected;
  final bool isUsed;
  final String? scheduledTime;
  final VoidCallback onTap;

  const CollectionSelectionCard({
    super.key,
    required this.collection,
    required this.isSelected,
    required this.isUsed,
    this.scheduledTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    return Opacity(
      opacity: isUsed ? 0.4 : 1.0, 
      child: GestureDetector(
        onTap: () {
          if (isUsed) {
            debugPrint('🛑 [AutomationUI] Blocked selection: Collection already scheduled.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${collection['title']} is already scheduled!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: wapperColors.rederror,
              ), 
            );
          } else {
            onTap();
          }
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: wapperColors.settingtilecolor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? (wapperColors.accentcolor ?? Colors.blue) : Colors.grey.withAlpha(26),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Builder(
                  builder: (context) {
                    final imgPath = collection['image']?.toString() ?? '';
                    
                    if (imgPath.isEmpty) {
                      return Container(width: 60.w, height: 60.w, color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported, color: Colors.grey));
                    }
                    
                    return Image.file(
                      File(imgPath), 
                      width: 60.w, 
                      height: 60.w, 
                      fit: BoxFit.cover,
                      errorBuilder: (_,_,_) => Container(width: 60.w, height: 60.w, color: Colors.grey.shade300, child: const Icon(Icons.broken_image, color: Colors.grey)),
                    );
                  }
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(collection['title'], style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: wapperColors.primarytextcolor)),
                    SizedBox(height: 4.h),
                    Text(
                      isUsed ? "Scheduled: $scheduledTime" : (isSelected ? "Selected" : "Tap to select"),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isUsed ? wapperColors.secondarytextcolor : (isSelected ? wapperColors.accentcolor : wapperColors.secondarytextcolor),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: wapperColors.accentcolor ?? Colors.blue, width: 6.w),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}