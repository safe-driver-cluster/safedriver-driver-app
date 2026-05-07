import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/driver_model.dart';

// Current authenticated driver provider
final authDriverProvider =
    StateNotifierProvider<AuthDriverNotifier, AsyncValue<DriverModel?>>((ref) {
  return AuthDriverNotifier();
});

class AuthDriverNotifier extends StateNotifier<AsyncValue<DriverModel?>> {
  AuthDriverNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _init() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadDriverData(user.phoneNumber ?? '');
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> _loadDriverData(String phoneNumber) async {
    try {
      final query = await _firestore
          .collection('drivers')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        data['id'] = query.docs.first.id;
        final driver = DriverModel.fromJson(data);
        state = AsyncValue.data(driver);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> setDriver(DriverModel driver) async {
    state = AsyncValue.data(driver);
  }

  Future<void> updateDriver(DriverModel driver) async {
    try {
      await _firestore
          .collection('drivers')
          .doc(driver.id)
          .update(driver.toJson());
      state = AsyncValue.data(driver);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfileImage(String driverId, String imageUrl) async {
    try {
      await _firestore.collection('drivers').doc(driverId).update({
        'profileImageUrl': imageUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final currentDriver = state.value;
      if (currentDriver != null) {
        state =
            AsyncValue.data(currentDriver.copyWith(profileImageUrl: imageUrl));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> refreshDriver() async {
    final currentDriver = state.value;
    if (currentDriver != null) {
      await _loadDriverData(currentDriver.phoneNumber);
    }
  }
}

// Helper provider to get current driver ID
final currentDriverIdProvider = Provider<String?>((ref) {
  final authDriver = ref.watch(authDriverProvider);
  return authDriver.value?.id;
});
