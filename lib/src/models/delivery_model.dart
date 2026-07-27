import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

// Define the waypoint type
enum WaypointType { pickup, dropoff }

// Coordinates model
@JsonSerializable()
class Coordinates {
  final double lat;
  final double lng;

  Coordinates({
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
  };

  factory Coordinates.fromJson(Map<String, dynamic> json) => Coordinates(
    lat: json['lat'] as double? ?? 0.0,
    lng: json['lng'] as double? ?? 0.0,
  );

  Coordinates copyWith({double? lat, double? lng}) {
    return Coordinates(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

// Package details model
@JsonSerializable()
class PackageDetails {
  final String itemName;
  final String itemCategory;
  final String? itemDescription;
  final String recipientName;
  final String recipientPhone;
  final bool isFilled;

  PackageDetails({
    required this.itemName,
    required this.itemCategory,
    this.itemDescription,
    required this.recipientName,
    required this.recipientPhone,
    this.isFilled = false,
  });

  bool get isValid =>
      itemName.isNotEmpty &&
      itemCategory.isNotEmpty &&
      recipientName.isNotEmpty &&
      recipientPhone.isNotEmpty &&
      isFilled;

  Map<String, dynamic> toJson() => {
    'itemName': itemName,
    'itemCategory': itemCategory,
    'itemDescription': itemDescription,
    'recipientName': recipientName,
    'recipientPhone': recipientPhone,
    'isFilled': isFilled,
  };

  factory PackageDetails.fromJson(Map<String, dynamic> json) =>
      PackageDetails(
        itemName: json['itemName'] as String? ?? '',
        itemCategory: json['itemCategory'] as String? ?? '',
        itemDescription: json['itemDescription'] as String?,
        recipientName: json['recipientName'] as String? ?? '',
        recipientPhone: json['recipientPhone'] as String? ?? '',
        isFilled: json['isFilled'] as bool? ?? false,
      );

  PackageDetails copyWith({
    String? itemName,
    String? itemCategory,
    String? itemDescription,
    String? recipientName,
    String? recipientPhone,
    bool? isFilled,
  }) {
    return PackageDetails(
      itemName: itemName ?? this.itemName,
      itemCategory: itemCategory ?? this.itemCategory,
      itemDescription: itemDescription ?? this.itemDescription,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      isFilled: isFilled ?? this.isFilled,
    );
  }
}

// Parcel model - represents a pickup + dropoff pair with package details
@JsonSerializable()
class Parcel {
  final String id;
  final int parcelNumber; // Parcel 1, 2, 3, etc.
  final String pickupAddress;
  final Coordinates pickupCoordinates;
  final String dropoffAddress;
  final Coordinates dropoffCoordinates;
  final PackageDetails packageDetails;

  Parcel({
    required this.id,
    required this.parcelNumber,
    required this.pickupAddress,
    required this.pickupCoordinates,
    required this.dropoffAddress,
    required this.dropoffCoordinates,
    required this.packageDetails,
  });

  bool get isPickupFilled => pickupAddress.isNotEmpty;
  bool get isDropoffFilled => dropoffAddress.isNotEmpty;
  bool get isComplete => isPickupFilled && isDropoffFilled && packageDetails.isValid;

  Map<String, dynamic> toJson() => {
    'id': id,
    'parcelNumber': parcelNumber,
    'pickupAddress': pickupAddress,
    'pickupCoordinates': pickupCoordinates.toJson(),
    'dropoffAddress': dropoffAddress,
    'dropoffCoordinates': dropoffCoordinates.toJson(),
    'packageDetails': packageDetails.toJson(),
  };

  factory Parcel.fromJson(Map<String, dynamic> json) => Parcel(
    id: json['id'] as String? ?? const Uuid().v4(),
    parcelNumber: json['parcelNumber'] as int? ?? 1,
    pickupAddress: json['pickupAddress'] as String? ?? '',
    pickupCoordinates: Coordinates.fromJson(json['pickupCoordinates'] as Map<String, dynamic>? ?? {}),
    dropoffAddress: json['dropoffAddress'] as String? ?? '',
    dropoffCoordinates: Coordinates.fromJson(json['dropoffCoordinates'] as Map<String, dynamic>? ?? {}),
    packageDetails: PackageDetails.fromJson(json['packageDetails'] as Map<String, dynamic>? ?? {}),
  );

  Parcel copyWith({
    String? pickupAddress,
    Coordinates? pickupCoordinates,
    String? dropoffAddress,
    Coordinates? dropoffCoordinates,
    PackageDetails? packageDetails,
  }) {
    return Parcel(
      id: id,
      parcelNumber: parcelNumber,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupCoordinates: pickupCoordinates ?? this.pickupCoordinates,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffCoordinates: dropoffCoordinates ?? this.dropoffCoordinates,
      packageDetails: packageDetails ?? this.packageDetails,
    );
  }
}

// Waypoint model
@JsonSerializable()
class Waypoint {
  final String id;
  final WaypointType type;
  final String addressString;
  final Coordinates coordinates;
  final PackageDetails packageDetails;

  Waypoint({
    required this.id,
    required this.type,
    required this.addressString,
    required this.coordinates,
    required this.packageDetails,
  });

  bool get isLocationFilled => addressString.isNotEmpty;

  bool get isComplete => isLocationFilled && packageDetails.isValid;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString().split('.').last,
    'addressString': addressString,
    'coordinates': coordinates.toJson(),
    'packageDetails': packageDetails.toJson(),
  };

  factory Waypoint.fromJson(Map<String, dynamic> json) => Waypoint(
    id: json['id'] as String? ?? '',
    type: (json['type'] as String?) == 'pickup'
        ? WaypointType.pickup
        : WaypointType.dropoff,
    addressString: json['addressString'] as String? ?? '',
    coordinates: json['coordinates'] is Map
        ? Coordinates.fromJson(json['coordinates'] as Map<String, dynamic>)
        : Coordinates(lat: 0, lng: 0),
    packageDetails: json['packageDetails'] is Map
        ? PackageDetails.fromJson(
            json['packageDetails'] as Map<String, dynamic>)
        : PackageDetails(
            itemName: '',
            itemCategory: '',
            recipientName: '',
            recipientPhone: '',
          ),
  );

  Waypoint copyWith({
    String? id,
    WaypointType? type,
    String? addressString,
    Coordinates? coordinates,
    PackageDetails? packageDetails,
  }) {
    return Waypoint(
      id: id ?? this.id,
      type: type ?? this.type,
      addressString: addressString ?? this.addressString,
      coordinates: coordinates ?? this.coordinates,
      packageDetails: packageDetails ?? this.packageDetails,
    );
  }
}

// Delivery state model
@JsonSerializable()
class DeliveryState {
  final List<Waypoint> waypoints;
  final bool isLoading;
  final String? error;

  DeliveryState({
    required this.waypoints,
    this.isLoading = false,
    this.error,
  }) {
    // Ensure we always have at least 2 waypoints (pickup and first dropoff)
    if (this.waypoints.isEmpty) {
      _initializeDefaultWaypoints();
    }
  }

  void _initializeDefaultWaypoints() {
    (waypoints as List).addAll([
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
    ]);
  }

  int get dropoffCount => waypoints.where((w) => w.type == WaypointType.dropoff).length;

  bool get isPickupFilled => waypoints[0].isLocationFilled;

  bool get isFirstDropoffFilled =>
      waypoints.any((w) => w.type == WaypointType.dropoff && w.isLocationFilled);

  bool get allLocationsFilled => waypoints.every((w) => w.isLocationFilled);

  bool get allStopsComplete => waypoints.every((w) => w.isComplete);

  Map<String, dynamic> toJson() => {
    'waypoints': waypoints.map((w) => w.toJson()).toList(),
    'isLoading': isLoading,
    'error': error,
  };

  factory DeliveryState.fromJson(Map<String, dynamic> json) => DeliveryState(
    waypoints: (json['waypoints'] as List?)
            ?.map((w) => Waypoint.fromJson(w as Map<String, dynamic>))
            .toList() ??
        [],
    isLoading: json['isLoading'] as bool? ?? false,
    error: json['error'] as String?,
  );

  DeliveryState copyWith({
    List<Waypoint>? waypoints,
    bool? isLoading,
    String? error,
  }) {
    return DeliveryState(
      waypoints: waypoints ?? this.waypoints,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
