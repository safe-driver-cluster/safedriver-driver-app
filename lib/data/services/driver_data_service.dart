import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/driver_models.dart';

class DriverDataService {
  DriverDataService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<AttendanceRecord>> attendance(String driverId) {
    return _query('attendance', driverId).snapshots().map(
      (snap) => snap.docs.map(AttendanceRecord.fromDoc).toList(),
    );
  }

  Stream<List<DriverAlert>> alerts(String driverId) {
    return _query(
      'alerts',
      driverId,
    ).snapshots().map((snap) => snap.docs.map(DriverAlert.fromDoc).toList());
  }

  Stream<List<DriverFeedback>> feedback(String driverId) {
    return _query(
      'feedback',
      driverId,
    ).snapshots().map((snap) => snap.docs.map(DriverFeedback.fromDoc).toList());
  }

  Stream<List<DriverBus>> buses(DriverProfile driver) {
    var query = _firestore.collection('buses').limit(50);
    if (driver.currentBusId.isNotEmpty) {
      query = _firestore
          .collection('buses')
          .where(FieldPath.documentId, isEqualTo: driver.currentBusId)
          .limit(10);
    }
    return query.snapshots().map(
      (snap) => snap.docs.map(DriverBus.fromDoc).toList(),
    );
  }

  Future<void> submitComplaint({
    required String driverId,
    required String title,
    required String message,
  }) {
    return _firestore.collection('driverComplaints').add({
      'driverId': driverId,
      'title': title,
      'message': message,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfilePhoto(String driverId, String url) {
    return _firestore.collection('drivers').doc(driverId).set({
      'profileImageUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Query<Map<String, dynamic>> _query(String collection, String driverId) {
    return _firestore
        .collection(collection)
        .where('driverId', isEqualTo: driverId)
        .limit(50);
  }
}
