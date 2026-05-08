import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_driver_driver_app/models/models.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Driver Operations
  Future<DriverModel?> getDriverById(String driverId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(driverId).get();
      if (doc.exists) {
        return DriverModel.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'driverId': doc.id,
        });
      }
      return null;
    } catch (e) {
      print('Error fetching driver: $e');
      rethrow;
    }
  }

  Future<DriverModel?> getDriverByPhone(String phone) async {
    try {
      final snapshot = await _firestore
          .collection('drivers')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return DriverModel.fromJson({
          ...snapshot.docs.first.data() as Map<String, dynamic>,
          'driverId': snapshot.docs.first.id,
        });
      }
      return null;
    } catch (e) {
      print('Error fetching driver by phone: $e');
      rethrow;
    }
  }

  Future<void> updateDriverProfile(
    String driverId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('drivers').doc(driverId).update(data);
    } catch (e) {
      print('Error updating driver profile: $e');
      rethrow;
    }
  }

  // Attendance Operations
  Stream<List<AttendanceModel>> getAttendanceStream(String driverId) {
    return _firestore
        .collection('attendance')
        .where('driverId', isEqualTo: driverId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => AttendanceModel.fromJson({
                  ...doc.data(),
                  'attendanceId': doc.id,
                }),
              )
              .toList();
        });
  }

  Future<void> checkIn(String driverId, DateTime now) async {
    try {
      final today = DateTime(now.year, now.month, now.day);
      final docId = '$driverId-${today.toIso8601String().split('T')[0]}';

      await _firestore.collection('attendance').doc(docId).set({
        'driverId': driverId,
        'date': today.toIso8601String(),
        'checkInTime': now.toIso8601String(),
        'status': 'present',
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error checking in: $e');
      rethrow;
    }
  }

  Future<void> checkOut(String driverId, DateTime now) async {
    try {
      final today = DateTime(now.year, now.month, now.day);
      final docId = '$driverId-${today.toIso8601String().split('T')[0]}';

      await _firestore.collection('attendance').doc(docId).update({
        'checkOutTime': now.toIso8601String(),
      });
    } catch (e) {
      print('Error checking out: $e');
      rethrow;
    }
  }

  // Buses Operations
  Stream<List<BusModel>> getBusesStream(String driverId) {
    return _firestore
        .collection('buses')
        .where('assignedDriver', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BusModel.fromJson({...doc.data(), 'busId': doc.id}))
              .toList();
        });
  }

  // Alerts Operations
  Stream<List<AlertModel>> getAlertsStream(String driverId) {
    return _firestore
        .collection('alerts')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    AlertModel.fromJson({...doc.data(), 'alertId': doc.id}),
              )
              .toList();
        });
  }

  // Ratings Operations
  Stream<List<RatingModel>> getRatingsStream(String driverId) {
    return _firestore
        .collection('ratings')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    RatingModel.fromJson({...doc.data(), 'ratingId': doc.id}),
              )
              .toList();
        });
  }

  // Complaints Operations
  Stream<List<ComplaintModel>> getComplaintsStream(String driverId) {
    return _firestore
        .collection('complaints')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => ComplaintModel.fromJson({
                  ...doc.data(),
                  'complaintId': doc.id,
                }),
              )
              .toList();
        });
  }

  Future<void> submitComplaint(
    String driverId,
    ComplaintModel complaint,
  ) async {
    try {
      await _firestore.collection('complaints').add({
        'driverId': driverId,
        'title': complaint.title,
        'description': complaint.description,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error submitting complaint: $e');
      rethrow;
    }
  }

  Future<void> updateProfilePicture(String driverId, String imageUrl) async {
    try {
      await _firestore.collection('drivers').doc(driverId).update({
        'profilePictureUrl': imageUrl,
      });
    } catch (e) {
      print('Error updating profile picture: $e');
      rethrow;
    }
  }
}
