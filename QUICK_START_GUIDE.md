# SafeDriver Driver App - Quick Start Guide

**✅ Status**: App successfully builds and runs on Android emulator!  
**Next Step**: Configure Firebase credentials for full functionality (see Step 4)

This guide will help you quickly set up and run the SafeDriver Driver Application.

## 📋 System Requirements

- **Flutter**: ^3.5.3
- **Dart**: ^3.5.3
- **Android SDK**: Level 21+ (for Android)
- **iOS**: 11.0+ (for iOS)
- **Java**: JDK 11 or higher

## 🚀 Quick Setup (5 minutes)

### Step 1: Navigate to Project Directory
```bash
cd "g:\SafeDriver Project\safe_driver_driver_app"
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Generate Localization Files
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 4: Set up Firebase

**Android:**
1. Download `google-services.json` from [Firebase Console](https://console.firebase.google.com)
2. Copy to: `android/app/google-services.json`
3. Enable Phone Authentication in Firebase Console
4. Create Firestore collections (see FIREBASE_SETUP.md for details)

**For detailed Firebase setup instructions:**
→ See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) (Complete guide with code samples)

**iOS:**
1. Get `GoogleService-Info.plist` from Firebase Console
2. Add to Xcode project (optional for now, Android first)

### Step 5: Run the App
```bash
flutter run
```

## 📁 Project Structure Overview

```
safe_driver_driver_app/
├── lib/                    # Main Dart code
│   ├── models/            # Data models
│   ├── services/          # Firebase & API services
│   ├── providers/         # Riverpod state management
│   ├── screens/           # UI screens
│   ├── core/themes/       # Theme configuration
│   └── main.dart          # App entry point
├── android/               # Android native code
├── ios/                   # iOS native code
└── l10n/                  # Localization files
```

## 🔑 Key Features Implementation

### Authentication Flow
```
Phone Number Input → Validate → Send OTP → Enter OTP → Firebase Auth → Dashboard
```

### Data Flow
```
Firebase Firestore → Riverpod Streams → UI Widgets → Real-time Updates
```

## 🎨 Customization

### Change Theme Colors

Edit `lib/core/themes/app_theme.dart`:
```dart
static const Color lightPrimary = Color(0xFF1F7A3D); // Change this
```

### Add New Language

1. Create new ARB file: `lib/l10n/arb/app_xx.arb`
2. Copy strings from `app_en.arb`
3. Translate strings
4. Run: `flutter pub run build_runner build`

### Modify Dashboard Sections

Edit `lib/screens/dashboard/dashboard_screen.dart` to add/remove tabs.

## 🔧 Development Commands

```bash
# Clean and rebuild
flutter clean
flutter pub get

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Generate localization
flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format lib
```

## 🛠️ Troubleshooting

### Problem: "Pub get" fails
```bash
flutter clean
flutter pub get
```

### Problem: Localization not working
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter clean
flutter pub get
flutter run
```

### Problem: Firebase errors
- Verify Firebase project ID matches `google-services.json`
- Check Firestore security rules
- Ensure phone authentication is enabled in Firebase Console

### Problem: Build fails
```bash
# Clear all caches
flutter clean
rm -rf pubspec.lock
flutter pub get
flutter run
```

## 📱 Testing Different Devices

```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run on emulator
flutter run -d emulator-5554
```

## 🔐 Firestore Security Rules (Starter)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /drivers/{driverId} {
      allow read, write: if request.auth.uid == driverId;
    }
    match /attendance/{doc=**} {
      allow read, write: if request.auth != null;
    }
    match /buses/{doc=**} {
      allow read: if request.auth != null;
    }
    match /alerts/{doc=**} {
      allow read: if request.auth != null;
    }
    match /ratings/{doc=**} {
      allow read, write: if request.auth != null;
    }
    match /complaints/{doc=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 📊 Key Screens & Navigation

| Screen | Path | Purpose |
|--------|------|---------|
| Login | `/auth/login` | Driver authentication |
| OTP | `/auth/otp` | OTP verification |
| Dashboard | `/dashboard` | Main navigation hub |
| Attendance | `/dashboard/attendance` | View attendance records |
| Buses | `/dashboard/buses` | View assigned buses |
| Alerts | `/dashboard/alerts` | Receive and view alerts |
| Ratings | `/dashboard/ratings` | View passenger ratings |
| Complaints | `/dashboard/complaints` | Submit and track complaints |
| Profile | `/dashboard/profile` | View and update profile |
| Settings | `/settings` | Theme, language, notifications |

## 🚢 Deployment Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Test on physical devices (Android & iOS)
- [ ] Test all features and edge cases
- [ ] Update README and documentation
- [ ] Update Firebase security rules
- [ ] Set up App signing certificates
- [ ] Test APK build for Android
- [ ] Test iOS build with certificate
- [ ] Create release notes

## 📞 Support & Contact

For issues or questions:
- Check DRIVER_APP_README.md for detailed documentation
- Review comments in source code
- Check Firebase Console logs
- Test with different phone numbers and OTPs

## 🎯 Next Steps for Development

1. **Immediate**: Set up Firebase and test authentication
2. **Phase 1**: Test all dashboard features
3. **Phase 2**: Integrate real API endpoints
4. **Phase 3**: Implement location tracking
5. **Phase 4**: Add push notifications
6. **Phase 5**: Performance optimization and deployment

## 📝 Notes

- The app uses Riverpod for state management
- Firebase Realtime/Firestore for backend
- Provider for dependency injection
- Flutter localization system for i18n
- Material 3 design system

## ⚡ Performance Tips

- Use `const` constructors where possible
- Cache images locally
- Use streams for real-time data
- Lazy load list items
- Minimize widget rebuilds

---

**Status**: Ready for Development ✅
**Last Updated**: May 2025
**Version**: 1.0.0-dev

Happy coding! 🚀
