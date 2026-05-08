# SafeDriver Driver App - Architecture & Design Document

## 🏗️ Architecture Overview

The SafeDriver Driver App follows a **Clean Architecture** pattern with clear separation of concerns:

```
Presentation Layer (Screens & Widgets)
         ↓
    State Management (Riverpod)
         ↓
    Business Logic (Providers)
         ↓
    Services Layer (Firebase, Firestore)
         ↓
    Data Layer (Models, Firebase)
```

## 🎯 Architectural Pattern

### Riverpod State Management

**Why Riverpod?**
- Compile-time safety
- Automatic dependency injection
- Easy testing
- Reactive programming
- No BuildContext required

**Provider Types Used:**
1. **Provider** - Simple computed values
2. **FutureProvider** - One-time async operations
3. **StreamProvider** - Real-time data streams
4. **StateNotifierProvider** - Complex state logic

### Example Flow:

```dart
// Provider Definition
final driverDataProvider = FutureProvider.family<DriverModel?, String>((ref, driverId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getDriverById(driverId);
});

// Usage in Widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final driverData = ref.watch(driverDataProvider('driver_123'));
  
  return driverData.when(
    data: (driver) => // Show data
    loading: () => // Show loading
    error: (err, stack) => // Show error
  );
}
```

## 📱 Screen Hierarchy

```
├── LoginScreen
│   ├── Phone Input → Validation
│   ├── Firebase Phone Verification
│   └── OTPScreen
│       ├── OTP Input (6 digits)
│       ├── Firebase OTP Verification
│       └── Navigate to Dashboard
│
└── DashboardScreen (Main App)
    ├── BottomNavigationBar (5 items)
    ├── Drawer (Additional Menu)
    ├── Tabs
    │   ├── HomeTab
    │   ├── AttendanceTab
    │   ├── BusesTab
    │   ├── AlertsTab
    │   └── RatingsTab
    └── SettingsScreen (from Drawer)
```

## 🔄 Data Flow Architecture

### Real-Time Data Update Flow

```
Firebase Firestore
      ↓
FirestoreService (Methods like getAttendanceStream())
      ↓
StreamProvider (attendanceStreamProvider)
      ↓
Widget (ConsumerWidget)
      ↓
UI Update (Automatic via Riverpod)
```

### Example - Attendance Tab:

```dart
// 1. Provider Definition
final attendanceStreamProvider = StreamProvider.family<List<AttendanceModel>, String>(
  (ref, driverId) {
    final firestoreService = ref.watch(firestoreServiceProvider);
    return firestoreService.getAttendanceStream(driverId);
  }
);

// 2. Service Method
Stream<List<AttendanceModel>> getAttendanceStream(String driverId) {
  return _firestore
    .collection('attendance')
    .where('driverId', isEqualTo: driverId)
    .orderBy('date', descending: true)
    .snapshots()
    .map((snapshot) => // Convert to models);
}

// 3. Widget Consumption
class AttendanceTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(attendanceStreamProvider(userId));
    
    return attendance.when(
      data: (list) => // Display list
      loading: () => // Show loading
      error: (err, stack) => // Show error
    );
  }
}
```

## 🔐 Authentication Architecture

### Phone + OTP Authentication Flow

```
1. User enters phone number
   ↓
2. LoginScreen validates phone format
   ↓
3. AuthService.verifyPhoneNumber() called
   ↓
4. Firebase sends OTP to phone
   ↓
5. OTPScreen displays 6-digit input
   ↓
6. User enters OTP
   ↓
7. PhoneAuthCredential created from OTP
   ↓
8. AuthService.signInWithCredential() called
   ↓
9. Firebase authenticates and creates session
   ↓
10. Navigate to DashboardScreen
```

### Security Features:

- ✅ Phone number validation (SL format)
- ✅ OTP timeout protection
- ✅ Secure Firebase Auth integration
- ✅ Automatic session management
- ✅ Logout clears all data

## 🎨 Theme System Architecture

### Theme Management

```
AppTheme (Static Theme Definitions)
  ├── lightTheme (ThemeData)
  └── darkTheme (ThemeData)

ThemeProvider (Riverpod StateNotifier)
  ├── Watches SharedPreferences
  ├── Persists user preference
  └── Toggles theme on demand

MaterialApp
  ├── theme: AppTheme.lightTheme
  ├── darkTheme: AppTheme.darkTheme
  └── themeMode: isDarkMode ? dark : light
```

### Color Palette

**Light Theme:**
- Primary: `#1F7A3D` (Forest Green)
- Secondary: `#2196F3` (Blue)
- Background: `#FAFAFA` (Light Gray)
- Surface: `#FFFFFF` (White)

**Dark Theme:**
- Primary: `#4CAF7F` (Light Green)
- Background: `#121212` (Almost Black)
- Surface: `#1E1E1E` (Dark Gray)

## 🌍 Localization Architecture

### Supported Languages

1. **English (en)** - Default
2. **Sinhala (si)** - Native
3. **Tamil (ta)** - Native

### i18n Implementation

```
Locale Selection (SharedPreferences)
      ↓
LanguageProvider (Riverpod StateNotifier)
      ↓
MaterialApp.locale = Locale(language)
      ↓
AppLocalizations.of(context) returns localized strings
      ↓
All strings use: locale!.stringKey
```

### Adding New Language:

