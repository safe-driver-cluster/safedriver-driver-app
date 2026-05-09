import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? readDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

double readDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

String readString(
  Map<String, dynamic> data,
  List<String> keys, [
  String fallback = '',
]) {
  for (final key in keys) {
    final value = data[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return fallback;
}

class DriverProfile {
  DriverProfile({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.profileImageUrl,
    required this.licenseNumber,
    required this.licenseType,
    required this.licenseExpiry,
    required this.status,
    required this.currentBusId,
    required this.currentRoute,
    required this.safetyScore,
    required this.alertnessLevel,
    required this.rating,
    required this.totalRatings,
    required this.isActive,
    required this.raw,
  });

  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String? profileImageUrl;
  final String licenseNumber;
  final String licenseType;
  final DateTime? licenseExpiry;
  final String status;
  final String currentBusId;
  final String currentRoute;
  final double safetyScore;
  final double alertnessLevel;
  final double rating;
  final int totalRatings;
  final bool isActive;
  final Map<String, dynamic> raw;

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty
        ? name
        : readString(raw, ['name', 'fullName'], 'Driver');
  }

  bool get isOnDuty {
    final normalized = status.toLowerCase();
    return normalized == 'active' ||
        normalized == 'driving' ||
        normalized == 'onduty' ||
        normalized == 'on_duty';
  }

  factory DriverProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final performance = Map<String, dynamic>.from(
      data['performance'] as Map? ?? {},
    );
    final safetyMetrics = Map<String, dynamic>.from(
      data['safetyMetrics'] as Map? ?? {},
    );
    return DriverProfile(
      id: doc.id,
      employeeId: readString(data, [
        'employeeId',
        'driverId',
        'staffId',
      ], doc.id),
      firstName: readString(data, ['firstName']),
      lastName: readString(data, ['lastName']),
      phoneNumber: readString(data, [
        'phoneNumber',
        'phone',
        'mobileNumber',
        'contactNumber',
      ]),
      email: readString(data, ['email']),
      profileImageUrl:
          readString(data, ['profileImageUrl', 'photoUrl', 'avatarUrl']).isEmpty
          ? null
          : readString(data, ['profileImageUrl', 'photoUrl', 'avatarUrl']),
      licenseNumber: readString(data, ['licenseNumber', 'licenceNumber']),
      licenseType: readString(data, ['licenseType', 'licenceType'], 'Standard'),
      licenseExpiry: readDate(
        data['licenseExpiryDate'] ?? data['licenseExpiry'],
      ),
      status: readString(data, ['status', 'currentStatus'], 'offDuty'),
      currentBusId: readString(data, [
        'currentBusId',
        'busId',
        'assignedBusId',
      ]),
      currentRoute: readString(data, ['currentRoute', 'routeNumber', 'route']),
      safetyScore: readDouble(
        data['safetyScore'] ?? safetyMetrics['overallScore'],
      ),
      alertnessLevel: readDouble(
        data['alertnessLevel'] ?? safetyMetrics['alertnessLevel'],
        1,
      ),
      rating: readDouble(
        data['rating'] ??
            performance['overallRating'] ??
            performance['passengerRatings'],
      ),
      totalRatings:
          (data['totalRatings'] ?? performance['totalRatings'] ?? 0) is num
          ? ((data['totalRatings'] ?? performance['totalRatings']) as num)
                .toInt()
          : 0,
      isActive: data['isActive'] != false,
      raw: data,
    );
  }
}

class DriverBus {
  DriverBus({
    required this.id,
    required this.busNumber,
    required this.routeNumber,
    required this.registration,
    required this.status,
    required this.safetyScore,
    required this.currentSpeed,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
  });

  final String id;
  final String busNumber;
  final String routeNumber;
  final String registration;
  final String status;
  final double safetyScore;
  final double? currentSpeed;
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;

  factory DriverBus.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final location = Map<String, dynamic>.from(
      data['currentLocation'] as Map? ?? {},
    );
    return DriverBus(
      id: doc.id,
      busNumber: readString(data, [
        'busNumber',
        'busNumberPlate',
        'number',
      ], doc.id),
      routeNumber: readString(data, ['routeNumber', 'route']),
      registration: readString(data, ['registration', 'busNumberPlate']),
      status: readString(data, ['status'], 'offline'),
      safetyScore: readDouble(data['safetyScore']),
      currentSpeed: data['currentSpeed'] == null
          ? null
          : readDouble(data['currentSpeed']),
      latitude: location['latitude'] == null
          ? null
          : readDouble(location['latitude']),
      longitude: location['longitude'] == null
          ? null
          : readDouble(location['longitude']),
      lastUpdated: readDate(data['lastUpdated'] ?? location['timestamp']),
    );
  }
}

class DriverAlert {
  DriverAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String type;
  final DateTime? createdAt;

  factory DriverAlert.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DriverAlert(
      id: doc.id,
      title: readString(data, ['title'], 'Alert'),
      description: readString(data, ['description', 'message']),
      priority: readString(data, ['priority', 'severity'], 'medium'),
      status: readString(data, ['status'], 'active'),
      type: readString(data, ['type'], 'safety'),
      createdAt: readDate(data['createdAt'] ?? data['timestamp']),
    );
  }
}

class DriverFeedback {
  DriverFeedback({
    required this.id,
    required this.title,
    required this.description,
    required this.rating,
    required this.category,
    required this.createdAt,
    required this.passengerName,
  });

  final String id;
  final String title;
  final String description;
  final int rating;
  final String category;
  final DateTime? createdAt;
  final String passengerName;

  factory DriverFeedback.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ratingData = Map<String, dynamic>.from(data['rating'] as Map? ?? {});
    final value = ratingData['overall'] ?? data['rating'] ?? 0;
    return DriverFeedback(
      id: doc.id,
      title: readString(data, ['title'], 'Passenger feedback'),
      description: readString(data, ['description', 'comment']),
      rating: value is num ? value.toInt() : 0,
      category: readString(data, ['category'], 'driver'),
      createdAt: readDate(
        data['createdAt'] ?? data['submittedAt'] ?? data['timestamp'],
      ),
      passengerName: readString(data, [
        'userName',
        'passengerName',
      ], 'Passenger'),
    );
  }
}

class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.busId,
    required this.notes,
  });

  final String id;
  final String status;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String busId;
  final String notes;

  factory AttendanceRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AttendanceRecord(
      id: doc.id,
      status: readString(data, ['status'], 'recorded'),
      checkIn: readDate(
        data['checkIn'] ?? data['clockIn'] ?? data['createdAt'],
      ),
      checkOut: readDate(data['checkOut'] ?? data['clockOut']),
      busId: readString(data, ['busId', 'currentBusId']),
      notes: readString(data, ['notes', 'remark']),
    );
  }
}
