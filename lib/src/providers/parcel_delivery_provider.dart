import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parcel_model.dart';

class ParcelDeliveryNotifier extends StateNotifier<DeliveryState> {
  ParcelDeliveryNotifier() : super(DeliveryState());

  // Update pickup address for a parcel
  void updateParcelPickup(int parcelIndex, String address, double lat, double lng) {
    if (parcelIndex < 0 || parcelIndex >= state.parcels.length) return;
    
    final parcels = List<Parcel>.from(state.parcels);
    parcels[parcelIndex] = parcels[parcelIndex].copyWith(
      pickupAddress: address,
      pickupCoordinates: Coordinates(lat: lat, lng: lng),
    );
    state = DeliveryState(
      parcels: parcels,
      isLoading: state.isLoading,
      error: state.error,
    );
  }

  // Update dropoff address for a parcel
  void updateParcelDropoff(int parcelIndex, String address, double lat, double lng) {
    if (parcelIndex < 0 || parcelIndex >= state.parcels.length) return;
    
    final parcels = List<Parcel>.from(state.parcels);
    parcels[parcelIndex] = parcels[parcelIndex].copyWith(
      dropoffAddress: address,
      dropoffCoordinates: Coordinates(lat: lat, lng: lng),
    );
    state = DeliveryState(
      parcels: parcels,
      isLoading: state.isLoading,
      error: state.error,
    );
  }

  // Update package details for a parcel
  void updateParcelPackageDetails(int parcelIndex, PackageDetails details) {
    if (parcelIndex < 0 || parcelIndex >= state.parcels.length) return;
    
    final parcels = List<Parcel>.from(state.parcels);
    parcels[parcelIndex] = parcels[parcelIndex].copyWith(
      packageDetails: details,
    );
    state = DeliveryState(
      parcels: parcels,
      isLoading: state.isLoading,
      error: state.error,
    );
  }

  // Add a new empty parcel
  void addNewParcel() {
    final parcels = List<Parcel>.from(state.parcels);
    parcels.add(
      Parcel(
        parcelNumber: parcels.length + 1,
        pickupAddress: '',
        pickupCoordinates: Coordinates(lat: 0, lng: 0),
        dropoffAddress: '',
        dropoffCoordinates: Coordinates(lat: 0, lng: 0),
        packageDetails: PackageDetails(
          itemName: '',
          itemCategory: '',
          recipientName: '',
          recipientPhone: '',
        ),
      ),
    );
    state = DeliveryState(
      parcels: parcels,
      isLoading: state.isLoading,
      error: state.error,
    );
  }

  // Validate current parcel (for Add More Location)
  ValidationResult validateCurrentParcel(int parcelIndex) {
    if (parcelIndex < 0 || parcelIndex >= state.parcels.length) {
      return ValidationResult(
        isValid: false,
        message: 'Invalid parcel',
      );
    }

    final parcel = state.parcels[parcelIndex];
    
    if (!parcel.isPickupFilled) {
      return ValidationResult(
        isValid: false,
        message: 'Please enter the pickup location for Parcel ${parcel.parcelNumber}',
        failedParcelIndex: parcelIndex,
      );
    }

    if (!parcel.isDropoffFilled) {
      return ValidationResult(
        isValid: false,
        message: 'Please enter the dropoff location for Parcel ${parcel.parcelNumber}',
        failedParcelIndex: parcelIndex,
      );
    }

    return ValidationResult(isValid: true);
  }

  // Validate all parcels before broadcast
  ValidationResult validateAllParcels() {
    for (int i = 0; i < state.parcels.length; i++) {
      final parcel = state.parcels[i];
      
      if (!parcel.isPickupFilled) {
        return ValidationResult(
          isValid: false,
          message: 'Parcel ${parcel.parcelNumber}: Please enter pickup location',
          failedParcelIndex: i,
        );
      }

      if (!parcel.isDropoffFilled) {
        return ValidationResult(
          isValid: false,
          message: 'Parcel ${parcel.parcelNumber}: Please enter dropoff location',
          failedParcelIndex: i,
        );
      }

      if (!parcel.packageDetails.isValid) {
        return ValidationResult(
          isValid: false,
          message: 'Parcel ${parcel.parcelNumber}: Please complete package details',
          failedParcelIndex: i,
        );
      }
    }

    return ValidationResult(isValid: true);
  }

  // Get consolidated payload for API
  Map<String, dynamic>? getConsolidatedPayload() {
    final validation = validateAllParcels();
    if (!validation.isValid) return null;

    return {
      'stops': state.parcels.map((parcel) {
        return {
          'parcelNumber': parcel.parcelNumber,
          'pickup': {
            'address': parcel.pickupAddress,
            'coordinates': {
              'lat': parcel.pickupCoordinates.lat,
              'lng': parcel.pickupCoordinates.lng,
            },
          },
          'dropoff': {
            'address': parcel.dropoffAddress,
            'coordinates': {
              'lat': parcel.dropoffCoordinates.lat,
              'lng': parcel.dropoffCoordinates.lng,
            },
          },
          'package': {
            'itemName': parcel.packageDetails.itemName,
            'itemCategory': parcel.packageDetails.itemCategory,
            'itemDescription': parcel.packageDetails.itemDescription,
            'recipientName': parcel.packageDetails.recipientName,
            'recipientPhone': parcel.packageDetails.recipientPhone,
          },
        };
      }).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Broadcast order (stub for API integration)
  Future<void> broadcastOrder() async {
    state = DeliveryState(
      parcels: state.parcels,
      isLoading: true,
      error: state.error,
    );

    try {
      // TODO: Integrate with actual API
      // final payload = getConsolidatedPayload();
      // await http.post('/api/orders', body: payload);
      
      await Future.delayed(const Duration(seconds: 1));
      
      state = DeliveryState(
        parcels: state.parcels,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = DeliveryState(
        parcels: state.parcels,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Reset delivery state
  void resetDelivery() {
    state = DeliveryState();
  }

  // Set loading state
  void setLoading(bool loading) {
    state = DeliveryState(
      parcels: state.parcels,
      isLoading: loading,
      error: state.error,
    );
  }
}

final parcelDeliveryProvider = StateNotifierProvider<ParcelDeliveryNotifier, DeliveryState>((ref) {
  return ParcelDeliveryNotifier();
});
