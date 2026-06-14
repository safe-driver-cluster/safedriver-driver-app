import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/driver_models.dart';

class DriverDataService {
  DriverDataService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  Stream<List<AttendanceRecord>> attendance(String driverId) {
    const lookbackDays = 14;
    final dateIds = _recentDateIds(lookbackDays);
    final recordsByDate = <String, List<AttendanceRecord>>{};
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    late final StreamController<List<AttendanceRecord>> controller;
    controller = StreamController<List<AttendanceRecord>>(
      onListen: () {
        for (final dateId in dateIds) {
          final subscription = _firestore
              .collection('attendance')
              .doc(driverId)
              .collection(dateId)
              .snapshots()
              .listen((snap) {
                recordsByDate[dateId] = snap.docs
                    .map((doc) => AttendanceRecord.fromDoc(doc, dateId: dateId))
                    .toList();
                controller.add(_attendanceShifts(dateIds, recordsByDate));
              }, onError: controller.addError);
          subscriptions.add(subscription);
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
  }

  Stream<List<DriverAlert>> alerts(DriverProfile driver) async* {
    debugPrint('[DriverDataService.alerts.start] driver=${driver.id}');
    final callable = _functions.httpsCallable(
      'driverAlerts',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 300)),
    );
    final result = await callable.call<Map<String, dynamic>>({
      'days': 10,
      'limit': 300,
    });
    final data = Map<String, dynamic>.from(result.data);
    final rawAlerts = data['alerts'] as List? ?? const [];
    final alerts = rawAlerts.map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      return DriverAlert.fromMap(map['id']?.toString() ?? '', map);
    }).toList();
    debugPrint(
      '[DriverDataService.alerts.emit] driver=${driver.id} total=${alerts.length}',
    );
    yield alerts;
  }

  Stream<List<DriverFeedback>> feedback(String driverId) {
    return _query(
      'feedback',
      driverId,
    ).snapshots().map((snap) => snap.docs.map(DriverFeedback.fromDoc).toList());
  }

  Stream<List<DriverComplaintRecord>> complaints(String driverId) {
    return _query('driverComplaints', driverId).snapshots().map(
      (snap) => snap.docs.map(DriverComplaintRecord.fromDoc).toList(),
    );
  }

  Stream<List<DriverSupportRequest>> supportRequests(String driverId) {
    return _query('support_conversations', driverId).snapshots().map(
      (snap) => snap.docs.map(DriverSupportRequest.fromDoc).toList(),
    );
  }

  Stream<List<DriverHazardZone>> hazardZones() {
    return _firestore.collection('hazards').limit(100).snapshots().map((snap) {
      final hazards = snap.docs
          .map(DriverHazardZone.fromDoc)
          .where((hazard) => hazard.hasLocation)
          .toList();
      hazards.sort((a, b) {
        final aTime = a.updatedAt ?? a.createdAt ?? DateTime(1900);
        final bTime = b.updatedAt ?? b.createdAt ?? DateTime(1900);
        return bTime.compareTo(aTime);
      });
      return hazards;
    });
  }

  Stream<List<DriverBus>> buses(DriverProfile driver) {
    var query = _firestore.collection('vehicles').limit(50);
    if (driver.currentBusId.isNotEmpty) {
      query = _firestore
          .collection('vehicles')
          .where('busNumberPlate', isEqualTo: driver.currentBusId)
          .limit(10);
    }
    return query.snapshots().asyncMap((snap) async {
      if (snap.docs.isNotEmpty || driver.currentBusId.isEmpty) {
        return snap.docs.map(DriverBus.fromDoc).toList();
      }

      final vehicleDoc = await _firestore
          .collection('vehicles')
          .doc(driver.currentBusId)
          .get();
      if (vehicleDoc.exists) return [DriverBus.fromDoc(vehicleDoc)];

      final vehicleNumberQuery = await _firestore
          .collection('vehicles')
          .where('busNumber', isEqualTo: driver.currentBusId)
          .limit(1)
          .get();
      if (vehicleNumberQuery.docs.isNotEmpty) {
        return vehicleNumberQuery.docs.map(DriverBus.fromDoc).toList();
      }

      final oldBusDoc = await _firestore
          .collection('buses')
          .doc(driver.currentBusId)
          .get();
      if (oldBusDoc.exists) return [DriverBus.fromDoc(oldBusDoc)];

      final oldBusNumberQuery = await _firestore
          .collection('buses')
          .where('busNumber', isEqualTo: driver.currentBusId)
          .limit(1)
          .get();
      if (oldBusNumberQuery.docs.isNotEmpty) {
        return oldBusNumberQuery.docs.map(DriverBus.fromDoc).toList();
      }

      final oldPlateQuery = await _firestore
          .collection('buses')
          .where('busNumberPlate', isEqualTo: driver.currentBusId)
          .limit(1)
          .get();
      return oldPlateQuery.docs.map(DriverBus.fromDoc).toList();
    });
  }

  Future<void> submitComplaint({
    required String driverId,
    required String title,
    required String message,
    String? category,
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
      final bytes = await media.readAsBytes();
      final upload = await _storage
          .ref(mediaPath)
          .putData(bytes, SettableMetadata(contentType: mediaType));
      mediaUrl = await upload.ref.getDownloadURL();
    }

    return doc.set({
      'driverId': driverId,
      'title': title,
      'message': message,
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
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

  Future<void> updateDriverLanguage(String driverId, String language) {
    return _firestore.collection('drivers').doc(driverId).set({
      'language': language,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> submitSupportRequest({
    required String driverId,
    required String driverName,
    required String category,
    required String message,
    required String priority,
  }) {
    return _firestore.collection('support_conversations').add({
      'driverId': driverId,
      'driverName': driverName,
      'category': category,
      'message': message,
      'priority': priority,
      'status': 'open',
      'source': 'driver_app',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Query<Map<String, dynamic>> _query(String collection, String driverId) {
    return _firestore
        .collection(collection)
        .where('driverId', isEqualTo: driverId)
        .limit(50);
  }

  List<String> _recentDateIds(int days) {
    final format = DateFormat('yyyy-MM-dd');
    final today = DateTime.now();
    return List.generate(days, (index) {
      final date = DateTime(today.year, today.month, today.day - index);
      return format.format(date);
    });
  }

  List<AttendanceRecord> _attendanceShifts(
    List<String> dateIds,
    Map<String, List<AttendanceRecord>> recordsByDate,
  ) {
    final shifts = <AttendanceRecord>[];
    for (final dateId in dateIds) {
      final entries = [...recordsByDate[dateId] ?? const <AttendanceRecord>[]]
        ..sort((a, b) {
          final aTime = a.checkIn ?? a.checkOut ?? a.date;
          final bTime = b.checkIn ?? b.checkOut ?? b.date;
          return aTime.compareTo(bTime);
        });

      final dayShifts = <AttendanceRecord>[];
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        dayShifts.add(
          entry.copyWith(id: '$dateId/${entry.id}', status: 'Shift ${i + 1}'),
        );
      }
      shifts.addAll(dayShifts.reversed);
    }
    return shifts;
  }

  String _guessContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
