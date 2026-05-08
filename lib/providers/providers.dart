import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safe_driver_driver_app/services/auth_service.dart';
import 'package:safe_driver_driver_app/services/firestore_service.dart';
import 'package:safe_driver_driver_app/models/models.dart';

// Shared Preferences Provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Services
final authServiceProvider = Provider((ref) => AuthService());
final firestoreServiceProvider = Provider((ref) => FirestoreService());

// Theme Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier(false);
});

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier(bool isDarkMode) : super(isDarkMode);

  void toggleTheme() {
    state = !state;
  }

  Future<void> setTheme(bool isDarkMode) async {
    state = isDarkMode;
  }
}

// Language Provider
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier('en');
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier(String language) : super(language);

  void setLanguage(String language) {
    state = language;
  }
}

// Authentication Providers
final currentUserProvider = StreamProvider((ref) {
  final authService = ref.watch(authServiceProvider);
  return Stream.value(authService.getCurrentUser());
});

final isAuthenticatedProvider = StateProvider<bool>((ref) {
  return false;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUserId();
});

// Driver Data Providers
final driverDataProvider = FutureProvider.family<DriverModel?, String>((ref, driverId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getDriverById(driverId);
});

final attendanceStreamProvider = StreamProvider.family<List<AttendanceModel>, String>((ref, driverId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAttendanceStream(driverId);
});

final busesStreamProvider = StreamProvider.family<List<BusModel>, String>((ref, driverId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getBusesStream(driverId);
});

final alertsStreamProvider = StreamProvider.family<List<AlertModel>, String>((ref, driverId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAlertsStream(driverId);
});

final ratingsStreamProvider = StreamProvider.family<List<RatingModel>, String>((ref, driverId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getRatingsStream(driverId);
});

final complaintsStreamProvider = StreamProvider.family<List<ComplaintModel>, String>((ref, driverId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getComplaintsStream(driverId);
});

// Check-in Status Provider
final checkedInProvider = StateProvider<bool>((ref) {
  return false;
});
