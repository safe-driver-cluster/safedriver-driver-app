class DriverModel {
  final String driverId;
  final String name;
  final String phone;
  final String email;
  final String licenseNumber;
  final String busId;
  final String profilePictureUrl;
  final bool isActive;
  final DateTime createdAt;
  final double averageRating;
  final int totalRatings;

  DriverModel({
    required this.driverId,
    required this.name,
    required this.phone,
    required this.email,
    required this.licenseNumber,
    required this.busId,
    required this.profilePictureUrl,
    required this.isActive,
    required this.createdAt,
    required this.averageRating,
    required this.totalRatings,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      driverId: json['driverId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      busId: json['busId'] ?? '',
      profilePictureUrl: json['profilePictureUrl'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'name': name,
      'phone': phone,
      'email': email,
      'licenseNumber': licenseNumber,
      'busId': busId,
      'profilePictureUrl': profilePictureUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'averageRating': averageRating,
      'totalRatings': totalRatings,
    };
  }
}

class AttendanceModel {
  final String attendanceId;
  final String driverId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String status;

  AttendanceModel({
    required this.attendanceId,
    required this.driverId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      attendanceId: json['attendanceId'] ?? '',
      driverId: json['driverId'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
      status: json['status'] ?? 'absent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendanceId': attendanceId,
      'driverId': driverId,
      'date': date.toIso8601String(),
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'status': status,
    };
  }
}

class BusModel {
  final String busId;
  final String busNumber;
  final String route;
  final int capacity;
  final String status;

  BusModel({
    required this.busId,
    required this.busNumber,
    required this.route,
    required this.capacity,
    required this.status,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      busId: json['busId'] ?? '',
      busNumber: json['busNumber'] ?? '',
      route: json['route'] ?? '',
      capacity: json['capacity'] ?? 0,
      status: json['status'] ?? 'inactive',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busId': busId,
      'busNumber': busNumber,
      'route': route,
      'capacity': capacity,
      'status': status,
    };
  }
}

class AlertModel {
  final String alertId;
  final String driverId;
  final String title;
  final String description;
  final DateTime createdAt;
  final String type;

  AlertModel({
    required this.alertId,
    required this.driverId,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.type,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      alertId: json['alertId'] ?? '',
      driverId: json['driverId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      type: json['type'] ?? 'info',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'driverId': driverId,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
    };
  }
}

class RatingModel {
  final String ratingId;
  final String driverId;
  final double rating;
  final String passengerName;
  final String comment;
  final DateTime createdAt;

  RatingModel({
    required this.ratingId,
    required this.driverId,
    required this.rating,
    required this.passengerName,
    required this.comment,
    required this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      ratingId: json['ratingId'] ?? '',
      driverId: json['driverId'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      passengerName: json['passengerName'] ?? '',
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ratingId': ratingId,
      'driverId': driverId,
      'rating': rating,
      'passengerName': passengerName,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ComplaintModel {
  final String complaintId;
  final String driverId;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;

  ComplaintModel({
    required this.complaintId,
    required this.driverId,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      complaintId: json['complaintId'] ?? '',
      driverId: json['driverId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complaintId': complaintId,
      'driverId': driverId,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
