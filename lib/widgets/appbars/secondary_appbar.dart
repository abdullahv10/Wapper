import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// 🚀 NEW IMPORT PATH
import 'package:wappar/core/theme/colors.dart';

class SecondaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  
  const SecondaryAppBar({
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
      title: Padding(
        padding: EdgeInsets.only(left: 10.w), // Swapped Container for a clean Padding widget
        child: Text(
          title,
          style: GoogleFonts.manrope(
            color: wapperColors.primarytextcolor, 
            fontWeight: FontWeight.w800,
            fontSize: 30.sp, 
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(50.0.h); 
}