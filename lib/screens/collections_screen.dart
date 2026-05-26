import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// 🚀 NEW IMPORT PATHS
import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/providers/collection_provider.dart';
import 'package:wappar/screens/create_collection_screen.dart'; // Fixed the typo in your original file name!
import 'package:wappar/widgets/appbars/secondary_appbar.dart';

// Assuming you moved these two to the new widgets folder:
import 'package:wappar/widgets/collection/empty_collections_screen.dart'; 
import 'package:wappar/widgets/collection/collections_grid_screen.dart'; 

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    final collectionData = context.watch<CollectionProvider>();

    return Scaffold(
      backgroundColor: wapperColors.backgroundColor, // Moved from the deleted Container
      appBar: const SecondaryAppBar(title: "Collections"),
      body: Stack(
        children: [
          if (collectionData.collections.isEmpty)
            const EmptyCollectionsScreen()
          else
            const CollectionsGridScreen(),
            
          Positioned(
            bottom: 15.h,
            right: 30.w,
            child: FloatingActionButton(
              onPressed: () {
                debugPrint('🚀 [CollectionsScreen] Navigating to Create Collection Screen via FAB');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateCollectionScreen()),
                );
              },
              backgroundColor: wapperColors.accentcolor,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ), 
          )
        ],
      ),
    );
  }
}