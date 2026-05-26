import 'package:flutter/material.dart';

// --- THE EXTENSION ---
class WapperColors extends ThemeExtension<WapperColors> {
  final Color? navBarBackground;
  final Color? navactiveIcon;
  final Color? navinactiveIcon;
  final Color? secondarytextcolor;
  final Color? primarytextcolor;
  final Color? accentcolor;
  final Color? backgroundColor;
  final Color? settingtilecolor;
  final Color? halfblackwhite;
  final Color? rederror;
  final Color? tertiarytextcolor;

  WapperColors({
    required this.navBarBackground,
    required this.navactiveIcon,
    required this.navinactiveIcon,
    required this.secondarytextcolor,
    required this.primarytextcolor,
    required this.accentcolor,
    required this.backgroundColor,
    required this.settingtilecolor,
    required this.halfblackwhite,
    required this.rederror, 
    required this.tertiarytextcolor,
  });

  @override
  WapperColors copyWith({
    Color? navBarBackground,
    Color? navactiveIcon,
    Color? navinactiveIcon,
    Color? secondarytextcolor,
    Color? primarytextcolor,
    Color? accentcolor,
    Color? backgroundColor,
    Color? settingtilecolor,
    Color? halfblackwhite,
    Color? rederror,
    Color? tertiarytextcolor,
  }) {
    return WapperColors(
      navBarBackground: navBarBackground ?? this.navBarBackground,
      // 🐛 BUG FIXED: These were previously pointing to this.navBarBackground
      navactiveIcon: navactiveIcon ?? this.navactiveIcon, 
      navinactiveIcon: navinactiveIcon ?? this.navinactiveIcon, 
      secondarytextcolor: secondarytextcolor ?? this.secondarytextcolor,
      primarytextcolor: primarytextcolor ?? this.primarytextcolor,
      accentcolor: accentcolor ?? this.accentcolor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      settingtilecolor: settingtilecolor ?? this.settingtilecolor,
      halfblackwhite: halfblackwhite ?? this.halfblackwhite,
      rederror: rederror ?? this.rederror,
      tertiarytextcolor: tertiarytextcolor ?? this.tertiarytextcolor,
    );
  }

  @override
  WapperColors lerp(ThemeExtension<WapperColors>? other, double t) {
    if (other is! WapperColors) return this;
    return WapperColors(
      navBarBackground: Color.lerp(navBarBackground, other.navBarBackground, t),
      navactiveIcon: Color.lerp(navactiveIcon, other.navactiveIcon, t),
      navinactiveIcon: Color.lerp(navinactiveIcon, other.navinactiveIcon, t),
      secondarytextcolor: Color.lerp(secondarytextcolor, other.secondarytextcolor, t),
      primarytextcolor: Color.lerp(primarytextcolor, other.primarytextcolor, t),
      accentcolor: Color.lerp(accentcolor, other.accentcolor, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      settingtilecolor: Color.lerp(settingtilecolor, other.settingtilecolor, t),
      halfblackwhite: Color.lerp(halfblackwhite, other.halfblackwhite, t),
      rederror: Color.lerp(rederror, other.rederror, t),
      tertiarytextcolor: Color.lerp(tertiarytextcolor, other.tertiarytextcolor, t),
    );
  }
}

// --- THE PALETTES ---
class AppThemes {
  // Light Mode
  static final lightCustom = WapperColors(
    navBarBackground: const Color(0xFFFFFFFF),
    navactiveIcon: const Color(0xFF4F46E5),        
    navinactiveIcon: const Color(0xFF90A1B9),      
    secondarytextcolor: const Color(0xFF45556C),    
    primarytextcolor: const Color(0xFF0F172A),  
    accentcolor: const Color(0xFF0845D4),
    backgroundColor: const Color(0xFFF8FAFC),
    settingtilecolor: const Color(0xFFF1F5F9),
    halfblackwhite: const Color(0xFF000000).withValues(alpha: 0.5),
    rederror: const Color(0xFFC62828),
    tertiarytextcolor: const Color(0xFFA7A2F2),
  );

  // Dark Mode 
  static final darkCustom = WapperColors(
    navBarBackground: const Color(0xFF1E293B),
    navactiveIcon: const Color(0xFF4F46E5),        
    navinactiveIcon: const Color(0xFF90A1B9),
    secondarytextcolor: const Color(0xFF90A1B9),
    primarytextcolor: const Color(0xFFF8FAFC),
    accentcolor: const Color(0xFF0845D4),
    backgroundColor: const Color(0xFF0F172B),
    settingtilecolor: const Color(0xFF1D293D),
    halfblackwhite: const Color(0xFFFFFFFF).withValues(alpha: 0.5),
    rederror: const Color(0xFF8B0000),
    tertiarytextcolor: const Color(0xFFA7A2F2),
  );
}