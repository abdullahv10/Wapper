import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// 🚀 NEW IMPORT PATHS
import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/providers/collection_provider.dart';
import 'package:wappar/widgets/appbars/tertiary_appbar.dart'; 
import 'package:wappar/widgets/collection/collection_details_grid.dart'; // Standardized name

class CollectionDetailsScreen extends StatefulWidget {
  final String collectionId;
  final String collectionTitle;

  const CollectionDetailsScreen({
    super.key,
    required this.collectionId,
    required this.collectionTitle,
  });

  @override
  State<CollectionDetailsScreen> createState() => _CollectionDetailsScreenState();
}

class _CollectionDetailsScreenState extends State<CollectionDetailsScreen> {
  
  @override
  void initState() {
    super.initState();
    
    debugPrint('🚀 [CollectionDetailsScreen] Booting up for ID: ${widget.collectionId}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🚀 [CollectionDetailsScreen] Fetching wallpapers for collection...');
      context.read<CollectionProvider>().loadWallpapersForCollection(widget.collectionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double navBarHeight = 80.h + bottomPadding;
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    final collectionData = context.watch<CollectionProvider>();
    
    final name = collectionData.getCollectionTitle(widget.collectionId) ?? widget.collectionTitle;

    return Scaffold(
      extendBody: true,
      appBar: TertiaryAppBar(title: name), // Fixed typo
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          
          CollectionDetailsGrid(collectionId: widget.collectionId), 
          
          // Fixed Bottom Bar (Save Changes)
          Container(
            color: Colors.transparent,
            height: navBarHeight,
            padding: EdgeInsets.only(
              left: 24.w,
              right: 24.w,
              top: 16.h,
              bottom: bottomPadding + 10.h, 
            ),
            child: SizedBox(
              height: 55.h,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  debugPrint('🚀 [CollectionDetailsScreen] Save Changes tapped. Popping screen.');
                  Navigator.pop(context);
                }, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: wapperColors.accentcolor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                label: Text(
                  "Save Changes", 
                  style: GoogleFonts.manrope(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
          
          // Add Photos FAB
          Positioned(
            bottom: navBarHeight - 5, 
            right: 30.w,
            child: FloatingActionButton(
              onPressed: () async {
                debugPrint('🚀 [CollectionDetailsScreen] Add Photos FAB tapped. Opening picker...');
                await context.read<CollectionProvider>().pickAndSaveWallpapers(widget.collectionId);
              },
              backgroundColor: wapperColors.accentcolor,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ), 
          ),
        ],
      ),
    );
  } 
}