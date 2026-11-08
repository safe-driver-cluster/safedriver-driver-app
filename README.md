<div align="center">
  <img src="assets/images/logo.png" alt="SafeDriver logo" width="170" />
  <h1>🚌 SafeDriver · Driver App</h1>
  <p><strong>Your daily driving information, connected in one place.</strong></p>
  <p>A Flutter application for registered drivers in the SafeDriver transport system.</p>
  <p>
    <img src="https://img.shields.io/badge/Flutter-Cross_Platform-02569B?logo=flutter&amp;logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-%5E3.9.0-0175C2?logo=dart&amp;logoColor=white" alt="Dart SDK ^3.9.0" />
    <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&amp;logoColor=black" alt="Firebase" />
    <img src="https://img.shields.io/badge/Version-1.0.0%2B6-16A34A" alt="Version 1.0.0+6" />
    <img src="https://img.shields.io/badge/Languages-EN_|_SI_|_TA-7C3AED" alt="English, Sinhala and Tamil" />
  </p>
  <p>📍 Maps &nbsp; · &nbsp; 🔔 Alerts &nbsp; · &nbsp; 📋 Attendance &nbsp; · &nbsp; ⭐ Ratings</p>
</div>

---

## 📖 Contents

- [Overview](#-overview)
- [Features](#-features)
- [Brand artwork](#-brand-artwork)
- [Technology stack](#-technology-stack)
- [Project structure](#-project-structure)
- [Getting started](#-getting-started)
- [Firebase and SMS backend](#-firebase-and-sms-backend)
- [Authentication flow](#-authentication-flow)
- [Data model](#-data-model)
- [Maps and permissions](#-maps-and-permissions)
- [Build and deployment](#-build-and-deployment)
- [Quality checks](#-quality-checks)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🌟 Overview

SafeDriver gives drivers access to their profile, assigned vehicle, attendance records, safety alerts, passenger feedback, and support tools. Firebase provides authentication, data access, and attachment storage. A Node.js Cloud Functions backend integrates Text.lk SMS verification.

Driver login requires an existing active driver record. This application does not provide public driver registration.

The repository includes Android, iOS, web, Windows, macOS, and Linux folders. These folders do not establish full platform support: Firebase configuration, Maps setup, and plugin compatibility must be verified for each target. Android and web have explicit map implementations; iOS requires additional setup.

## ✨ Features

| Feature | Driver capabilities |
| --- | --- |
| 🔐 Phone authentication | Request, resend, and verify an SMS OTP; sign in with a Firebase custom token. |
| 🏠 Dashboard | View driver information and access app sections. |
| 📋 Attendance | Review recorded shifts from a rolling 14-day window. Attendance is read-only in this app. |
| 🔔 Alerts | Retrieve driver-related alerts through the `driverAlerts` callable function. |
| 🚌 Assigned buses | View vehicle details, including compatibility lookups for legacy bus records. |
| 🗺️ Maps | Show the current position, inspect hazards, and open external Google Maps navigation. |
| ⭐ Ratings | View passenger feedback, rating summaries, and filters by star count. |
| 📝 Complaints | Submit complaints with an optional photo or video attachment and review history. |
| 💬 Support | Submit support requests and view previous requests. |
| 👤 Profile | View driver information; the data service also exposes profile image URL updates. |
| 🌐 Languages | Choose English (`en`), Sinhala (`si`), or Tamil (`ta`). |
| 🎨 Appearance | Use light and dark themes with persisted preferences. |
| 🚪 Session controls | Restore an authenticated driver session and sign out with confirmation. |

Attendance, feedback, complaints, support requests, vehicles, and hazards use Firestore streams where implemented. Alerts are fetched through a callable function rather than a continuous subscription.

## 🖼️ Brand artwork

These are the app's existing onboarding illustrations, rather than screenshots of running screens.

<table>
  <tr>
    <td align="center"><img src="assets/images/onboard-01.png" alt="Onboarding artwork 1" width="220" /></td>
    <td align="center"><img src="assets/images/onboard-02.png" alt="Onboarding artwork 2" width="220" /></td>
    <td align="center"><img src="assets/images/onboard-03.png" alt="Onboarding artwork 3" width="220" /></td>
  </tr>
</table>

Brand assets live in [`assets/images/`](assets/images/). Local image paths keep the logo and artwork available when viewing this README offline; technology badges require internet access.

## 🧰 Technology stack

| Layer | Technologies |
| --- | --- |
| UI | Flutter, Material widgets, Cupertino icons |
| Language | Dart, SDK constraint `^3.9.0` |
| State and preferences | `AppController`, `AppScope`, view models, `shared_preferences` |
| Backend | Firebase Authentication, Cloud Firestore, Cloud Functions, Firebase Storage |
| Maps and location | `google_maps_flutter`, `geolocator`, OpenStreetMap web embed |
| Media and links | `image_picker`, `url_launcher` |
| Networking and configuration | `http`, `flutter_dotenv` |
| Localization | `flutter_localizations`, `intl`, custom `AppLocalizations` |
| SMS backend | Node.js 22, Firebase Admin SDK, Firebase Functions, Axios, Text.lk |
| Checks | `flutter_test`, `flutter_lints`; Jest dependency in the backend |

Dependency constraints and resolved versions are recorded in [`pubspec.yaml`](pubspec.yaml), `pubspec.lock`, and [`backend/functions/package.json`](backend/functions/package.json).

## 🗂️ Project structure

```text
safedriver-driver-app/
├── assets/images/              # Logo and onboarding artwork
├── lib/
│   ├── main.dart               # Environment, Firebase and app initialization
│   ├── app/routes.dart         # Named routes
│   ├── config/                 # Firebase configuration constants
│   ├── core/                   # Themes, constants, Maps configuration, utilities
│   ├── data/
│   │   ├── models/             # Driver and operational record models
│   │   ├── repositories/       # Map hazard repository
│   │   └── services/           # Authentication and driver data access
│   ├── l10n/                   # English, Sinhala and Tamil translations
│   ├── presentation/
│   │   ├── pages/              # Authentication, dashboard and feature screens
│   │   ├── viewmodels/         # Authentication and dashboard state
│   │   └── widgets/            # Shared UI and dashboard components
│   ├── services/               # Places, nearby stops and directions service
│   ├── state/                  # App scope and persisted preferences
│   └── firebase_options.dart   # Platform Firebase options
├── backend/functions/          # SMS authentication and alert backend
├── android/                    # Android runner, permissions and signing
├── ios/                        # iOS runner and permissions
├── web/                        # Web entry point and icons
├── windows/                    # Windows runner
├── macos/                      # macOS runner
├── linux/                      # Linux runner
├── test/                       # Flutter smoke and widget tests
├── firebase.json               # Deployment and emulator configuration
├── firestore.rules             # Firestore access rules
├── firestore.indexes.json      # Firestore indexes
├── storage.rules               # Storage access rules
└── pubspec.yaml                # Version, dependencies and bundled assets
```

Pages and view models use data services and models. Shared application preferences are exposed through `AppScope` and persisted by `AppController`.

## 🚀 Getting started

### 1. Prerequisites

- Flutter with a Dart SDK satisfying `^3.9.0`.
- Git and an editor such as Android Studio or VS Code.
- Android SDK and a compatible JDK for Android development.
- macOS, Xcode, and CocoaPods for iOS builds.
- Chrome for web development.
- Access to the intended Firebase project and an active driver record.
- Node.js **22**, npm, and the Firebase CLI for backend work.
- Text.lk credentials for real SMS delivery.

From the repository root:

```sh
flutter doctor
flutter pub get
flutter devices
```

### 2. Create the app environment file

Create `.env` in the repository root:

```dotenv
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

This file is declared as a Flutter asset and ignored by Git. Create it before running or building the app, even if you are initially working without Maps.

Android Gradle reads the value into its Maps manifest placeholder. Use a plain, unquoted value so both Gradle's properties reader and `flutter_dotenv` can read it.

The root `.env` is bundled into the client. Keep SMS tokens and server secrets in the backend environment. Restrict client Maps keys for their intended application and APIs.

### 3. Verify Firebase configuration

Startup uses [`lib/firebase_options.dart`](lib/firebase_options.dart), which currently reads constants from [`lib/config/firebase_config.dart`](lib/config/firebase_config.dart).

- Verify the project and registered application identifiers.
- The Android application ID in Gradle is `com.codecrafters.safedriver_driver`.
- Existing Firebase configuration includes placeholder iOS/web app IDs and legacy passenger identifiers. Replace them with valid driver app configuration before testing those targets.
- Keep generated options and native configuration consistent if regenerating with FlutterFire.
- The client calls functions in `asia-south1`; deploy its backend to the same region.

### 4. Prepare Android signing

The Android Gradle script creates release signing configuration unconditionally. Missing signing properties can therefore prevent even a debug build from configuring.

Obtain authorized signing files from the maintainer, or create a separate development keystore. Create `android/key.properties`:

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=C:/path/to/your/keystore.jks
```

Use an existing keystore. Relative `storeFile` paths resolve from the Android app module. Keep credentials and keystores out of commits; the root ignore file does not explicitly exclude `key.properties` or keystore files.

### 5. Run the app

```sh
# Attached device or emulator
flutter run

# Browser
flutter run -d chrome
```

Select a language, complete onboarding, and log in using a phone number associated with an active driver. Login requires available backend functions and valid Firebase configuration.

## 🔥 Firebase and SMS backend

Implementation: [`backend/functions/index.js`](backend/functions/index.js). Additional documentation: [`backend/functions/README.md`](backend/functions/README.md). Use the implementation and package manifest as the source of truth for runtime and behavior.

### Install and configure

From the repository root:

```sh
cd backend/functions
npm ci
```

Copy `.env.example` to `.env` inside the functions directory. In PowerShell:

```powershell
Copy-Item .env.example .env
```

Fill in the backend configuration:

| Variable | Purpose | Implementation default |
| --- | --- | --- |
| `TEXTLK_API_TOKEN` | SMS authentication | Required for real SMS |
| `TEXTLK_API_URL` | SMS endpoint | `https://app.text.lk/api/v3/sms/send` |
| `TEXTLK_SENDER_ID` | Sender identifier | `SafeDriver`; example file uses `TextLKDemo` |
| `FIREBASE_PROJECT_ID` | Firebase project | `safe-driver-system` |
| `FIREBASE_REGION` | Function region | `asia-south1` |
| `OTP_EXPIRY_MINUTES` | Code lifetime | `10` |
| `OTP_MAX_ATTEMPTS` | Verification attempt limit | `3` |
| `OTP_LENGTH` | Code length | `6` |
| `OTP_RATE_LIMIT_POINTS` | OTP request allowance | `3` |
| `OTP_RATE_LIMIT_DURATION` | OTP request window, seconds | `3600` |
| `VERIFICATION_RATE_LIMIT_POINTS` | Verification allowance | `5` |
| `VERIFICATION_RATE_LIMIT_DURATION` | Verification window, seconds | `300` |
| `DEBUG_MODE` | Debug logging | `false` |
| `SMS_TEMPLATE` | Message with `{OTP}` and `{MINUTES}` placeholders | Built-in verification message |

The limiter uses in-memory state, so limits apply per function instance. The backend also contains a hardcoded driver test OTP path; review it before production deployment.

### Functions

| Function | Role |
| --- | --- |
| `driverSendOTP` | Find an active driver and start verification. |
| `driverVerifyOTP` | Verify the request and return a Firebase custom token. |
| `driverAlerts` | Retrieve authenticated-driver alerts. |
| `cleanupExpiredOTPs` | Scheduled removal of expired verification records. |
| `healthCheck` | HTTP health endpoint. |

The backend also exports `sendOTP`, `verifyOTP`, and `resetPassword` for other authentication flows. This app uses the driver-specific OTP functions.

### Local emulators

With the Firebase CLI installed, run from the repository root:

```sh
firebase emulators:start --project staging
```

| Service | Port |
| --- | --- |
| Authentication | `9099` |
| Functions | `5001` |
| Firestore | `8080` |
| Hosting | `5000` |
| Storage | `9199` |
| Emulator UI | `4000` |

Starting emulators does not redirect the Flutter app automatically. Its Firebase clients currently use the configured project; add explicit emulator connections for local testing. SMS requests can still reach Text.lk unless the SMS integration is isolated.

## 🔐 Authentication flow

1. The client normalizes common Sri Lankan phone formats to `+94…`.
2. `driverSendOTP` checks driver eligibility and starts verification.
3. The driver enters the SMS code.
4. `driverVerifyOTP` validates the request and returns a custom token and driver information.
5. Firebase Authentication signs in with the custom token.
6. The app loads the driver profile and opens the dashboard.

Driver access rules depend on custom token claims such as `role` and `driverId`. Clients cannot directly read or write OTP verification records.

Named routes include `/`, `/language`, `/onboarding`, `/login`, `/otp`, `/dashboard`, and `/maps`. Other feature pages are opened within the app's navigation flow.

## 🗄️ Data model

| Collection or path | Usage |
| --- | --- |
| `drivers/{driverId}` | Profile, active status, vehicle assignment, language and authentication linkage |
| `attendance/{driverId}/{dateId}/{recordId}` | Date-grouped attendance and shifts |
| `alerts` and date-grouped alert subcollections | Alerts assembled by the backend |
| `vehicles` | Primary vehicle details |
| `buses` | Legacy vehicle lookup fallback |
| `feedback` | Passenger ratings and comments |
| `hazards` | Hazard locations and details |
| `driverComplaints` | Complaints, status and attachment metadata |
| `support_conversations` | Driver support requests |
| `otp_verifications` | Backend-only verification records |

Complaint attachments use Storage paths under `driverComplaints/{driverId}/{complaintId}/{fileName}`. The corresponding rule requires files smaller than 10 MiB.

Deploy rules and indexes to the intended project. The current Firestore rules have no explicit `hazards` rule, so those reads fall under default deny and need an appropriate rule before they can succeed.

## 📍 Maps and permissions

- **Android:** native Google Maps with a key from the root `.env`, runtime location permission, and position updates while the map screen is active.
- **Web:** the map page uses an OpenStreetMap iframe. The repository also contains a Google Maps JavaScript loader and a Places/directions service with fallback providers.
- **iOS:** camera, library, and foreground location descriptions are present in `Info.plist`. `AppDelegate.swift` does not initialize a Google Maps SDK key; complete native setup and Firebase registration before treating iOS Maps as configured.
- **Navigation:** opens an external Google Maps URL using `url_launcher`.

Android declares internet, camera, fine location, and coarse location permissions. Media selection supports complaint attachments, and foreground location supports the map's position view.

## 📦 Build and deployment

### Flutter builds

After completing platform configuration and signing:

```sh
flutter build apk --release
flutter build appbundle --release
flutter build web --release

# Requires macOS and configured iOS signing
flutter build ipa --release
```

| Build | Typical artifact |
| --- | --- |
| APK | `build/app/outputs/flutter-apk/app-release.apk` |
| App Bundle | `build/app/outputs/bundle/release/app-release.aab` |
| Web | `build/web/` |
| IPA | `build/ios/ipa/` |

### Firebase deployment

The committed `staging` alias points to `safe-driver-system`. Hosting target `driver` maps to `safe-driver-driver-app` and serves `build/web`. Verify the selected project before deploying, especially for separate environments.

From the repository root:

```sh
firebase login

# Backend functions
firebase deploy --only functions --project staging

# Firestore rules and indexes
firebase deploy --only firestore --project staging

# Storage rules
firebase deploy --only storage --project staging

# Web app — build web assets first
firebase deploy --only hosting:driver --project staging
```

These commands publish changes to the selected project. Hosting rewrites application routes to `index.html`.

## 🧪 Quality checks

From the repository root:

```sh
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test
```

Existing Flutter tests check the localized app name and a basic boot to `MaterialApp`. They do not establish end-to-end coverage for SMS, Maps, uploads, or backend permissions.

The backend defines `npm test` with Jest, but no backend test files are currently included. Add tests before relying on that command as validation.

For releases, also exercise login/logout, attendance, alerts, vehicle assignment, rating filters, complaint uploads, support submission, language persistence, themes, and permission handling on intended devices.

## 🛠️ Troubleshooting

| Symptom | Check |
| --- | --- |
| Missing `.env` asset | Create the root `.env` before running or building. |
| Null Android signing value | Supply complete `android/key.properties` and an existing keystore. Signing is configured unconditionally. |
| Driver not found | Verify an active record and matching `phoneNumber`, `phone`, `mobileNumber`, or `contactNumber`. |
| OTP not received | Check function logs, Text.lk credentials, sender, delivery status, and credits. |
| OTP rejected | Check expiry, attempt limits, verification ID, and phone consistency; request a fresh code. |
| Callable unavailable | Check project, deployed function name, network, and `asia-south1` region. |
| Firebase fails on web/iOS | Replace placeholder app IDs and legacy identifiers with valid platform configuration. |
| Native map blank | Check key, application restrictions, platform integration, and native initialization. |
| No location | Enable device location services and grant app/browser permission. |
| Firestore permission denied | Check authentication, driver claims, and deployed rules. Hazards currently need an explicit rule. |
| Profile upload fails | The service updates an image URL, but supplied Storage rules do not define a driver profile upload path. Verify the upload implementation and rule. |
| Complaint upload fails | Check driver claims, accepted media type, and file size limit. |
| Attendance incomplete | The app reads 14 days; verify driver/date subcollection layout. |
| Desktop/Linux fails | Verify plugins and Firebase options; Linux configuration explicitly throws an unsupported-platform error. |

## 🤝 Contributing

1. Create a focused branch.
2. Follow the page, view model, service, and model organization.
3. Update supported translations for user-facing changes where applicable.
4. Run formatting, analysis, and relevant tests.
5. Document changes to environment values, collections, permissions, or deployment requirements.
6. Open a pull request describing behavior and validation.

Keep backend credentials, personal driver data, and signing files out of commits. Bug reports should include platform, reproduction steps, expected behavior, and sanitized logs.

## 📄 License

No standalone license file is included. The backend README identifies this as part of SafeDriver and states that all rights are reserved. Confirm usage and redistribution permissions with the project owner.

---

<div align="center">
  <img src="assets/images/logo.png" alt="SafeDriver" width="64" />
  <p><strong>🚌 SafeDriver — connected information for every shift.</strong></p>
</div>
