import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/delivery_model.dart';

// Delivery provider - manages the complete delivery workflow state
final deliveryProvider =
    StateNotifierProvider<DeliveryNotifier, DeliveryState>(
  (ref) => DeliveryNotifier(),
);

class DeliveryNotifier extends StateNotifier<DeliveryState> {
  static const _uuid = Uuid();

  DeliveryNotifier()
      : super(
          DeliveryState(
            waypoints: [
              Waypoint(
                id: 'pickup_0',
                type: WaypointType.pickup,
                addressString: '',
                coordinates: Coordinates(lat: 0, lng: 0),
                packageDetails: PackageDetails(
                  itemName: '',
                  itemCategory: '',
                  recipientName: '',
                  recipientPhone: '',
                ),
              ),
              Waypoint(
                id: 'dropoff_0',
                type: WaypointType.dropoff,
                addressString: '',
                coordinates: Coordinates(lat: 0, lng: 0),
                packageDetails: PackageDetails(
                  itemName: '',
                  itemCategory: '',
                  recipientName: '',
                  recipientPhone: '',
                ),
              ),
            ],
          ),
        );

  /// Update location for a specific waypoint
  void updateWaypointLocation(int index, String address, double lat, double lng) {
    final waypoints = [...state.waypoints];
    if (index < waypoints.length) {
      waypoints[index] = waypoints[index].copyWith(
        addressString: address,
        coordinates: Coordinates(lat: lat, lng: lng),
      );
      state = state.copyWith(waypoints: waypoints);
    }
  }

  /// Update package details for a specific waypoint
  void updateWaypointPackageDetails(int index, PackageDetails details) {
    final waypoints = [...state.waypoints];
    if (index < waypoints.length) {
      waypoints[index] = waypoints[index].copyWith(
        packageDetails: details,
      );
      state = state.copyWith(waypoints: waypoints);
    }
  }

  /// Add a new dropoff waypoint
  void addDropoffWaypoint() {
    final waypoints = [...state.waypoints];
    final dropoffIndex = waypoints.where((w) => w.type == WaypointType.dropoff).length;
    
    waypoints.add(
      Waypoint(
        id: 'dropoff_$dropoffIndex',
        type: WaypointType.dropoff,
        addressString: '',
        coordinates: Coordinates(lat: 0, lng: 0),
        packageDetails: PackageDetails(
          itemName: '',
          itemCategory: '',
          recipientName: '',
          recipientPhone: '',
        ),
      ),
    );
    
    state = state.copyWith(waypoints: waypoints);
  }

  /// Validate current active locations (pickup and first dropoff)
  ValidationResult validateCurrentLocations() {
    if (!state.isPickupFilled) {
      return ValidationResult(
        isValid: false,
        message: 'Please enter your pickup location first.',
        failedFieldIndex: 0,
      );
    }
    
    if (!state.isFirstDropoffFilled) {
      return ValidationResult(
        isValid: false,
        message: 'Please enter your delivery location first.',
        failedFieldIndex: 1,
      );
    }
    
    return ValidationResult(isValid: true, message: 'Valid');
  }

  /// Validate all waypoints before final submission
  ValidationResult validateAllWaypoints() {
    for (int i = 0; i < state.waypoints.length; i++) {
      final waypoint = state.waypoints[i];
      
      if (!waypoint.isLocationFilled) {
        return ValidationResult(
          isValid: false,
          message: 'Please fill all locations.',
          failedFieldIndex: i,
        );
      }
      
      if (!waypoint.packageDetails.isValid) {
        return ValidationResult(
          isValid: false,
          message: 'Please fill all required package details for Stop ${i}.',
          failedFieldIndex: i,
        );
      }
    }
    
    return ValidationResult(isValid: true, message: 'All waypoints are valid');
  }

  /// Get consolidated payload for order broadcast
  Map<String, dynamic> getConsolidatedPayload() {
    final stops = <Map<String, dynamic>>[];
    
    for (int i = 0; i < state.waypoints.length; i++) {
      final waypoint = state.waypoints[i];
      stops.add({
        'sequence': i + 1,
        'type': waypoint.type.toString().split('.').last,
        'address': waypoint.addressString,
        'coordinates': {
          'lat': waypoint.coordinates.lat,
          'lng': waypoint.coordinates.lng,
        },
        if (waypoint.type == WaypointType.dropoff)
          'package': {
            'itemName': waypoint.packageDetails.itemName,
            'itemCategory': waypoint.packageDetails.itemCategory,
            'itemDescription': waypoint.packageDetails.itemDescription,
            'recipientName': waypoint.packageDetails.recipientName,
            'recipientPhone': waypoint.packageDetails.recipientPhone,
          },
      });
    }
    
    return {
      'stops': stops,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Reset delivery state
  void resetDelivery() {
    state = DeliveryState(
      waypoints: [
        Waypoint(
          id: 'pickup_0',
          type: WaypointType.pickup,
          addressString: '',
          coordinates: Coordinates(lat: 0, lng: 0),
          packageDetails: PackageDetails(
            itemName: '',
            itemCategory: '',
            recipientName: '',
            recipientPhone: '',
          ),
        ),
        Waypoint(
          id: 'dropoff_0',
          type: WaypointType.dropoff,
          addressString: '',
          coordinates: Coordinates(lat: 0, lng: 0),
          packageDetails: PackageDetails(
            itemName: '',
            itemCategory: '',
            recipientName: '',
            recipientPhone: '',
          ),
        ),
      ],
    );
  }

  /// Set loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Set error state
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Broadcast the order (stub function - hook to backend here)
  Future<void> broadcastOrder() async {
    setLoading(true);
    try {
      final payload = getConsolidatedPayload();
      print('Broadcasting order with payload: $payload');
      
      // TODO: Replace with actual API call
      // final response = await apiClient.broadcastOrder(payload);
      
      await Future.delayed(const Duration(seconds: 1)); // Simulate API delay
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      rethrow;
    }
  }
}

/// Validation result model
class ValidationResult {
  final bool isValid;
  final String message;
  final int? failedFieldIndex;

  ValidationResult({
    required this.isValid,
    required this.message,
    this.failedFieldIndex,
  });
}
