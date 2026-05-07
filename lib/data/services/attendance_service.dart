import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'attendance';

  // Clock in
  Future<AttendanceModel> clockIn({
    required String driverId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final now = DateTime.now();
    final attendance = AttendanceModel(
      id: '',
      driverId: driverId,
      clockInTime: now,
      clockInLocation: LocationData(
        latitude: latitude,
        longitude: longitude,
        address: address,
        timestamp: now,
      ),
      status: AttendanceStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    final docRef =
        await _firestore.collection(_collection).add(attendance.toJson());
    return attendance.copyWith(id: docRef.id);
  }

  // Clock out
  Future<AttendanceModel> clockOut({
    required String attendanceId,
    required double latitude,
    required double longitude,
    String? address,
    String? notes,
  }) async {
    final now = DateTime.now();
    final docRef = _firestore.collection(_collection).doc(attendanceId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Attendance record not found');
    }

    final attendance = AttendanceModel.fromJson(doc.data()!);
    final totalHours = now.difference(attendance.clockInTime).inMinutes / 60.0;

    final updatedAttendance = attendance.copyWith(
      clockOutTime: now,
      clockOutLocation: LocationData(
        latitude: latitude,
        longitude: longitude,
        address: address,
        timestamp: now,
      ),
      status: AttendanceStatus.completed,
      totalHours: totalHours,
      notes: notes,
      updatedAt: now,
    );

    await docRef.update(updatedAttendance.toJson());
    return updatedAttendance;
  }

  // Get today's attendance for a driver
  Future<AttendanceModel?> getTodayAttendance(String driverId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = await _firestore
        .collection(_collection)
        .where('driverId', isEqualTo: driverId)
        .where('clockInTime',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('clockInTime', isLessThan: endOfDay.toIso8601String())
        .orderBy('clockInTime', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final data = query.docs.first.data();
    data['id'] = query.docs.first.id;
    return AttendanceModel.fromJson(data);
  }

  // Get attendance history for a driver
  Future<List<AttendanceModel>> getAttendanceHistory({
    required String driverId,
    int limit = 30,
  }) async {
    final query = await _firestore
        .collection(_collection)
        .where('driverId', isEqualTo: driverId)
        .orderBy('clockInTime', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return AttendanceModel.fromJson(data);
    }).toList();
  }

  // Stream today's attendance
  Stream<AttendanceModel?> streamTodayAttendance(String driverId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(_collection)
        .where('driverId', isEqualTo: driverId)
        .where('clockInTime',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('clockInTime', isLessThan: endOfDay.toIso8601String())
        .orderBy('clockInTime', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return AttendanceModel.fromJson(data);
    });
  }
}
