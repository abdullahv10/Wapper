import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🚀 NEW IMPORT PATH
import 'package:wappar/core/theme/colors.dart';

class QuickSkipCard extends StatefulWidget {
  const QuickSkipCard({super.key});

  @override
  State<QuickSkipCard> createState() => _QuickSkipCardState();
}

class _QuickSkipCardState extends State<QuickSkipCard> {
  late Future<bool> _isDismissedFuture;
  static const String _dismissedPrefKey = 'quickSkipDismissed';

  @override
  void initState() {
    super.initState();
    _isDismissedFuture = _checkDismissedStatus();
  }

  Future<bool> _checkDismissedStatus() async {
    debugPrint('🚀 [QuickSkipCard] Checking UI dismissal status from storage...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDismissed = prefs.getBool(_dismissedPrefKey) ?? false;
      debugPrint('👀 [QuickSkipCard] Status result: $isDismissed');
      return isDismissed;
    } catch (e) {
      debugPrint('🛑 [QuickSkipCard] ERROR reading storage: $e');
      return false; // Default to showing it if storage fails
    }
  }

  Future<void> _dismissCardPermanently() async {
    debugPrint('🚀 [QuickSkipCard] Dismiss button tapped. Saving to storage...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dismissedPrefKey, true); 
      
      setState(() {
        _isDismissedFuture = Future.value(true); 
      });
      debugPrint('✅ [QuickSkipCard] Card permanently dismissed and hidden.');
    } catch (e) {
      debugPrint('🛑 [QuickSkipCard] ERROR saving dismissal to storage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isDismissedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(width: 320.w); 
        }

        if (snapshot.data == true) {
          return const SizedBox.shrink(); 
        }

        return _buildSuggestionCard();
      },
    );
  }

  Widget _buildSuggestionCard() {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    return Center(
      child: SizedBox(
        width: 320.w, 
        child: Card(
          color: wapperColors.navBarBackground, 
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Skip Widget',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: wapperColors.primarytextcolor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: wapperColors.secondarytextcolor),
                      onPressed: _dismissCardPermanently, 
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                SizedBox(
                  width: 230.w,
                  child: Text(
                    'Long-press your home screen and select Widgets to add the skip shortcut for instant background refreshes.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: wapperColors.secondarytextcolor,
                      wordSpacing: -0.9,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}