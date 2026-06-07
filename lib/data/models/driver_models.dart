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

int readInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
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
        normalized == 'on_duty' ||
        normalized == 'on duty';
  }

  factory DriverProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return DriverProfile.fromMap(doc.id, doc.data() ?? {});
  }

  factory DriverProfile.fromMap(String id, Map<String, dynamic> data) {
    final performance = Map<String, dynamic>.from(
      data['performance'] as Map? ?? {},
    );
    final safetyMetrics = Map<String, dynamic>.from(
      data['safetyMetrics'] as Map? ?? {},
    );
    final fullName = readString(data, ['name', 'fullName']);
    final nameParts = fullName.split(RegExp(r'\s+'));
    return DriverProfile(
      id: id,
      employeeId: readString(data, ['employeeId', 'driverId', 'staffId'], id),
      firstName: readString(data, [
        'firstName',
      ], nameParts.isEmpty ? '' : nameParts.first),
      lastName: readString(data, [
        'lastName',
      ], nameParts.length <= 1 ? '' : nameParts.skip(1).join(' ')),
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
        'busNumber',
        'assignedBusNumber',
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
      totalRatings: readInt(
        data['totalRatings'] ?? performance['totalRatings'],
      ),
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
    required this.model,
    required this.routeId,
    required this.locationDepot,
    required this.locationAddress,
    required this.driverName,
    required this.deviceId,
    required this.year,
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
  final String model;
  final String routeId;
  final String locationDepot;
  final String locationAddress;
  final String driverName;
  final String deviceId;
  final int year;
  final double safetyScore;
  final double? currentSpeed;
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;

  factory DriverBus.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final location = Map<String, dynamic>.from(
      (data['currentLocation'] ?? data['location']) as Map? ?? {},
    );
    return DriverBus(
      id: doc.id,
      busNumber: readString(data, [
        'busNumber',
        'busNumberPlate',
        'number',
      ], doc.id),
      routeNumber: readString(data, ['routeNumber', 'route']),
      registration: readString(data, [
        'registration',
        'busNumberPlate',
        'busNumber',
      ], doc.id),
      status: readString(data, ['status'], 'offline'),
      model: readString(data, ['model', 'busModel']),
      routeId: readString(data, ['routeId']),
      locationDepot: readString(data, ['locationDepot', 'depot']),
      locationAddress: readString(location, ['address']),
      driverName: readString(data, ['driverName']),
      deviceId: readString(data, ['deviceId']),
      year: readInt(data['year']),
      safetyScore: readDouble(data['safetyScore']),
      currentSpeed: data['currentSpeed'] == null
          ? null
          : readDouble(data['currentSpeed']),
      latitude: (location['latitude'] ?? location['lat']) == null
          ? null
          : readDouble(location['latitude'] ?? location['lat']),
      longitude: (location['longitude'] ?? location['lng']) == null
          ? null
          : readDouble(location['longitude'] ?? location['lng']),
      lastUpdated: readDate(
        data['lastUpdated'] ?? data['updatedAt'] ?? location['timestamp'],
      ),
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
    required this.tag,
    required this.numberPlate,
    required this.driverRef,
    required this.evidenceUrl,
    required this.createdAt,
    required this.raw,
  });

  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String type;
  final String tag;
  final String numberPlate;
  final String driverRef;
  final String evidenceUrl;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  factory DriverAlert.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final type = readString(data, ['type'], 'safety');
    final message = readString(data, ['message', 'description']);
    return DriverAlert(
      id: doc.id,
      title: readString(data, ['title'], message.isEmpty ? type : message),
      description: readString(data, [
        'description',
        'message',
      ], message.isEmpty ? 'Detection event' : message),
      priority: readString(data, ['priority', 'severity'], _priorityFor(type)),
      status: readString(data, ['status'], 'active'),
      type: type,
      tag: readString(data, ['tag']),
      numberPlate: readString(data, [
        'number_plate',
        'numberPlate',
        'busNumber',
        'busNumberPlate',
        'plateNumber',
      ]),
      driverRef: readString(data, ['driver', 'driverId', 'employeeId']),
      evidenceUrl: readString(data, [
        'evidence',
        'evidenceUrl',
        'imageUrl',
        'photoUrl',
        'mediaUrl',
        'attachmentUrl',
      ]),
      createdAt: readDate(
        data['createdAt'] ?? data['timestamp'] ?? data['time'],
      ),
      raw: data,
    );
  }

  static String _priorityFor(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('smoking') ||
        normalized.contains('phone') ||
        normalized.contains('sleep')) {
      return 'high';
    }
    return 'medium';
  }
}

class DriverHazardZone {
  DriverHazardZone({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.createdAt,
    required this.updatedAt,
    required this.raw,
  });

  final String id;
  final String name;
  final String type;
  final String location;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  bool get hasLocation => latitude != 0 && longitude != 0;

  factory DriverHazardZone.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final latitude = readDouble(data['latitude'] ?? data['lat']);
    final longitude = readDouble(
      data['longitude'] ?? data['lng'] ?? data['lon'],
    );
    return DriverHazardZone(
      id: doc.id,
      name: readString(
        data,
        ['name', 'title'],
        latitude == 0 || longitude == 0
            ? 'Hazard zone'
            : 'Hazard at ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
      ),
      type: readString(data, ['type', 'category'], 'hazard'),
      location: readString(data, ['location', 'address'], 'Detected Location'),
      latitude: latitude,
      longitude: longitude,
      radiusMeters: readDouble(data['radius'] ?? data['radiusMeters'], 250),
      createdAt: readDate(data['createdAt']),
      updatedAt: readDate(data['updatedAt']),
      raw: data,
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
      rating: readInt(value),
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

class DriverComplaintRecord {
  DriverComplaintRecord({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.status,
    required this.mediaUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String message;
  final String category;
  final String status;
  final String mediaUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DriverComplaintRecord.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DriverComplaintRecord(
      id: doc.id,
      title: readString(data, ['title'], 'Complaint'),
      message: readString(data, ['message', 'description']),
      category: readString(data, ['category', 'type']),
      status: readString(data, ['status'], 'open'),
      mediaUrl: readString(data, ['mediaUrl', 'imageUrl', 'attachmentUrl']),
      createdAt: readDate(
        data['createdAt'] ?? data['submittedAt'] ?? data['timestamp'],
      ),
      updatedAt: readDate(data['updatedAt'] ?? data['resolvedAt']),
    );
  }
}

class DriverSupportRequest {
  DriverSupportRequest({
    required this.id,
    required this.category,
    required this.message,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String category;
  final String message;
  final String priority;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DriverSupportRequest.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DriverSupportRequest(
      id: doc.id,
      category: readString(data, ['category', 'subject'], 'Support request'),
      message: readString(data, ['message', 'description', 'lastMessage']),
      priority: readString(data, ['priority'], 'normal'),
      status: readString(data, ['status'], 'open'),
      createdAt: readDate(
        data['createdAt'] ?? data['submittedAt'] ?? data['timestamp'],
      ),
      updatedAt: readDate(data['updatedAt'] ?? data['lastMessageAt']),
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
