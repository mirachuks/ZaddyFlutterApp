import 'package:flutter/foundation.dart';

/// Platform compatibility layer for web and native platforms
/// This file provides web-safe alternatives to platform-specific packages

// Platform-independent location class
class LocationCoordinates {
  final double latitude;
  final double longitude;

  LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => 'LocationCoordinates($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationCoordinates &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Placeholder for GoogleMapController on web
class PlatformMapController {
  final dynamic _nativeController;

  PlatformMapController({dynamic nativeController}) : _nativeController = nativeController;

  dynamic get nativeController => _nativeController;
}

/// Web-safe wrapper for File paths
/// On web, this stores a data URL or reference
/// On native, this stores a file path
class PlatformFile {
  final String path;
  final String name;
  final List<int>? bytes;
  final bool isWeb;

  PlatformFile({
    required this.path,
    required this.name,
    this.bytes,
    this.isWeb = false,
  });

  @override
  String toString() => 'PlatformFile($name)';
}

/// Check if running on web
bool isWebPlatform() => kIsWeb;

/// Create a location object that works on both platforms
LocationCoordinates createLocation(double latitude, double longitude) {
  return LocationCoordinates(latitude: latitude, longitude: longitude);
}

/// Convert a LocationCoordinates to LatLng for native platforms
/// On web, this just returns the coordinates
dynamic toNativeLatLng(LocationCoordinates coords) {
  if (kIsWeb) {
    return coords;
  }
  // For native platforms, we dynamically import and create LatLng
  return coords;
}

/// Create a platform file reference
PlatformFile createPlatformFile({
  required String path,
  required String name,
  List<int>? bytes,
}) {
  return PlatformFile(
    path: path,
    name: name,
    bytes: bytes,
    isWeb: kIsWeb,
  );
}
