import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/widgets/appbars/main_appbar.dart';
import 'package:wappar/widgets/home/background_image.dart';
import 'package:wappar/widgets/home/quick_skip_card.dart';

// 🚀 ADD THIS IMPORT: Point it to wherever your background_engine.dart lives
import 'package:wappar/services/background_engine.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Notice we completely removed the MethodChannel from this file!

  Future<void> _skipWallpaper(BuildContext context) async {
    try {
      debugPrint(
        '🚀 [HomeScreen] Manual wallpaper skip triggered via Dart BackgroundEngine',
      );

      // 🚀 THE FIX: Call your Dart engine directly!
      await BackgroundEngine.triggerWallpaperChange();

      // We don't need notifyListeners() or anything else here.
      // BackgroundEngine automatically sends the 'RELOAD' signal to CollectionProvider!
    } catch (e) {
      debugPrint("🛑 [HomeScreen] Failed to trigger next wallpaper: '$e'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;

    return Scaffold(
      appBar: const MainAppBar(),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            const BackgroundImage(),
            Center(
              child: Column(
                children: [
                  SizedBox(height: 490.h),
                  const QuickSkipCard(),
                ],
              ),
            ),
            Positioned(
              bottom: 15.h,
              right: 30.w,
              child: FloatingActionButton(
                onPressed: () => _skipWallpaper(
                  context,
                ), // 🚀 Make sure this is calling our updated method
                backgroundColor: wapperColors.accentcolor,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.play_arrow,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
