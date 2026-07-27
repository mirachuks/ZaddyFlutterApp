import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class LocationSuggestion {
  final String addressString;
  final double lat;
  final double lng;

  const LocationSuggestion({
    required this.addressString,
    required this.lat,
    required this.lng,
  });
}

class LocationSuggestionService {
  static const String _userAgent = 'ZaddyExpress/1.0 (support@zaddyexpress.com)';
  static const Duration debounceDuration = Duration(milliseconds: 800);
  static const double ratePerKm = 900.0;

  static Uri buildSuggestionUri(String query) {
    final base = ApiConfig.baseUrl.replaceAll('/api', '');
    return Uri.parse('$base/api/places/suggest?query=${Uri.encodeQueryComponent(query)}');
  }

  static Future<List<LocationSuggestion>> fetchSuggestions(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 3) {
      return getFallbackSuggestions(trimmedQuery);
    }

    final queryText = trimmedQuery.toLowerCase().contains('enugu')
        ? trimmedQuery
        : 'Enugu $trimmedQuery';

    final uri = buildSuggestionUri(queryText);

    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept-Language': 'en',
        },
      );

      if (response.statusCode != 200) {
        return getFallbackSuggestions(trimmedQuery);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return getFallbackSuggestions(trimmedQuery);
      }

      final suggestions = decoded.whereType<Map<String, dynamic>>().map((item) {
        if (!isAddressLikeSuggestion(item)) {
          return null;
        }

        final displayName = item['display_name']?.toString() ?? '';
        final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
        final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;

        return LocationSuggestion(
          addressString: displayName,
          lat: lat,
          lng: lon,
        );
      }).whereType<LocationSuggestion>();

      final mapped = suggestions
          .where((suggestion) => suggestion.addressString.isNotEmpty)
          .toList();

      return mapped.isEmpty ? getFallbackSuggestions(trimmedQuery) : mapped;
    } catch (_) {
      return getFallbackSuggestions(trimmedQuery);
    }
  }

  static List<LocationSuggestion> getFallbackSuggestions(String query) {
    final normalized = query.trim().toLowerCase();
    final baseSuggestions = <LocationSuggestion>[
      const LocationSuggestion(
        addressString: 'Ogui Road, Enugu, Enugu State, Nigeria',
        lat: 6.4474,
        lng: 7.5086,
      ),
      const LocationSuggestion(
        addressString: 'Abakpa Nike, Enugu, Enugu State, Nigeria',
        lat: 6.4580,
        lng: 7.5465,
      ),
      const LocationSuggestion(
        addressString: 'New Haven, Enugu, Enugu State, Nigeria',
        lat: 6.4462,
        lng: 7.5074,
      ),
      const LocationSuggestion(
        addressString: 'GRA, Enugu, Enugu State, Nigeria',
        lat: 6.4402,
        lng: 7.5019,
      ),
      const LocationSuggestion(
        addressString: 'Independence Layout, Enugu, Enugu State, Nigeria',
        lat: 6.4510,
        lng: 7.5169,
      ),
    ];

    if (normalized.isEmpty) {
      return baseSuggestions;
    }

    return baseSuggestions.where((suggestion) {
      final value = suggestion.addressString.toLowerCase();
      return value.contains(normalized) || normalized.split(' ').every((word) => value.contains(word));
    }).toList();
  }

  static bool isAddressLikeSuggestion(Map<String, dynamic> item) {
    final displayName = item['display_name']?.toString() ?? '';
    if (displayName.isEmpty) {
      return false;
    }

    final lowerDisplayName = displayName.toLowerCase();
    final placeType = item['type']?.toString().toLowerCase() ?? '';
    final placeClass = item['class']?.toString().toLowerCase() ?? '';

    final blockedTypes = <String>{
      'administrative',
      'city',
      'state',
      'county',
      'country',
      'town',
      'village',
      'suburb',
      'neighbourhood',
      'hamlet',
    };
    final blockedClasses = <String>{'boundary', 'place'};

    if (blockedTypes.contains(placeType) || blockedClasses.contains(placeClass)) {
      return false;
    }

    final addressMarkers = <String>{
      'road',
      'street',
      'avenue',
      'close',
      'lane',
      'crescent',
      'drive',
      'way',
      'junction',
      'estate',
      'building',
      'house',
      'plot',
      'residential',
      'compound',
      'block',
      'flat',
      'apartment',
      'hotel',
      'shop',
      'market',
      'office',
      'school',
      'hospital',
      'church',
      'bank',
      'bus stop',
      'park',
      'route',
    };

    final containsAddressMarker = addressMarkers.any(lowerDisplayName.contains);
    return containsAddressMarker || lowerDisplayName.contains('enugu') && lowerDisplayName.contains(',');
  }

  static double calculateDistanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const double earthRadiusKm = 6371.0;
    final double latDistance = _toRadians(endLat - startLat);
    final double lonDistance = _toRadians(endLng - startLng);

    final double a =
        (sin(latDistance / 2) * sin(latDistance / 2)) +
            cos(_toRadians(startLat)) *
                cos(_toRadians(endLat)) *
                (sin(lonDistance / 2) * sin(lonDistance / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double calculateDeliveryPrice({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    double ratePerKm = ratePerKm,
  }) {
    final distanceKm = calculateDistanceKm(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
    return distanceKm * ratePerKm;
  }

  static double _toRadians(double degrees) => degrees * (3.141592653589793 / 180);
}
