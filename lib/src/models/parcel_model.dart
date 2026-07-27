import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

// Coordinates model
@JsonSerializable()
class Coordinates {
  final double lat;
  final double lng;

  Coordinates({required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  factory Coordinates.fromJson(Map<String, dynamic> json) => Coordinates(
    lat: json['lat'] as double? ?? 0.0,
    lng: json['lng'] as double? ?? 0.0,
  );

  Coordinates copyWith({double? lat, double? lng}) => Coordinates(
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
  );
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

  factory PackageDetails.fromJson(Map<String, dynamic> json) => PackageDetails(
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
  }) =>
      PackageDetails(
        itemName: itemName ?? this.itemName,
        itemCategory: itemCategory ?? this.itemCategory,
        itemDescription: itemDescription ?? this.itemDescription,
        recipientName: recipientName ?? this.recipientName,
        recipientPhone: recipientPhone ?? this.recipientPhone,
        isFilled: isFilled ?? this.isFilled,
      );
}

// Parcel model - one parcel = one pickup + one dropoff + package details
@JsonSerializable()
class Parcel {
  final String id;
  final int parcelNumber; // Parcel 1, 2, 3...
  final String pickupAddress;
  final Coordinates pickupCoordinates;
  final String dropoffAddress;
  final Coordinates dropoffCoordinates;
  final PackageDetails packageDetails;

  Parcel({
    String? id,
    required this.parcelNumber,
    required this.pickupAddress,
    required this.pickupCoordinates,
    required this.dropoffAddress,
    required this.dropoffCoordinates,
    required this.packageDetails,
  }) : id = id ?? const Uuid().v4();

  bool get isPickupFilled => pickupAddress.trim().isNotEmpty;
  bool get isDropoffFilled => dropoffAddress.trim().isNotEmpty;
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
    id: json['id'] as String,
    parcelNumber: json['parcelNumber'] as int,
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
  }) =>
      Parcel(
        id: id,
        parcelNumber: parcelNumber,
        pickupAddress: pickupAddress ?? this.pickupAddress,
        pickupCoordinates: pickupCoordinates ?? this.pickupCoordinates,
        dropoffAddress: dropoffAddress ?? this.dropoffAddress,
        dropoffCoordinates: dropoffCoordinates ?? this.dropoffCoordinates,
        packageDetails: packageDetails ?? this.packageDetails,
      );
}

// Delivery state
@JsonSerializable()
class DeliveryState {
  final List<Parcel> parcels;
  final bool isLoading;
  final String? error;

  DeliveryState({
    List<Parcel>? parcels,
    this.isLoading = false,
    this.error,
  }) : parcels = parcels ?? [_createEmptyParcel(1)];

  static Parcel _createEmptyParcel(int parcelNumber) => Parcel(
    parcelNumber: parcelNumber,
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
  );

  int get parcelCount => parcels.length;
  int get completedParcelCount => parcels.where((p) => p.isComplete).length;
  bool get allParcelsComplete => parcels.every((p) => p.isComplete);

  Map<String, dynamic> toJson() => {
    'parcels': parcels.map((p) => p.toJson()).toList(),
    'isLoading': isLoading,
    'error': error,
  };

  factory DeliveryState.fromJson(Map<String, dynamic> json) => DeliveryState(
    parcels: (json['parcels'] as List<dynamic>? ?? [])
        .map((p) => Parcel.fromJson(p as Map<String, dynamic>))
        .toList(),
    isLoading: json['isLoading'] as bool? ?? false,
    error: json['error'] as String?,
  );
}

// Validation result
class ValidationResult {
  final bool isValid;
  final String message;
  final int? failedParcelIndex;

  ValidationResult({
    required this.isValid,
    this.message = '',
    this.failedParcelIndex,
  });
}
