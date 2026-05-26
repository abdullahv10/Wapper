import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🚀 NEW IMPORT PATHS
import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/providers/collection_provider.dart';
import 'package:wappar/widgets/appbars/secondary_appbar.dart';
import 'package:wappar/widgets/schedule/schedule_empty_state.dart';
import 'package:wappar/widgets/schedule/populated_schedule_widget.dart';// Assuming you rename schedulegrid.dart to this

class AutomationScheduleScreen extends StatelessWidget {
  const AutomationScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final collectionData = context.watch<CollectionProvider>();
    final wapperColors = Theme.of(context).extension<WapperColors>()!;

    return Scaffold(
      backgroundColor: wapperColors.backgroundColor,
      appBar: const SecondaryAppBar(title: "Schedule"),
      
      body: !collectionData.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : collectionData.collections.isEmpty
              ? const ScheduleEmptyState()
              : const PopulatedScheduleWidget(), // Assuming this is inside schedule_grid.dart
    );
  }
}