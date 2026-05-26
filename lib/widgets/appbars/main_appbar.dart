import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// 🚀 NEW IMPORT PATH
import 'package:wappar/core/theme/colors.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    return AppBar(
      toolbarHeight: 50.0.h, 
      backgroundColor: wapperColors.navBarBackground, 
      elevation: 0, 
      centerTitle: false, 
      title: Padding(
        padding: EdgeInsets.only(left: 10.w), 
        child: Text(
          "Wappar", // Unified brand spelling
          style: GoogleFonts.manrope(
            color: wapperColors.accentcolor, 
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