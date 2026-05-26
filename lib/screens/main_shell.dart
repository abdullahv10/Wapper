import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_symbols_icons/symbols.dart';

// 🚀 NEW IMPORT PATHS
import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/widgets/common/custom_nav_item.dart';

// Screen Imports
import 'package:wappar/screens/home_screen.dart';
import 'package:wappar/screens/collections_screen.dart';
import 'package:wappar/screens/schedule_screen.dart';
import 'package:wappar/screens/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    CollectionsScreen(),
    AutomationScheduleScreen(), // Assuming this is the class name in schedule_screen.dart
    SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    debugPrint('🚀 [MainShell] Navigating to tab index: $index');
    setState(() {
      _currentIndex = index;
    });
  }  

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double navBarHeight = 60.h + bottomPadding; 

    return Scaffold(
      backgroundColor: wapperColors.navBarBackground,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        height: navBarHeight, 
        decoration: BoxDecoration(
          color: wapperColors.navBarBackground,
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CustomNavItem(
                    icon: Symbols.home,
                    label: 'Home',
                    index: 0,
                    currentIndex: _currentIndex,
                    activeColor: wapperColors.navactiveIcon!,
                    inactiveColor: wapperColors.navinactiveIcon!,
                    onTap: () => _onTabTapped(0),
                  ),
                  CustomNavItem(
                    icon: Symbols.folder_rounded,
                    label: 'Collections',
                    index: 1,
                    currentIndex: _currentIndex,
                    activeColor: wapperColors.navactiveIcon!,
                    inactiveColor: wapperColors.navinactiveIcon!,
                    onTap: () => _onTabTapped(1),
                  ),
                  CustomNavItem(
                    icon: Symbols.schedule_rounded,
                    label: 'Schedule',
                    index: 2,
                    currentIndex: _currentIndex,
                    activeColor: wapperColors.navactiveIcon!,
                    inactiveColor: wapperColors.navinactiveIcon!,
                    onTap: () => _onTabTapped(2),
                  ),
                  CustomNavItem(
                    icon: Symbols.settings_rounded,
                    label: 'Settings',
                    index: 3,
                    currentIndex: _currentIndex,
                    activeColor: wapperColors.navactiveIcon!,
                    inactiveColor: wapperColors.navinactiveIcon!,
                    onTap: () => _onTabTapped(3),
                  ),
                ],
              ),
            ),
            SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }
}