import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// 🚀 NEW IMPORT PATHS
import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/providers/collection_provider.dart';
import 'package:wappar/providers/schedule_switch_provider.dart';
import 'package:wappar/screens/new_automation_screen.dart';
import 'package:wappar/widgets/schedule/schedule_components.dart'; 

class PopulatedScheduleWidget extends StatelessWidget {
  const PopulatedScheduleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final providerData = context.watch<CollectionProvider>();
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    final switchProv = context.watch<ScheduleSwitchProvider>();

    // No Scaffold! Just returning the Stack.
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5.h),
            ScheduleMasterSwitchCard(switchProv: switchProv),
            SizedBox(height: 16.h),
            
            Expanded(
              child: providerData.schedules.isEmpty
                  ? const EmptyRulesState()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 26.w),
                          child: Text(
                            "Swipe left to delete a rule",
                            style: TextStyle(fontSize: 12.sp, color: wapperColors.primarytextcolor, fontWeight: FontWeight.w500),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        const Expanded(child: ScheduleRulesList()),
                      ],
                    ),
            ),
          ],
        ),
    
        Positioned(
          bottom: 15.h,
          right: 30.w,
          child: FloatingActionButton(
            onPressed: () {
              debugPrint('🚀 [PopulatedScheduleWidget] FAB Tapped: Navigating to New Automation Screen');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewAutomationScreen()),
              );
            },
            backgroundColor: wapperColors.accentcolor,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 32, color: Colors.white),
          ),
        ),
      ],
    );
  }
}