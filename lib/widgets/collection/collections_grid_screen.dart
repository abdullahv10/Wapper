import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// 🚀 NEW IMPORT PATHS
import 'package:wappar/core/theme/colors.dart'; 
import 'package:wappar/providers/collection_provider.dart';
import 'package:wappar/screens/collection_details_screen.dart'; // Standardized name

class CollectionsGridScreen extends StatelessWidget {
  const CollectionsGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final providerData = context.watch<CollectionProvider>();
    final collections = providerData.collections;
    Theme.of(context).extension<WapperColors>()!;

    // Removed the Scaffold here! Just returning the indicator.
    if (!providerData.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Removed the Scaffold here too! Just returning the Padding.
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 5.h, 22.w, 20.h),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
          childAspectRatio: 0.56,
        ),
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final item = collections[index];
          return CollectionCard(
            title: item['title'] ?? 'Untitled', 
            imagePath: item['image'] ?? '',  
            onDelete: () {
              debugPrint('🚀 [CollectionsGrid] Delete tapped for: ${item['title']}');
              providerData.deleteCollection(item['id']);
            },
            onEdit: () {
              debugPrint('🚀 [CollectionsGrid] Edit tapped for: ${item['title']}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CollectionDetailsScreen(
                    collectionId: item['id'], 
                    collectionTitle: item['title'],
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }
}

class CollectionCard extends StatelessWidget {
  final String title;
  final String imagePath; 
  final VoidCallback onDelete;
  final VoidCallback onEdit; 

  const CollectionCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    
    return Container(
      decoration: BoxDecoration(
        color: wapperColors.navBarBackground,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: imagePath.isNotEmpty
                      ? Image.file(
                          File(imagePath),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(wapperColors),
                        )
                      : _buildErrorPlaceholder(wapperColors),
                ),
                
                // Delete Button
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: onDelete,
                      splashColor: Colors.red, 
                      highlightColor: Colors.red.withValues(alpha: 0.5),
                      child: Padding(
                        padding: EdgeInsets.all(8.r),
                        child: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                
                // Edit Button
                Positioned(
                  bottom: 8.h,
                  right: 8.w,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: onEdit,
                      splashColor: wapperColors.accentcolor?.withValues(alpha: 0.5) ?? Colors.white24,
                      child: Padding(
                        padding: EdgeInsets.all(8.r),
                        child: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(6.w, 12.h, 6.w, 12.h),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: wapperColors.primarytextcolor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(WapperColors colors) {
    return Container(
      color: colors.settingtilecolor ?? Colors.grey[200],
      child: Center(
        child: Icon(Icons.image_not_supported, color: colors.secondarytextcolor),
      ),
    );
  }
}