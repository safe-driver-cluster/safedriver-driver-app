import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/complaint_model.dart';

class ComplaintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'complaints';

  // Submit a complaint
  Future<ComplaintModel> submitComplaint({
    required String driverId,
    required String subject,
    required String description,
    required ComplaintCategory category,
    ComplaintPriority priority = ComplaintPriority.medium,
    List<String>? attachmentUrls,
  }) async {
    final now = DateTime.now();
    final complaint = ComplaintModel(
      id: '',
      driverId: driverId,
      subject: subject,
      description: description,
      category: category,
      status: ComplaintStatus.pending,
      priority: priority,
      attachmentUrls: attachmentUrls,
      createdAt: now,
      updatedAt: now,
    );

    final docRef =
        await _firestore.collection(_collection).add(complaint.toJson());
    return complaint.copyWith(id: docRef.id);
  }

  // Get complaints for a driver
  Future<List<ComplaintModel>> getComplaints({
    required String driverId,
    ComplaintStatus? status,
    int limit = 50,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (status != null) {
      query =
          query.where('status', isEqualTo: status.toString().split('.').last);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return ComplaintModel.fromJson(data);
    }).toList();
  }

  // Stream complaints for a driver
  Stream<List<ComplaintModel>> streamComplaints({
    required String driverId,
    ComplaintStatus? status,
  }) {
    Query query = _firestore
        .collection(_collection)
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .limit(50);

    if (status != null) {
      query =
          query.where('status', isEqualTo: status.toString().split('.').last);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ComplaintModel.fromJson(data);
      }).toList();
    });
  }

  // Get a single complaint
  Future<ComplaintModel?> getComplaint(String complaintId) async {
    final doc = await _firestore.collection(_collection).doc(complaintId).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    return ComplaintModel.fromJson(data);
  }

  // Update complaint (for admin response)
  Future<void> updateComplaint({
    required String complaintId,
    ComplaintStatus? status,
    String? adminResponse,
    String? respondedBy,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (status != null) {
      updates['status'] = status.toString().split('.').last;
    }

    if (adminResponse != null) {
      updates['adminResponse'] = adminResponse;
      updates['respondedAt'] = DateTime.now().toIso8601String();
    }

    if (respondedBy != null) {
      updates['respondedBy'] = respondedBy;
    }

    await _firestore.collection(_collection).doc(complaintId).update(updates);
  }

  // Get complaint statistics
  Future<Map<String, int>> getComplaintStats(String driverId) async {
    final complaints = await getComplaints(driverId: driverId, limit: 1000);

    return {
      'total': complaints.length,
      'pending':
          complaints.where((c) => c.status == ComplaintStatus.pending).length,
      'inProgress': complaints
          .where((c) => c.status == ComplaintStatus.inProgress)
          .length,
      'resolved':
          complaints.where((c) => c.status == ComplaintStatus.resolved).length,
      'rejected':
          complaints.where((c) => c.status == ComplaintStatus.rejected).length,
    };
  }
}
