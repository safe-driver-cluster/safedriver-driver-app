import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  Stream<List<DriverAlert>> alerts(DriverProfile driver) {
    final driverId = driver.id;
    final controller = StreamController<List<DriverAlert>>();
    final sourceKeys = <String, Set<String>>{};
    final alertsByPath = <String, DriverAlert>{};
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    final pendingInitialSources = <String>{};
    var started = false;

    void emit() {
      if (pendingInitialSources.isNotEmpty) {
        debugPrint(
          '[DriverDataService.alerts.emit] waitingFor=${pendingInitialSources.length}',
        );
        return;
      }
      final alerts = alertsByPath.values.toList()
        ..sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
      debugPrint(
        '[DriverDataService.alerts.emit] driver=$driverId total=${alerts.length}',
      );
      if (!controller.isClosed) controller.add(alerts);
    }

    void listenTo(String key, Query<Map<String, dynamic>> query) {
      debugPrint('[DriverDataService.alerts.listen] source=$key');
      pendingInitialSources.add(key);
      final subscription = query.snapshots().listen(
        (snap) {
          debugPrint(
            '[DriverDataService.alerts.snapshot] source=$key count=${snap.docs.length}',
          );
          for (final oldKey in sourceKeys[key] ?? const <String>{}) {
            alertsByPath.remove(oldKey);
          }
          final nextKeys = <String>{};
          for (final doc in snap.docs) {
            final docKey = doc.reference.path;
            debugPrint(
              '[DriverDataService.alerts.doc] source=$key path=$docKey data=${doc.data()}',
            );
            nextKeys.add(docKey);
            alertsByPath[docKey] = DriverAlert.fromDoc(doc);
          }
          sourceKeys[key] = nextKeys;
          pendingInitialSources.remove(key);
          emit();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint(
            '[DriverDataService.alerts.error] source=$key error=$error',
          );
          pendingInitialSources.remove(key);
          emit();
        },
      );
      subscriptions.add(subscription);
    }

    Future<void> start() async {
      if (started) return;
      started = true;
      debugPrint(
        '[DriverDataService.alerts.start] driver=$driverId bus=${driver.currentBusId}',
      );

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateKeys = List.generate(16, (index) {
        final date = tomorrow.subtract(Duration(days: index));
        return _dateKey(date);
      });
      final deviceIds = await _alertDeviceIdsFor(driver);
      debugPrint(
        '[DriverDataService.alerts.devices] driver=$driverId devices=$deviceIds dates=$dateKeys',
      );

      listenTo(
        'flat_driverId',
        _firestore
            .collection('alerts')
            .where('driverId', isEqualTo: driverId)
            .limit(50),
      );

      for (final deviceId in deviceIds) {
        for (final dateKey in dateKeys) {
          listenTo(
            'device:$deviceId/$dateKey',
            _firestore
                .collection('alerts')
                .doc(deviceId)
                .collection(dateKey)
                .where('driver', isEqualTo: driverId)
                .limit(50),
          );
        }
      }

      for (final dateKey in dateKeys) {
        listenTo(
          'group:$dateKey',
          _firestore
              .collectionGroup(dateKey)
              .where('driver', isEqualTo: driverId)
              .limit(50),
        );
      }
    }

    controller.onListen = start;
    controller.onCancel = () async {
      debugPrint('[DriverDataService.alerts.cancel] driver=$driverId');
      await Future.wait(
        subscriptions.map((subscription) => subscription.cancel()),
      );
    };

    return controller.stream;
  }

  Future<Set<String>> _alertDeviceIdsFor(DriverProfile driver) async {
    final ids = <String>{};
    final rawDeviceId = readString(driver.raw, [
      'deviceId',
      'fingerprint_scanner_id',
      'scannerId',
    ]);
    if (rawDeviceId.isNotEmpty) ids.add(rawDeviceId);

    final bus = driver.currentBusId;
    if (bus.isEmpty) return ids;

    Future<void> addFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      String source,
    ) async {
      if (!doc.exists) {
        debugPrint('[DriverDataService.alerts.deviceLookup] $source missing');
        return;
      }
      final deviceId = readString(doc.data() ?? {}, ['deviceId']);
      debugPrint(
        '[DriverDataService.alerts.deviceLookup] $source deviceId=$deviceId',
      );
      if (deviceId.isNotEmpty) ids.add(deviceId);
    }

    final byPlate = await _firestore
        .collection('vehicles')
        .where('busNumberPlate', isEqualTo: bus)
        .limit(5)
        .get();
    debugPrint(
      '[DriverDataService.alerts.deviceLookup] vehicles.busNumberPlate=$bus count=${byPlate.docs.length}',
    );
    for (final doc in byPlate.docs) {
      await addFromDoc(doc, doc.reference.path);
    }

    await addFromDoc(
      await _firestore.collection('vehicles').doc(bus).get(),
      'vehicles/$bus',
    );

    final byBusNumber = await _firestore
        .collection('vehicles')
        .where('busNumber', isEqualTo: bus)
        .limit(5)
        .get();
    debugPrint(
      '[DriverDataService.alerts.deviceLookup] vehicles.busNumber=$bus count=${byBusNumber.docs.length}',
    );
    for (final doc in byBusNumber.docs) {
      await addFromDoc(doc, doc.reference.path);
    }

    return ids;
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
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
      final upload = await _storage
          .ref(mediaPath)
          .putFile(File(media.path), SettableMetadata(contentType: mediaType));
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

  String _guessContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
