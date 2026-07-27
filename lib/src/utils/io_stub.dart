// Minimal IO stub used for web builds to avoid importing dart:io
class File {
  final String path;
  File(this.path);
  bool existsSync() => false;
}
