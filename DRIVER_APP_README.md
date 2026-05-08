# SafeDriver - Driver Application

A comprehensive Flutter-based driver management application for the SafeDriver system. This app allows drivers to manage their attendance, view bus information, check ratings, submit complaints, and access real-time notifications.

## Features

### Authentication
- **Phone-based Login**: Drivers login using their registered phone number
- **OTP Verification**: Secure 6-digit OTP verification via Firebase Authentication
- **Phone Number Validation**: Supports Sri Lankan phone numbers (+94, 0, 94 formats)

### Dashboard Sections

#### 1. **Home Tab**
- Welcome card with personalized greeting
- Quick stats overview (Attendance, Bus Info, Alerts, Ratings)
- Quick action buttons (Check In, Check Out, Report Issue)

#### 2. **My Attendance**
- View attendance records with status (Present, Absent, Leave)
- Check-in and check-out times
- Date-wise attendance history

#### 3. **My Buses**
- View assigned bus information
- Bus number, route, capacity details
- Real-time bus status

#### 4. **My Alerts**
- Driver-specific alerts from admin
- Classified by type (Warning, Error, Info)
- Timestamp for each alert

#### 5. **Ratings**
- Average rating calculation
- Total number of ratings
- Recent passenger ratings with comments
- Star rating display

#### 6. **Complaints**
- Submit complaints to admin
- View complaint history with status
- Track complaint resolution

#### 7. **My Profile**
- View driver information (read-only)
- Update profile picture
- License number, bus assignment, contact details

#### 8. **Map** (Placeholder)
- Real-time location tracking
- Route visualization (coming soon)

#### 9. **Help & Support**
- FAQ section
- Contact information
- Support resources (Privacy Policy, Terms & Conditions)
- User guide

### Additional Features
- **Multi-Language Support**: English, Sinhala, Tamil
- **Dark/Light Theme**: Toggle between themes
- **Settings Page**: Customize language, theme, and notifications
- **Responsive Design**: Works on all device sizes
- **Offline Support**: Local data caching

## Prerequisites

- Flutter SDK (^3.5.3)
- Dart SDK
- Firebase project setup
- Android SDK / iOS SDK
- Git

## Installation

### 1. Clone the Repository
```bash
cd "g:\SafeDriver Project"
```

### 2. Get Dependencies
```bash
cd safe_driver_driver_app
flutter pub get
```

### 3. Generate Localization Files
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configure Firebase

#### For Android:
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/` directory
3. Update `android/build.gradle` if needed

#### For iOS:
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to iOS project using Xcode
3. Update iOS/Runner/Info.plist

### 5. Run the Application

```bash
# Run on connected device/emulator
flutter run

# Run in release mode
flutter run --release

