import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/alert_model.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'alerts';

  // Get alerts for a driver
  Future<List<AlertModel>> getAlerts({
    required String driverId,
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .where('targetDrivers', arrayContains: driverId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return AlertModel.fromJson(data);
    }).toList();
  }

  // Stream alerts for a driver
  Stream<List<AlertModel>> streamAlerts({
    required String driverId,
    bool unreadOnly = false,
  }) {
    Query query = _firestore
        .collection(_collection)
        .where('targetDrivers', arrayContains: driverId)
        .orderBy('createdAt', descending: true)
        .limit(50);

    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AlertModel.fromJson(data);
      }).toList();
    });
  }

  // Mark alert as read
  Future<void> markAsRead(String alertId) async {
    await _firestore.collection(_collection).doc(alertId).update({
      'isRead': true,
    });
  }

  // Mark all alerts as read for a driver
  Future<void> markAllAsRead(String driverId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('targetDrivers', arrayContains: driverId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Get unread count
  Future<int> getUnreadCount(String driverId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('targetDrivers', arrayContains: driverId)
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  // Stream unread count
  Stream<int> streamUnreadCount(String driverId) {
    return _firestore
        .collection(_collection)
        .where('targetDrivers', arrayContains: driverId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
