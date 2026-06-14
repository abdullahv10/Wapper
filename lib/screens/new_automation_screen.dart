import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// 🚀 NEW IMPORT PATHS
import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/providers/collection_provider.dart';
import 'package:wappar/widgets/appbars/tertiary_appbar.dart'; // Fixed typo in import
import 'package:wappar/widgets/schedule/automation_components.dart';

class NewAutomationScreen extends StatefulWidget {
  const NewAutomationScreen({super.key});

  @override
  State<NewAutomationScreen> createState() => _NewAutomationScreenState();
}

class _NewAutomationScreenState extends State<NewAutomationScreen> {
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 16, minute: 0);
  String? selectedCollectionId;

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hourStr = hour.toString().padLeft(2, '0');
    return '$hourStr:$minute $period';
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    debugPrint(
      '🚀 [NewAutomationScreen] Opening time picker for ${isStart ? "Start" : "End"} time',
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          // We use copyWith to keep your app's default fonts,
          // but we overwrite the colors with a generated blue scheme.
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              // This ensures the picker matches if the user's phone is in Dark Mode
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
          debugPrint(
            '✅ [NewAutomationScreen] Start time updated to: ${_formatTime(picked)}',
          );
        } else {
          endTime = picked;
          debugPrint(
            '✅ [NewAutomationScreen] End time updated to: ${_formatTime(picked)}',
          );
        }
      });
    }
  }

  void _saveAutomation() async {
    debugPrint('🚀 [NewAutomationScreen] Save automation triggered');
    final wapperColors = Theme.of(context).extension<WapperColors>()!;

    if (selectedCollectionId == null) {
      debugPrint(
        '🛑 [NewAutomationScreen] Save failed: No collection selected.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a collection first!',
            style: TextStyle(
              color: wapperColors.primarytextcolor,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: wapperColors.rederror,
        ),
      );
      return;
    }

    final timeRange = '${_formatTime(startTime)} - ${_formatTime(endTime)}';
    debugPrint(
      '👀 [NewAutomationScreen] Attempting to save rule: ID $selectedCollectionId at $timeRange',
    );

    final errorMessage = await context.read<CollectionProvider>().tryAddRule(
      selectedCollectionId!,
      timeRange,
    );

    if (!mounted) return;

    if (errorMessage != null) {
      debugPrint(
        '🛑 [NewAutomationScreen] Rule rejected by provider: $errorMessage',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: wapperColors.rederror,
        ),
      );
      return;
    }

    debugPrint(
      '✅ [NewAutomationScreen] Rule successfully saved. Popping screen.',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final providerData = context.watch<CollectionProvider>();
    final wapperColors = Theme.of(context).extension<WapperColors>()!;

    final missingGaps = providerData.getMissingTimeGaps();

    return Scaffold(
      backgroundColor: wapperColors.backgroundColor,
      appBar: const TertiaryAppBar(
        title: "Automation",
      ), // Updated to match fixed file name
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),

                    MissingGapsTip(missingGaps: missingGaps),

                    Text(
                      "Time Range",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: wapperColors.primarytextcolor,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: TimeSelectionCard(
                            label: "Start",
                            formattedTime: _formatTime(startTime),
                            onTap: () => _selectTime(context, true),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: TimeSelectionCard(
                            label: "End",
                            formattedTime: _formatTime(endTime),
                            onTap: () => _selectTime(context, false),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 32.h),
                    Text(
                      "Select Collection",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: wapperColors.primarytextcolor,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    ...providerData.collections.map((collection) {
                      final isSelected =
                          selectedCollectionId == collection['id'];
                      final scheduledTime = providerData
                          .getScheduledTimeForCollection(collection['id']);
                      final isUsed = scheduledTime != null;

                      return CollectionSelectionCard(
                        collection: collection,
                        isSelected: isSelected,
                        isUsed: isUsed,
                        scheduledTime: scheduledTime,
                        onTap: () {
                          debugPrint(
                            '🚀 [NewAutomationScreen] Collection tapped: ${collection['title']}',
                          );
                          setState(() {
                            selectedCollectionId = collection['id'];
                          });
                        },
                      );
                    }),

                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton.icon(
            onPressed: _saveAutomation,
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            label: Text(
              "Save Automation",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: wapperColors.accentcolor ?? Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }
}
