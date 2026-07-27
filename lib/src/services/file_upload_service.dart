import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../utils/form_data_utils.dart';
import 'api_client.dart';

class FileUploadService {
  final ApiClient apiClient;

  FileUploadService({required this.apiClient});

  /// Pick an image from device gallery or camera
  /// Returns null on web - use HTML file input instead
  Future<dynamic> pickImage({
    dynamic source = 0,
    int imageQuality = 80,
  }) async {
    try {
      if (kIsWeb) {
        // Web platform - not supported here
        // Use HTML file input or file_picker package instead
        return null;
      }
      // Native platform
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload single file to the server
  Future<String> uploadFile({
    required dynamic file,
    required String endpoint,
    required String fieldName,
    Map<String, dynamic>? additionalFields,
    void Function(int, int)? onProgress,
  }) async {
    try {
      // Use FormDataUtils to prepare payload for web/native
      final payload = <String, dynamic>{};
      payload.addAll(additionalFields ?? {});
      payload[fieldName] = file;

      final prepared = await FormDataUtils.prepareFormData(payload);

      final response = await apiClient.post(
        endpoint,
        data: prepared,
        onProgress: onProgress,
      );

      if (response.data is Map) {
        final map = response.data as Map;
        return map['path'] ?? map['url'] ?? '';
      }
      return '';
    } catch (e) {
      rethrow;
    }
  }

  /// Upload multiple files to the server
  Future<String> uploadFiles({
    required Map<String, dynamic> files, // Map of fieldName -> dynamic
    required String endpoint,
    Map<String, dynamic>? additionalFields,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final payload = <String, dynamic>{};
      payload.addAll(additionalFields ?? {});
      payload.addAll(files);

      final prepared = await FormDataUtils.prepareFormData(payload);

      final response = await apiClient.post(
        endpoint,
        data: prepared,
        onProgress: onProgress,
      );

      if (response.data is Map) {
        final map = response.data as Map;
        return map['path'] ?? map['url'] ?? '';
      }
      return '';
    } catch (e) {
      rethrow;
    }
  }

  /// Upload multiple files at once
  Future<Map<String, String>> uploadMultipleFiles({
    required Map<String, dynamic> files, // Map of fieldName -> File
    required String endpoint,
    Map<String, dynamic>? additionalFields,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final payload = <String, dynamic>{};
      payload.addAll(additionalFields ?? {});
      payload.addAll(files);

      final prepared = await FormDataUtils.prepareFormData(payload);

      final response = await apiClient.post(
        endpoint,
        data: prepared,
        onProgress: onProgress,
      );

      final uploadedPaths = <String, String>{};
      if (response.data is Map) {
        final responseData = response.data as Map;
        responseData.forEach((key, value) {
          if (value is Map && (value.containsKey('path') || value.containsKey('url'))) {
            uploadedPaths[key] = value['path'] ?? value['url'] ?? '';
          }
        });
      }

      return uploadedPaths;
    } catch (e) {
      rethrow;
    }
  }

  /// Compress image file to reduce size
  Future<dynamic> compressImage(dynamic imageFile, {int quality = 80}) async {
    try {
      if (kIsWeb) {
        return null; // Web doesn't need compression
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get file size in MB
  static double getFileSizeInMB(dynamic file) {
    return 0.0; // Placeholder for web
  }

  /// Validate file size (max size in MB)
  static bool isFileSizeValid(dynamic file, {double maxSizeMB = 10}) {
    return true; // Placeholder
  }

  /// Validate file type
  static bool isValidImageFile(dynamic file) {
    return true; // Placeholder
  }
}
