import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class FormDataUtils {
  static bool _isFileKey(String key) {
    return key.contains('_image') || key.contains('_cert') || key == 'profile_image' || key == 'attachment' || key == 'file' || key.endsWith('_file') || key.contains('image');
  }

  static Future<dynamic> prepareFormData(Map<String, dynamic> data) async {
    final formData = FormData();
    var hasFile = false;
    final output = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null) continue;

      if (_isFileKey(key)) {
        if (value is XFile) {
          final bytes = await value.readAsBytes();
          final mf = MultipartFile.fromBytes(bytes, filename: value.name);
          formData.files.add(MapEntry(key, mf));
          hasFile = true;
          continue;
        }

        if (value is List<int>) {
          final filename = '$key.bin';
          final mf = MultipartFile.fromBytes(value, filename: filename);
          formData.files.add(MapEntry(key, mf));
          hasFile = true;
          continue;
        }

        if (value is String && value.isNotEmpty) {
          if (value.startsWith('data:')) {
            final uri = Uri.parse(value);
            final bytes = uri.data?.contentAsBytes();
            if (bytes != null && bytes.isNotEmpty) {
              final filename = key.contains('.') ? key : '$key.png';
              final mf = MultipartFile.fromBytes(bytes, filename: filename);
              formData.files.add(MapEntry(key, mf));
              hasFile = true;
              continue;
            }
          }

          if (!kIsWeb) {
            try {
              final filename = value.split(RegExp(r'[\\/]+')).last;
              final mf = await MultipartFile.fromFile(value, filename: filename);
              formData.files.add(MapEntry(key, mf));
              hasFile = true;
              continue;
            } catch (_) {
              // fallback to string field below
            }
          }
        }
      }

      output[key] = value;
    }

    if (hasFile) {
      // Add non-file fields to FormData as well
      for (final entry in output.entries) {
        formData.fields.add(MapEntry(entry.key, entry.value.toString()));
      }
      return formData;
    }

    return output;
  }
}
