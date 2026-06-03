import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/driver_models.dart';

class DriverDataService {
  DriverDataService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

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
          .where('busNumber', isEqualTo: driver.currentBusId)
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
    XFile? media,
  }) async {
    final doc = _firestore.collection('driverComplaints').doc();
    String? mediaUrl;
    String? mediaPath;
    String? mediaType;
    String? mediaName;

    if (media != null) {
      mediaName = media.name;
      mediaType = media.mimeType ?? _guessContentType(media.path);
      mediaPath = 'driverComplaints/$driverId/${doc.id}/$mediaName';
      final upload = await _storage
          .ref(mediaPath)
          .putFile(File(media.path), SettableMetadata(contentType: mediaType));
      mediaUrl = await upload.ref.getDownloadURL();
    }

    return doc.set({
      'driverId': driverId,
      'title': title,
      'message': message,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaPath != null) 'mediaPath': mediaPath,
      if (mediaType != null) 'mediaType': mediaType,
      if (mediaName != null) 'mediaName': mediaName,
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

  String _guessContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
