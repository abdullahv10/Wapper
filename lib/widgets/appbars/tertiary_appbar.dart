import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// 🚀 NEW IMPORT PATH
import 'package:wappar/core/theme/colors.dart';

class TertiaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const TertiaryAppBar({
    super.key, 
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    return AppBar(
      toolbarHeight: 50.0.h, 
      backgroundColor: wapperColors.backgroundColor, 
      elevation: 0, 
      centerTitle: false, 
      titleSpacing: 0, 
      leading: Padding(
        padding: EdgeInsets.only(left: 16.0.w, top: 8.0.h, bottom: 8.0.h, right: 12.0.w),
        child: GestureDetector(
          onTap: () {
            debugPrint('🚀 [TertiaryAppBar] Back button tapped. Popping navigation stack.');
            Navigator.pop(context);
          }, 
          child: Container(
            decoration: BoxDecoration(
              color: wapperColors.halfblackwhite,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: wapperColors.primarytextcolor,
              size: 18.r, // Added .r for uniform scaling
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          color: wapperColors.primarytextcolor, 
          fontWeight: FontWeight.w800,
          fontSize: 24.sp, 
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(50.0.h); 
}