# Run with specific device
flutter run -d <device-id>
```

## Project Structure

```
safe_driver_driver_app/
├── lib/
│   ├── core/
│   │   └── themes/
│   │       └── app_theme.dart          # Light and dark themes
│   ├── l10n/
│   │   └── arb/
│   │       ├── app_en.arb              # English translations
│   │       ├── app_si.arb              # Sinhala translations
│   │       └── app_ta.arb              # Tamil translations
│   ├── models/
│   │   └── models.dart                 # Data models for all entities
│   ├── providers/
│   │   └── providers.dart              # Riverpod state management
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart       # Phone login screen
│   │   │   └── otp_screen.dart         # OTP verification screen
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart   # Main dashboard
│   │   │   ├── drawer_widget.dart      # Navigation drawer
│   │   │   └── tabs/                   # Dashboard sections
│   │   │       ├── home_tab.dart
│   │   │       ├── attendance_tab.dart
│   │   │       ├── buses_tab.dart
│   │   │       ├── alerts_tab.dart
│   │   │       ├── ratings_tab.dart
│   │   │       ├── complaints_tab.dart
│   │   │       ├── profile_tab.dart
│   │   │       ├── map_tab.dart
│   │   │       └── help_support_tab.dart
│   │   └── settings/
│   │       └── settings_screen.dart    # Settings page
│   ├── services/
│   │   ├── auth_service.dart           # Firebase authentication
│   │   └── firestore_service.dart      # Firestore operations
│   └── main.dart                       # App entry point
├── android/                            # Android native code
├── ios/                                # iOS native code
├── l10n.yaml                           # Localization config
├── pubspec.yaml                        # Dependencies and config
└── README.md                           # This file
```

## Configuration

### Firestore Database Schema

#### Collections:

**drivers**
```
{
  driverId: string,
  name: string,
  phone: string,
  email: string,
  licenseNumber: string,
  busId: string,
  profilePictureUrl: string,
  isActive: boolean,
  createdAt: timestamp,
  averageRating: number,
  totalRatings: number
}
```

**attendance**
```
{
  attendanceId: string,
  driverId: string,
  date: timestamp,
  checkInTime: timestamp,
  checkOutTime: timestamp,
  status: string (present, absent, leave)
}
```

**buses**
```
{
  busId: string,
  busNumber: string,
  route: string,
  capacity: number,
  status: string (active, inactive),
  assignedDriver: string
}
```

**alerts**
```
{
  alertId: string,
  driverId: string,
  title: string,
  description: string,
  createdAt: timestamp,
  type: string (info, warning, error)
}
```

**ratings**
```
{
  ratingId: string,
  driverId: string,
  rating: number (1-5),
  passengerName: string,
  comment: string,
  createdAt: timestamp
}
```

**complaints**
```
{
  complaintId: string,
  driverId: string,
  title: string,
  description: string,
  status: string (pending, resolved),
  createdAt: timestamp
}
```

## Dependencies

Key Flutter packages used:
- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication
- `cloud_firestore` - Database
- `firebase_storage` - Image storage
- `flutter_riverpod` - State management
- `shared_preferences` - Local storage
- `geolocator` - Location services
- `google_maps_flutter` - Maps
- `image_picker` - Image selection
- `intl` - Internationalization

See `pubspec.yaml` for complete dependencies list.

## Theme Colors

### Light Theme
- Primary: `#1F7A3D` (Green)
- Primary Light: `#4CAF7F`
- Background: `#FAFAFA`
- Text: `#1E1E1E`

### Dark Theme
- Primary: `#4CAF7F`
- Background: `#121212`
- Surface: `#1E1E1E`
- Text: `#FFFFFF`

## Localization

The app supports three languages:
- **English (en)** - Default
- **Sinhala (si)** - සිංහල
- **Tamil (ta)** - தமிழ்

Add new strings in `lib/l10n/arb/` files and run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Authentication Flow

1. User enters phone number on login screen
2. App validates Sri Lankan phone number format
3. Firebase sends OTP to the registered phone
4. User enters 6-digit OTP on verification screen
5. Firebase verifies OTP and creates/updates session
6. User is redirected to dashboard on successful login

## API Integration

All data is fetched from Firestore in real-time using Riverpod streams:
- Attendance records update automatically
- Bus information refreshes on changes
- Alerts push notifications in real-time
- Ratings update as passengers rate

## Building for Release

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

### Issue: "Firebaseexception permission-denied"
**Solution**: Check Firestore security rules are properly configured for authenticated users

### Issue: "OTP not received"
**Solution**: 
- Verify phone number format is correct
- Check Firebase phone authentication is enabled
- Check device has internet connection

### Issue: "Localization strings not showing"
**Solution**: Run `flutter clean` and `flutter pub get`, then rebuild

### Issue: "Theme not changing"
**Solution**: Restart the app or navigate to Home tab

## Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Create a pull request

## Performance Optimization

- Lazy loading for list items
- Stream-based real-time updates
- Local caching with SharedPreferences
- Image optimization

## Future Enhancements

- [ ] Real-time location tracking with Google Maps
- [ ] Push notifications for alerts
- [ ] Offline mode with sync
- [ ] Video support for complaints
- [ ] Advanced analytics dashboard
- [ ] Biometric authentication
- [ ] QR code check-in
- [ ] Email reports

## Support

For support, contact:
- **Email**: support@safedriver.lk
- **Phone**: +94 11 234 5678
- **Address**: 123 Main Street, Colombo, Sri Lanka

## License

This project is proprietary and confidential to SafeDriver.

## Changelog

### Version 1.0.0 (Initial Release)
- ✅ Authentication system
- ✅ Dashboard with 9 sections
- ✅ Multi-language support
- ✅ Theme customization
- ✅ Real-time data integration
- ✅ Complaint management
- ✅ Rating display
- ✅ Attendance tracking

---

**Last Updated**: May 2025
**Status**: Active Development
