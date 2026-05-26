import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/providers/automation_time_provider.dart';
import 'package:wappar/providers/schedule_switch_provider.dart';
import 'package:wappar/providers/settings_provider.dart';
import 'package:wappar/providers/collection_provider.dart';
import 'package:wappar/screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀 [main.dart] App Boot Sequence Started');

  // 1. Create the single instance
  final settingsProvider = SettingsProvider();

  // 2. Trigger the auto-heal on that specific instance
  settingsProvider.ensureBackgroundServiceIsRunning();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            debugPrint('🚀 [main.dart] Initializing CollectionProvider');
            return CollectionProvider()..loadData();
          },
        ),
        ChangeNotifierProvider(create: (_) => ScheduleSwitchProvider()),

        // 3. Connect the instance we created above
        ChangeNotifierProvider.value(value: settingsProvider),

        ChangeNotifierProvider(create: (_) => AutomationTimeProvider()),
      ],
      child: const WapperApp(),
    ),
  );
}

class WapperApp extends StatelessWidget {
  const WapperApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🚀 [main.dart] Building WapperApp Root Widget');

    return ScreenUtilInit(
      designSize: const Size(351, 788),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Wappar',
          themeMode: ThemeMode.system,
          theme: ThemeData(
            brightness: Brightness.light,
            extensions: [AppThemes.lightCustom],
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            extensions: [AppThemes.darkCustom],
          ),
          home: child,
        );
      },
      child: const MainShell(),
    );
  }
}
