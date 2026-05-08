import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for location data with coordinates
class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime? timestamp;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.timestamp,
  });

  /// Create LocationModel from Firestore document
  factory LocationModel.fromFirestore(Map<String, dynamic> data) {
    return LocationModel(
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] as String?,
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create LocationModel from GeoPoint
  factory LocationModel.fromGeoPoint(GeoPoint geoPoint, {String? address}) {
    return LocationModel(
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      address: address,
      timestamp: DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (timestamp != null) 'timestamp': Timestamp.fromDate(timestamp!),
    };
  }

  /// Convert to GeoPoint for Firestore
  GeoPoint toGeoPoint() {
    return GeoPoint(latitude, longitude);
  }

  /// Create a copy with updated fields
  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    DateTime? timestamp,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'LocationModel(lat: $latitude, lng: $longitude, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.address == address;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^ longitude.hashCode ^ address.hashCode;
  }
}
