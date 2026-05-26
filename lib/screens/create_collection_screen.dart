import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; 

// 🚀 NEW IMPORT PATHS
import 'package:wappar/core/theme/colors.dart';
import 'package:wappar/providers/collection_provider.dart';
import 'package:wappar/widgets/collection/create_collection_components.dart';

class CreateCollectionScreen extends StatefulWidget {
  const CreateCollectionScreen({super.key});

  @override
  State<CreateCollectionScreen> createState() => _CreateCollectionScreenState();
}

class _CreateCollectionScreenState extends State<CreateCollectionScreen> {
  String? _coverPhotoPath; 
  final TextEditingController _nameController = TextEditingController();
  final List<String> _selectedPhotosPaths = [];

  void _createCollection() async {
    debugPrint('🚀 [CreateCollectionScreen] Attempting to create collection...');
    
    if (_nameController.text.trim().isEmpty) {
      debugPrint('🛑 [CreateCollectionScreen] Validation failed: Name is empty.');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a name")));
      return;
    }
    if (_coverPhotoPath == null) {
      debugPrint('🛑 [CreateCollectionScreen] Validation failed: No cover photo.');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a cover photo")));
      return;
    }

    debugPrint('🚀 [CreateCollectionScreen] Validation passed. Sending to Provider...');
    await context.read<CollectionProvider>().createCollectionWithWallpapers(
      _nameController.text.trim(),
      _coverPhotoPath!,
      _selectedPhotosPaths,
    );

    debugPrint('✅ [CreateCollectionScreen] Collection saved successfully.');
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickCoverPhoto() async {
    debugPrint('🚀 [CreateCollectionScreen] Opening single image picker for cover photo...');
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      debugPrint('✅ [CreateCollectionScreen] Cover photo selected: ${image.path}');
      setState(() {
        _coverPhotoPath = image.path; 
      });
    }
  }

  Future<void> _pickMultiplePhotos() async {
    debugPrint('🚀 [CreateCollectionScreen] Opening multi-image picker for wallpapers...');
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      debugPrint('✅ [CreateCollectionScreen] Selected ${images.length} new photos.');
      setState(() {
        _selectedPhotosPaths.addAll(images.map((img) => img.path));
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wapperColors = Theme.of(context).extension<WapperColors>()!;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double navBarHeight = 87.h + bottomPadding; 
    
    return Scaffold(
      backgroundColor: wapperColors.backgroundColor, 
      extendBodyBehindAppBar: true, 
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w, top: 8.h, bottom: 8.h),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3), 
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverPhotoHeader(
              coverPhotoPath: _coverPhotoPath,
              onTap: _pickCoverPhoto,
            ),
        
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CollectionNameField(controller: _nameController),
                  SizedBox(height: 24.h), 
                  PhotoSelectionArea(
                    selectedCount: _selectedPhotosPaths.length,
                    onAddPhotos: _pickMultiplePhotos,
                  ),
                  SizedBox(height: 80.h), 
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        color: Colors.transparent,
        height: navBarHeight,
        padding: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          top: 16.h,
          bottom: bottomPadding + 20.h, 
        ),
        child: SizedBox(
          height: 55.h,
          child: ElevatedButton.icon(
            onPressed: _createCollection, 
            style: ElevatedButton.styleFrom(
              backgroundColor: wapperColors.accentcolor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
            label: Text(
              "Create Collection",
              style: GoogleFonts.manrope(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}