1. Create `lib/l10n/arb/app_xx.arb`
2. Copy JSON structure from `app_en.arb`
3. Translate all strings
4. Run: `flutter pub run build_runner build`
5. Update LanguageProvider if needed

## 📊 Data Models & Relationships

```
Driver
  ├── ID (unique identifier)
  ├── Personal Info (name, phone, email)
  ├── License Info
  ├── Bus Assignment (busId reference)
  ├── Profile Picture (URL)
  ├── Status (active/inactive)
  └── Metrics (avg rating, total ratings)

Attendance
  ├── ID (unique)
  ├── Driver Reference (driverId)
  ├── Date (daily record)
  ├── Check-in Time
  ├── Check-out Time
  └── Status (present, absent, leave)

Bus
  ├── ID (unique)
  ├── Bus Number (identifier)
  ├── Route (name)
  ├── Capacity
  ├── Status (active, inactive)
  └── Assigned Driver Reference

Alert
  ├── ID (unique)
  ├── Driver Reference
  ├── Title
  ├── Description
  ├── Type (info, warning, error)
  └── Timestamp

Rating
  ├── ID (unique)
  ├── Driver Reference
  ├── Rating Score (1-5)
  ├── Passenger Name
  ├── Comment
  └── Timestamp

Complaint
  ├── ID (unique)
  ├── Driver Reference
  ├── Title
  ├── Description
  ├── Status (pending, resolved)
  └── Timestamp
```

## 🔄 Service Layer Architecture

### AuthService

```dart
✓ verifyPhoneNumber() - Send OTP
✓ signInWithCredential() - Verify OTP
✓ logout() - End session
✓ getCurrentUser() - Get auth user
✓ getCurrentUserId() - Get user ID
✓ checkPhoneNumberExists() - Validate phone
```

### FirestoreService

```dart
✓ getDriverById(driverId) - Fetch driver
✓ getDriverByPhone(phone) - Phone lookup
✓ updateDriverProfile() - Update info
✓ getAttendanceStream() - Real-time attendance
✓ checkIn/checkOut() - Attendance operations
✓ getBusesStream() - Real-time bus data
✓ getAlertsStream() - Real-time alerts
✓ getRatingsStream() - Real-time ratings
✓ getComplaintsStream() - Real-time complaints
✓ submitComplaint() - Create complaint
✓ updateProfilePicture() - Upload image
```

## 🎭 UI Components Architecture

### Reusable Components

1. **StatCards** - Display metrics (home_tab.dart)
2. **ListItems** - Standardized list rendering
3. **StatusBadges** - Status indicators
4. **LoadingStates** - Shimmer/progress indicators
5. **ErrorStates** - Error messages with retry
6. **EmptyStates** - No data placeholders

### Widget Classification

```
Screens (Full Page Views)
  ├── LoginScreen
  ├── OTPScreen
  ├── DashboardScreen
  └── SettingsScreen

Components (Reusable)
  ├── DrawerWidget
  ├── StatusBadge
  └── TabBars

Tabs (Dashboard Sections)
  ├── HomeTab
  ├── AttendanceTab
  ├── BusesTab
  ├── AlertsTab
  ├── RatingsTab
  ├── ComplaintsTab
  ├── ProfileTab
  ├── MapTab
  └── HelpSupportTab
```

## 🚀 Performance Optimization Strategies

### Memory Management
- Lazy loading of list items
- Stream-based real-time updates instead of polling
- Dispose pattern for controllers
- Const constructors for static widgets

### Network Optimization
- Cached Firestore queries
- Stream subscriptions instead of multiple requests
- Local SharedPreferences for user preferences

### UI Optimization
- StreamProvider for automatic rebuilds
- Selective widget rebuilds with ConsumerWidget
- Card-based layouts for natural scrolling
- Minimal widget tree depth

## 🔗 Dependency Injection

### Riverpod DI Setup

```dart
// Services
final authServiceProvider = Provider((ref) => AuthService());
final firestoreServiceProvider = Provider((ref) => FirestoreService());

// State
final currentUserIdProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUserId();
});

// Usage - No BuildContext required
final userId = ref.watch(currentUserIdProvider);
```

## 📈 Scalability Considerations

### Future-Ready Architecture

1. **Easy to Add Features**: Providers can be extended
2. **Testable**: Riverpod allows easy mocking
3. **Maintainable**: Clear separation of concerns
4. **Extensible**: Service layer can be swapped
5. **Multi-Platform**: Flutter allows iOS, Android, Web, Desktop

### Potential Extensions

- Web version using same codebase
- Desktop version (Windows/macOS)
- Push notifications service
- Offline sync mechanism
- Analytics integration

## 🛡️ Error Handling Strategy

### Error States

```
AsyncValue.when(
  data: (data) => // Success UI
  loading: () => // Loading UI
  error: (error, stack) => // Error UI with retry
)
```

### Error Types

- `FirebaseException` - Firebase operations
- `SocketException` - Network errors
- `PlatformException` - Platform-specific errors

## 📋 Firestore Security Rules

```
Rules enforce:
✓ Authentication required for all operations
✓ Drivers can only access their own data
✓ No direct admin operations from app
✓ Read-only access to shared resources (buses)
✓ Write restrictions to own complaint data only
```

---

**Architecture Version**: 1.0
**Last Updated**: May 2025
**Status**: Production Ready
