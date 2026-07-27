import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Web-optimized file picker that uses native HTML file input
class WebFilePicker {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image file (works on web and mobile)
  /// Returns XFile which works universally
  static Future<XFile?> pickImageFile() async {
    try {
      // Works on both web and mobile
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: false, // Faster on web
      );
      return pickedFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
      return null;
    }
  }
}
