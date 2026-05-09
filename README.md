# 🚗 SafeDriver - Driver Application

> A comprehensive mobile application for professional drivers to manage routes, safety alerts, communications, and performance metrics.

[![Flutter](https://img.shields.io/badge/Flutter-3.9-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)](https://flutter.dev)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
- [Installation & Setup](#-installation--setup)
- [Firebase Configuration](#-firebase-configuration)
- [Running the App](#-running-the-app)
- [Project Architecture](#-project-architecture)
- [Dependencies](#-dependencies)
- [Key Features Explained](#-key-features-explained)
- [Development Guidelines](#-development-guidelines)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

**SafeDriver** is a cutting-edge mobile application designed specifically for professional drivers and fleet managers. The application provides real-time monitoring, safety alerts, performance tracking, and comprehensive communication tools to enhance driver safety and fleet operations.

The app is built with **Flutter** for cross-platform compatibility (iOS, Android, Web, macOS, Linux) and integrates with **Firebase** for authentication, real-time data synchronization, cloud functions, and storage management.

---

## ✨ Features

### 🔐 **Authentication & Security**
- ✅ Phone number-based authentication with OTP verification
- ✅ Firebase authentication integration
- ✅ Secure session management
- ✅ Encrypted data storage
- ✅ Biometric login support (optional)

### 📍 **Location & Navigation**
- ✅ Real-time GPS tracking
- ✅ Route mapping and optimization
- ✅ Geolocation-based alerts
- ✅ Area coverage monitoring
- ✅ Historical route tracking

### ⚠️ **Safety & Alerts**
- ✅ Real-time safety alerts
- ✅ Speed limit warnings
- ✅ Hazard notifications
- ✅ Weather alerts
- ✅ Traffic congestion warnings

### 📞 **Communication**
- ✅ In-app messaging
- ✅ Push notifications
- ✅ Support ticketing system
- ✅ Complaint management
- ✅ Real-time chat

### 📊 **Performance & Analytics**
- ✅ Driver rating system
- ✅ Performance metrics dashboard
- ✅ Trip history and statistics
- ✅ Safety score tracking
- ✅ Attendance management

### 🎨 **User Experience**
- ✅ Multi-language support (i18n)
- ✅ Dark and light theme modes
- ✅ Responsive UI design
- ✅ Smooth animations
- ✅ Material Design 3

### 👤 **Profile Management**
- ✅ Driver profile customization
- ✅ Personal information management
- ✅ Document uploads
- ✅ Performance history
- ✅ Badge and achievement tracking

### 🚌 **Fleet Management**
- ✅ Bus/vehicle assignment
- ✅ Multiple vehicle tracking
- ✅ Vehicle maintenance alerts
- ✅ Fuel monitoring
- ✅ Vehicle status updates

---

## 🛠️ Tech Stack

### **Frontend**
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **Material Design 3** - UI design system
- **Provider / GetX** - State management

### **Backend & Services**
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - Real-time database
- **Firebase Storage** - File storage
- **Cloud Functions** - Serverless functions
- **Firebase Messaging** - Push notifications

### **Additional Libraries**
- **Geolocator** - GPS and geolocation
- **Image Picker** - Camera and gallery integration
- **Shared Preferences** - Local storage
- **Intl** - Internationalization
- **Flutter Localizations** - Multi-language support

---

## 📁 Project Structure

```
lib/
├── main.dart                      # Application entry point
├── app/
│   └── routes.dart               # App routing configuration
├── config/
│   └── firebase_config.dart      # Firebase initialization
├── core/
│   ├── constants/                # App-wide constants
│   ├── theme/                    # Theme configuration
│   │   └── app_theme.dart       # Light & dark themes
│   └── utils/                    # Utility functions
├── data/
│   ├── models/                   # Data models
│   │   ├── driver_model.dart
│   │   ├── trip_model.dart
│   │   ├── alert_model.dart
│   │   └── ...
│   └── services/                 # Backend services
│       ├── driver_auth_service.dart    # Authentication
│       └── driver_data_service.dart    # Data operations
├── l10n/
│   └── app_localizations.dart   # Translation strings
├── presentation/
│   ├── pages/                    # Screen pages
│   │   ├── auth/                # Authentication screens
│   │   │   ├── splash_page.dart
│   │   │   ├── login_page.dart
│   │   │   └── otp_page.dart
│   │   ├── dashboard/           # Main dashboard
│   │   │   └── driver_dashboard_page.dart
│   │   ├── alerts/              # Safety alerts
│   │   ├── attendance/          # Attendance tracking
│   │   ├── buses/               # Bus/vehicle management
│   │   ├── complaints/          # Complaint reporting
│   │   ├── maps/                # Map & location
│   │   ├── profile/             # User profile
│   │   ├── ratings/             # Performance ratings
│   │   ├── settings/            # App settings
│   │   ├── support/             # Support & help
│   │   ├── language/            # Language selection
│   │   ├── onboarding/          # Onboarding flow
│   │   └── pages.dart           # Page exports
│   ├── viewmodels/              # Business logic
│   │   ├── auth_viewmodel.dart
│   │   ├── dashboard_viewmodel.dart
│   │   └── ...
│   └── widgets/                 # Reusable widgets
│       ├── common_widgets.dart
│       ├── custom_buttons.dart
│       └── ...
├── state/
│   └── app_controller.dart      # Global app state
├── firebase_options.dart        # Firebase config
└── assets/
    └── images/                  # Image assets
```

---

## 📱 Prerequisites

Before running the SafeDriver app, ensure you have the following installed:

### **Required**
- 🔹 **Flutter SDK** v3.9.0 or higher ([Install Flutter](https://flutter.dev/docs/get-started/install))
- 🔹 **Dart SDK** v3.9.0 or higher (comes with Flutter)
- 🔹 **Git** version control
- 🔹 **Firebase Account** ([Create Firebase Project](https://firebase.google.com))

### **Platform-Specific Requirements**

#### **Android**
- Android SDK 21 or higher
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device

#### **iOS**
- Xcode 13.0 or higher
- iOS 12.0 or higher
- CocoaPods
- Physical iPhone or iOS Simulator

#### **Web (Optional)**
- Chrome or any modern browser

---

## 🚀 Getting Started

### **Step 1: Clone the Repository**

```bash
git clone https://github.com/yourusername/safedriver-driver-app.git
cd safedriver-driver-app
```

### **Step 2: Install Flutter Dependencies**

```bash
flutter pub get
```

### **Step 3: Set Up Firebase**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new Firebase project or select existing one
3. Enable required services:
   - ✅ Authentication (Phone)
   - ✅ Cloud Firestore
   - ✅ Cloud Storage
   - ✅ Cloud Functions
   - ✅ Firebase Messaging

### **Step 4: Configure Firebase for Your Platform**

Follow the [Firebase setup guide](https://firebase.flutter.dev/docs/overview) for your target platform.

---

## ⚙️ Installation & Setup

### **1. Flutter Setup**

```bash
# Check Flutter installation
flutter doctor

# Upgrade Flutter
flutter upgrade

# Get all dependencies
flutter pub get
```

### **2. Firebase Configuration**

#### **Android Setup**
```bash
# Download google-services.json from Firebase console
# Place it in: android/app/google-services.json

# Verify Gradle configuration
gradle wrapper --gradle-version 8.x.x
```

#### **iOS Setup**
```bash
# Download GoogleService-Info.plist from Firebase console
# Place it in: ios/Runner/GoogleService-Info.plist

# Install CocoaPods dependencies
cd ios
pod install
cd ..
```

### **3. Generate Localizations**

```bash
# Generate localization files
flutter gen-l10n
```

### **4. Build Runner (if needed)**

```bash
# Generate code from annotations
flutter pub run build_runner build
```

---

## 🔥 Firebase Configuration

### **Required Firestore Collections**

```
drivers/
├── {driverId}/
│   ├── personalInfo
│   ├── documents
│   ├── emergencyContact
│   └── settings

trips/
├── {tripId}/
│   ├── routeInfo
│   ├── checkpoints
│   ├── safetyMetrics
│   └── timestamps

alerts/
├── {alertId}/
│   ├── type
│   ├── severity
│   ├── location
│   └── timestamp

complaints/
├── {complaintId}/
│   ├── description
│   ├── category
│   ├── status
│   └── createdAt
```

### **Firebase Authentication Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /drivers/{document=**} {
      allow read, write: if request.auth.uid == document;
    }
    match /trips/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## ▶️ Running the App

### **Development Mode**

```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d <device_id>

# Run with verbose output
flutter run -v

# Run with specific flavor
flutter run --flavor development
```

### **Release Build**

#### **Android**
```bash
# Build APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

#### **iOS**
```bash
# Build iOS app
flutter build ios --release

# Create IPA for distribution
flutter build ios --release
```

### **Web**

```bash
# Enable web support
flutter config --enable-web

# Run on web
flutter run -d chrome

# Build web
flutter build web --release
```

---

## 🏗️ Project Architecture

### **Architecture Pattern: MVVM + Layered Architecture**

```
Presentation Layer
    ↓
├── Pages (UI)
├── ViewModels (Business Logic)
└── Widgets (Reusable UI)
    ↓
State Management Layer
    ↓
├── AppController (Global State)
└── Local State (Provider/GetX)
    ↓
Data Layer
    ↓
├── Services (Firebase, API calls)
├── Models (Data structures)
└── Repositories (Data access)
```

### **Data Flow**

```
UI (Pages) 
  ↓
ViewModel (Logic Processing)
  ↓
Services (Data Fetching)
  ↓
Firebase (Backend)
  ↓
Response flows back to UI
```

---

## 📦 Dependencies

### **Core Dependencies**

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | Latest | UI framework |
| `flutter_localizations` | Latest | Multi-language support |
| `cupertino_icons` | ^1.0.8 | iOS icons |

### **Firebase Services**

| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^2.32.0 | Firebase initialization |
| `firebase_auth` | ^4.20.0 | User authentication |
| `cloud_firestore` | ^4.17.5 | Real-time database |
| `cloud_functions` | ^4.7.6 | Serverless backend |
| `firebase_storage` | ^11.7.7 | File storage |

### **Utility Libraries**

| Package | Version | Purpose |
|---------|---------|---------|
| `image_picker` | ^1.0.4 | Camera & gallery |
| `geolocator` | ^10.1.0 | GPS & location |
| `shared_preferences` | ^2.2.2 | Local storage |
| `intl` | ^0.20.0 | Localization |

### **Dev Dependencies**

```yaml
flutter_test: Latest
flutter_lints: ^5.0.0
```

---

## 💡 Key Features Explained

### **🔐 Authentication Flow**

1. **Splash Screen** → App initialization and data loading
2. **Language Selection** → User chooses preferred language
3. **Onboarding** → First-time user tutorial
4. **Phone Login** → Enter phone number
5. **OTP Verification** → Enter received OTP code
6. **Dashboard** → Main application screen

```dart
// Authentication flow in routes.dart
splash → language → onboarding → login → otp → dashboard
```

### **📍 Real-time Location Tracking**

- Uses `geolocator` package for continuous GPS tracking
- Sends location updates to Firebase every 5-10 seconds
- Calculates distance, speed, and route efficiency

### **🚨 Alert System**

- Speed limit monitoring
- Hazard detection
- Weather warnings
- Traffic alerts
- Emergency notifications

### **💬 Communication System**

- Real-time messaging via Firebase
- Push notifications using Firebase Messaging
- Support ticket system with status tracking
- Complaint logging with category classification

### **📊 Performance Dashboard**

- Daily, weekly, and monthly statistics
- Safety rating calculation
- Trip history with detailed analytics
- Performance badges and achievements

---

## 👨‍💻 Development Guidelines

### **Code Style**

```dart
// ✅ DO: Use meaningful variable names
final userLocation = Position(latitude: 40.7128, longitude: -74.0060);

// ❌ DON'T: Use abbreviations
final uLoc = Position(latitude: 40.7128, longitude: -74.0060);
```

### **State Management Best Practices**

```dart
// Use ChangeNotifier for observable state
class DashboardViewModel extends ChangeNotifier {
  void updateData() {
    // Update logic
    notifyListeners();
  }
}
```

### **Firebase Best Practices**

```dart
// Use security rules and validation
// Always validate data before storing
// Optimize queries with indexes
// Use transactions for data consistency
```

### **Widget Organization**

- Keep widgets focused and single-responsibility
- Extract reusable widgets to `presentation/widgets/`
- Use const constructors where possible
- Add comprehensive comments for complex logic

### **Testing**

```bash
# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test
flutter test test/widget_test.dart
```

---

## 🐛 Troubleshooting

### **Issue: Firebase Initialization Error**

**Solution:**
```bash
# Clean Flutter cache
flutter clean

# Get dependencies again
flutter pub get

# Verify firebase_options.dart exists
# Check Firebase console configuration
```

### **Issue: Build Fails on iOS**

**Solution:**
```bash
# Clean iOS build
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..

# Rebuild
flutter clean
flutter pub get
flutter run
```

### **Issue: Android Gradle Error**

**Solution:**
```bash
# Update Gradle
android/gradlew wrapper --gradle-version 8.x.x

# Clear Gradle cache
./gradlew clean

# Rebuild
flutter clean
flutter pub get
flutter run
```

### **Issue: Location Permission Denied**

**Solution:**
```bash
# For Android: Check AndroidManifest.xml permissions
# For iOS: Check Info.plist permissions
# Request permissions at runtime
```

### **Issue: Firestore Connection Issues**

**Solution:**
```dart
// Add connectivity check
// Implement offline persistence
// Use proper error handling
// Verify Firestore security rules
```

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### **1. Fork the Repository**
```bash
git clone https://github.com/yourusername/safedriver-driver-app.git
```

### **2. Create a Feature Branch**
```bash
git checkout -b feature/your-feature-name
```

### **3. Make Your Changes**
- Write clean, readable code
- Follow the existing code style
- Add comments for complex logic
- Test your changes thoroughly

### **4. Commit Your Changes**
```bash
git commit -m "feat: add your feature description"
```

### **5. Push to Your Fork**
```bash
git push origin feature/your-feature-name
```

### **6. Create a Pull Request**
- Describe your changes clearly
- Reference any related issues
- Wait for code review

### **Commit Message Convention**

```
feat: add new feature
fix: fix bug in existing feature
docs: update documentation
style: format code
refactor: restructure code
test: add or update tests
chore: update dependencies
```

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support & Contact

### **Getting Help**

- 📧 **Email**: support@safedriver.com
- 💬 **Discord**: [Join Community](https://discord.gg/safedriver)
- 🐛 **Issue Tracker**: [GitHub Issues](https://github.com/yourusername/safedriver-driver-app/issues)
- 📖 **Documentation**: [Docs](https://docs.safedriver.com)

### **Social Media**

- 🐦 **Twitter**: [@SafeDriver](https://twitter.com/SafeDriver)
- 📘 **Facebook**: [SafeDriver Official](https://facebook.com/SafeDriver)
- 📺 **YouTube**: [SafeDriver Channel](https://youtube.com/SafeDriver)

---

## 🎯 Roadmap

- [ ] Offline mode support
- [ ] Advanced analytics dashboard
- [ ] AI-powered safety predictions
- [ ] Integration with vehicle diagnostics
- [ ] Multi-language support expansion
- [ ] Voice command feature
- [ ] Augmented reality features
- [ ] Blockchain-based safety verification

---

## 📊 Statistics

- 📱 **Platforms**: Android, iOS, Web, macOS, Linux
- 🌍 **Languages**: English, Spanish, French, Arabic, Hindi (extensible)
- 🔌 **Services**: Firebase (Auth, Firestore, Storage, Functions)
- 📦 **Packages**: 10+ integrated dependencies
- 🎨 **UI Framework**: Material Design 3

---

## ✅ Checklist for New Developers

- [ ] Install Flutter SDK
- [ ] Clone the repository
- [ ] Run `flutter pub get`
- [ ] Set up Firebase project
- [ ] Configure Firebase for Android/iOS
- [ ] Run `flutter run`
- [ ] Explore the codebase
- [ ] Read contribution guidelines
- [ ] Set up IDE with Flutter extensions

---

## 🎉 Thank You!

Thank you for using **SafeDriver**! We're committed to making roads safer, one driver at a time.

### **Show Your Support**

⭐ If you like this project, please give it a star on GitHub!

---

**Last Updated**: May 9, 2026
**Version**: 1.0.0
**Maintainer**: SafeDriver Team

