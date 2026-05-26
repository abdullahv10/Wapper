import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/providers/automation_time_provider.dart';
import 'package:wappar/providers/settings_provider.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: wapperColors.primarytextcolor, 
        ),
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final Widget child;
  const SettingsCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: wapperColors.settingtilecolor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class AutomationToggleButton extends StatelessWidget {
  final String label;
  final String currentTrigger;
  final AutomationTimeProvider provider;

  const AutomationToggleButton({
    super.key,
    required this.label,
    required this.currentTrigger,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    final isSelected = currentTrigger == label;
    
    return GestureDetector(
      onTap: () {
        debugPrint('🚀 [SettingsUI] Toggle button tapped: $label');
        bool isTimeInterval = (label == 'Time interval');
        provider.toggleSwitch(isTimeInterval);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected ? wapperColors.accentcolor : wapperColors.settingtilecolor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : wapperColors.primarytextcolor,
          ),
        ),
      ),
    );
  }
}

class IntervalChip extends StatelessWidget {
  final String label;
  final AutomationTimeProvider provider;

  const IntervalChip({
    super.key,
    required this.label,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    final isSelected = provider.changeInterval == label; 
    
    return GestureDetector(
      onTap: () {
        debugPrint('🚀 [SettingsUI] Interval chip tapped: $label');
        provider.setInterval(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? wapperColors.accentcolor : wapperColors.settingtilecolor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : wapperColors.primarytextcolor,
          ),
        ),
      ),
    );
  }
}

class MasterSwitchCard extends StatelessWidget {
  final SettingsProvider batteryProvider;

  const MasterSwitchCard({
    super.key,
    required this.batteryProvider,
  });

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: wapperColors.settingtilecolor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Pause on low battery", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: wapperColors.primarytextcolor)),
                SizedBox(height: 4.h),
                Text("Stop changing wallpapers when battery is below 20%", style: TextStyle(fontSize: 13.sp, color: wapperColors.secondarytextcolor, height: 1.4)),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Switch(
            value: batteryProvider.pauseOnLowBattery,
            onChanged: (value) {
              debugPrint('🚀 [SettingsUI] Battery switch toggled: $value');
              batteryProvider.toggleSwitch(value);
            },
            activeTrackColor: wapperColors.accentcolor,
            activeThumbColor: Colors.white,
            inactiveThumbColor: Colors.white,
          ),
        ],
      )
    );  
  }
}