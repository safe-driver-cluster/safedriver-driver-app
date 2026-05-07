class ComplaintModel {
  final String id;
  final String driverId;
  final String subject;
  final String description;
  final ComplaintCategory category;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final List<String>? attachmentUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adminResponse;
  final DateTime? respondedAt;
  final String? respondedBy;

  ComplaintModel({
    required this.id,
    required this.driverId,
    required this.subject,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    this.attachmentUrls,
    required this.createdAt,
    required this.updatedAt,
    this.adminResponse,
    this.respondedAt,
    this.respondedBy,
  });

  bool get isResolved => status == ComplaintStatus.resolved;
  bool get isPending => status == ComplaintStatus.pending;

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      category: ComplaintCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => ComplaintCategory.other,
      ),
      status: ComplaintStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ComplaintStatus.pending,
      ),
      priority: ComplaintPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => ComplaintPriority.medium,
      ),
      attachmentUrls: json['attachmentUrls'] != null
          ? List<String>.from(json['attachmentUrls'])
          : null,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      adminResponse: json['adminResponse'],
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : null,
      respondedBy: json['respondedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'subject': subject,
      'description': description,
      'category': category.toString().split('.').last,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'attachmentUrls': attachmentUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'adminResponse': adminResponse,
      'respondedAt': respondedAt?.toIso8601String(),
      'respondedBy': respondedBy,
    };
  }

  ComplaintModel copyWith({
    String? id,
    String? driverId,
    String? subject,
    String? description,
    ComplaintCategory? category,
    ComplaintStatus? status,
    ComplaintPriority? priority,
    List<String>? attachmentUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminResponse,
    DateTime? respondedAt,
    String? respondedBy,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
    );
  }
}

enum ComplaintCategory {
  vehicle,
  route,
  schedule,
  payment,
  safety,
  harassment,
  equipment,
  other,
}

enum ComplaintStatus {
  pending,
  inProgress,
  resolved,
  rejected,
}

enum ComplaintPriority {
  low,
  medium,
  high,
  urgent,
}
