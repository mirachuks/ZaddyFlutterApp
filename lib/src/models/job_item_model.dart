import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class JobItem {
  final String id;
  @JsonKey(name: 'job_id')
  final String? jobId;
  final String title;
  @JsonKey(name: 'receiver_name')
  final String? receiverName;
  @JsonKey(name: 'receiver_phone')
  final String? receiverPhone;
  @JsonKey(name: 'item_category')
  final String? itemCategory;
  final String? description;
  @JsonKey(name: 'pickup_address')
  final String? pickupAddress;
  @JsonKey(name: 'pickup_lat')
  final double? pickupLat;
  @JsonKey(name: 'pickup_lng')
  final double? pickupLng;
  @JsonKey(name: 'dropoff_address')
  final String? dropoffAddress;
  @JsonKey(name: 'dropoff_lat')
  final double? dropoffLat;
  @JsonKey(name: 'dropoff_lng')
  final double? dropoffLng;
  @JsonKey(name: 'mobility_type_needed')
  final String? mobilityTypeNeeded;
  final double? price;
  @JsonKey(name: 'price_type')
  final String? priceType;
  final String? status;
  @JsonKey(name: 'posted_at')
  final DateTime? postedAt;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  @JsonKey(name: 'delivered_at')
  final DateTime? deliveredAt;

  JobItem({
    required this.id,
    this.jobId,
    required this.title,
    this.receiverName,
    this.receiverPhone,
    this.itemCategory,
    this.description,
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffAddress,
    this.dropoffLat,
    this.dropoffLng,
    this.mobilityTypeNeeded,
    this.price,
    this.priceType,
    this.status,
    this.postedAt,
    this.expiresAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_id': jobId,
        'title': title,
        'receiver_name': receiverName,
        'receiver_phone': receiverPhone,
        'item_category': itemCategory,
        'description': description,
        'pickup_address': pickupAddress,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'dropoff_address': dropoffAddress,
        'dropoff_lat': dropoffLat,
        'dropoff_lng': dropoffLng,
        'mobility_type_needed': mobilityTypeNeeded,
        'price': price,
        'price_type': priceType,
        'status': status,
        'posted_at': postedAt?.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'delivered_at': deliveredAt?.toIso8601String(),
      }..removeWhere((key, value) => value == null);

  static JobItem fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return JobItem(
      id: json['id']?.toString() ?? '',
      jobId: json['job_id']?.toString(),
      title: json['title']?.toString() ?? json['item_description']?.toString() ?? json['description']?.toString() ?? 'Item',
      receiverName: json['receiver_name']?.toString() ?? json['recipient_name']?.toString(),
      receiverPhone: json['receiver_phone']?.toString() ?? json['recipient_phone']?.toString(),
      itemCategory: json['item_category']?.toString() ?? json['category']?.toString(),
      description: json['description']?.toString() ?? json['item_description']?.toString(),
      pickupAddress: json['pickup_address']?.toString(),
      pickupLat: parseDouble(json['pickup_lat']),
      pickupLng: parseDouble(json['pickup_lng']),
      dropoffAddress: json['dropoff_address']?.toString(),
      dropoffLat: parseDouble(json['dropoff_lat']),
      dropoffLng: parseDouble(json['dropoff_lng']),
      mobilityTypeNeeded: json['mobility_type_needed']?.toString(),
      price: parseDouble(json['price']),
      priceType: json['price_type']?.toString(),
      status: json['status']?.toString(),
      postedAt: parseDate(json['posted_at']),
      expiresAt: parseDate(json['expires_at']),
      deliveredAt: parseDate(json['delivered_at']),
    );
  }
}
