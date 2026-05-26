import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// 🚀 NEW IMPORT PATHS
import 'package:wappar/providers/collection_provider.dart';

class CollectionDetailsGrid extends StatelessWidget {
  final String collectionId; // Added to make the widget more robust

  const CollectionDetailsGrid({
    super.key,
    required this.collectionId,
  });

  @override
  Widget build(BuildContext context) {
    final providerData = context.watch<CollectionProvider>();
    final wallpapers = providerData.currentWallpapers;

    // Removed the Scaffold here! Just returning the Padding.
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 5.h, 22.w, 20.h),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,        
          crossAxisSpacing: 10.w,  
          mainAxisSpacing: 10.h,
          childAspectRatio: 0.55,  
        ),
        itemCount: wallpapers.length, 
        itemBuilder: (context, index) {
          final wallpaper = wallpapers[index];
          
          return WallpaperGridItem(
            imagePath: wallpaper['filePath'], 
            onDelete: () {
              debugPrint('🚀 [CollectionDetailsGrid] Deleting wallpaper ID: ${wallpaper['id']}');
              providerData.deleteWallpaper(wallpaper['id'], wallpaper['collectionId']);
            }, 
          );
        },
      ),
    );
  }
}

// --------------------------------------------------------
// The individual grid item
// --------------------------------------------------------

class WallpaperGridItem extends StatelessWidget {
  final String imagePath; 
  final VoidCallback onDelete;

  const WallpaperGridItem({
    super.key,
    required this.imagePath,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand, 
      children: [
        // 1. Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade800,
              child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
            ), 
          ),
        ),
        
        // 2. Delete Icon 
        Positioned(
          top: 7.h,
          right: 7.w,
          child: Material(
            color: Colors.black.withValues(alpha: 0.5),
            shape: const CircleBorder(),
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: onDelete,
              splashColor: Colors.red, 
              child: Padding(
                padding: EdgeInsets.all(6.r),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}