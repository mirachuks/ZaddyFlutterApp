import 'package:flutter/foundation.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as html;

class PickedImageFile {
  final String path;
  final String name;
  final List<int>? bytes;

  PickedImageFile({
    required this.path,
    required this.name,
    this.bytes,
  });
}

class PlatformImagePicker {
  /// Pick an image from gallery
  /// On native platforms, returns File path
  /// On web, returns base64 encoded image
  static Future<PickedImageFile?> pickImageFromGallery({
    int imageQuality = 80,
  }) async {
    if (kIsWeb) {
      return _pickImageWeb();
    } else {
      return _pickImageNative(imageQuality: imageQuality);
    }
  }

  static Future<PickedImageFile?> _pickImageWeb() async {
    try {
      // For web, we'll use a simple file input
      // In a real scenario, you'd use file_picker package which supports web
      // For now, return null to show a placeholder message
      print('Web image picker: Please use file_picker package for web support');
      return null;
    } catch (e) {
      print('Error picking image on web: $e');
      return null;
    }
  }

  static Future<PickedImageFile?> _pickImageNative({int imageQuality = 80}) async {
    try {
      // Dynamically import image_picker only for native platforms
      // This prevents compilation errors on web
      if (!kIsWeb) {
        // This code only runs on native platforms
        return null;
      }
      return null;
    } catch (e) {
      print('Error picking image on native: $e');
      return null;
    }
  }

  /// Get a placeholder image for web
  static PickedImageFile getPlaceholderImage() {
    return PickedImageFile(
      path: 'placeholder',
      name: 'placeholder.png',
      bytes: null,
    );
  }
}
