import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 🚀 NEW IMPORT PATH
import 'package:wappar/core/theme/colors.dart';

class CoverPhotoHeader extends StatelessWidget {
  final String? coverPhotoPath;
  final VoidCallback onTap;

  const CoverPhotoHeader({
    super.key,
    required this.coverPhotoPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 280.h,
        decoration: BoxDecoration(
          color: wapperColors.settingtilecolor, 
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          image: coverPhotoPath != null
              ? DecorationImage(
                  image: FileImage(File(coverPhotoPath!)), 
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: wapperColors.accentcolor, 
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(
                coverPhotoPath != null ? Icons.edit : Icons.camera_alt_outlined, 
                color: Colors.white, 
                size: 30.sp
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              coverPhotoPath != null ? "Tap to change cover photo" : "Tap to upload cover photo",
              style: GoogleFonts.manrope(
                color: coverPhotoPath != null ? Colors.white : wapperColors.primarytextcolor,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CollectionNameField extends StatelessWidget {
  final TextEditingController controller;

  const CollectionNameField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Collection Name", style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14.sp, color: wapperColors.primarytextcolor)),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: wapperColors.settingtilecolor, 
            hintText: "e.g., Synthwave Nights",
            hintStyle: GoogleFonts.manrope(color: wapperColors.secondarytextcolor, fontSize: 14.sp),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: wapperColors.secondarytextcolor ?? Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: wapperColors.secondarytextcolor ?? Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: wapperColors.accentcolor ?? Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}

class PhotoSelectionArea extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onAddPhotos;

  const PhotoSelectionArea({
    super.key,
    required this.selectedCount,
    required this.onAddPhotos,
  });

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Photos", style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14.sp)),
            Text("$selectedCount selected", style: GoogleFonts.manrope(color: wapperColors.secondarytextcolor, fontSize: 12.sp)),
          ],
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: onAddPhotos,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 24.h),
            decoration: BoxDecoration(
              color: wapperColors.settingtilecolor, 
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: wapperColors.secondarytextcolor ?? Colors.grey, width: 2), 
            ),
            child: Column(
              children: [
                Icon(Icons.add, color: wapperColors.secondarytextcolor, size: 28.sp),
                SizedBox(height: 8.h),
                Text("Add Photos", style: GoogleFonts.manrope(color: wapperColors.secondarytextcolor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}