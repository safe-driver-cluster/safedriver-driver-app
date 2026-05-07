class AttendanceModel {
  final String id;
  final String driverId;
  final DateTime clockInTime;
  final DateTime? clockOutTime;
  final LocationData clockInLocation;
  final LocationData? clockOutLocation;
  final AttendanceStatus status;
  final double? totalHours;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceModel({
    required this.id,
    required this.driverId,
    required this.clockInTime,
    this.clockOutTime,
    required this.clockInLocation,
    this.clockOutLocation,
    required this.status,
    this.totalHours,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isClockedIn =>
      clockOutTime == null && status == AttendanceStatus.active;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      clockInTime: DateTime.parse(
          json['clockInTime'] ?? DateTime.now().toIso8601String()),
      clockOutTime: json['clockOutTime'] != null
          ? DateTime.parse(json['clockOutTime'])
          : null,
      clockInLocation: LocationData.fromJson(json['clockInLocation'] ?? {}),
      clockOutLocation: json['clockOutLocation'] != null
          ? LocationData.fromJson(json['clockOutLocation'])
          : null,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AttendanceStatus.active,
      ),
      totalHours: json['totalHours']?.toDouble(),
      notes: json['notes'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'clockInTime': clockInTime.toIso8601String(),
      'clockOutTime': clockOutTime?.toIso8601String(),
      'clockInLocation': clockInLocation.toJson(),
      'clockOutLocation': clockOutLocation?.toJson(),
      'status': status.toString().split('.').last,
      'totalHours': totalHours,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? driverId,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    LocationData? clockInLocation,
    LocationData? clockOutLocation,
    AttendanceStatus? status,
    double? totalHours,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      clockInLocation: clockInLocation ?? this.clockInLocation,
      clockOutLocation: clockOutLocation ?? this.clockOutLocation,
      status: status ?? this.status,
      totalHours: totalHours ?? this.totalHours,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum AttendanceStatus {
  active,
  completed,
  absent,
  late,
}

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'],
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
