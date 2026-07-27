import 'dart:io';
import 'package:flutter/widgets.dart';

ImageProvider? fileImageProvider(String path) {
  final file = File(path);
  if (file.existsSync()) return FileImage(file);
  return null;
}

bool fileExists(String path) => File(path).existsSync();
