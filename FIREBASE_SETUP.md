# Firebase Setup Guide - SafeDriver Driver App

## Overview
The SafeDriver Driver App requires Firebase configuration to function fully. This guide will help you set up Firebase for the application.

## Prerequisites
- Firebase project created at [https://console.firebase.google.com](https://console.firebase.google.com)
- Android package name: `com.example.safe_driver_driver_app`

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a project" or select existing project
3. Name the project (e.g., "SafeDriver")
4. Proceed through the setup steps
5. Copy your **Project ID** - you'll need this

## Step 2: Configure Android

### 2.1 Add Android App to Firebase

1. In Firebase Console, click "Add app" → Select "Android"
2. Enter Android package name: `com.example.safe_driver_driver_app`
3. Enter app nickname (e.g., "Driver App")
4. Register the app
5. Download `google-services.json` file

### 2.2 Add google-services.json to Project

1. Download the `google-services.json` file from Firebase Console
2. Copy it to: `android/app/google-services.json`
   ```
   safe_driver_driver_app/
   └── android/
       └── app/
           └── google-services.json  ← Paste here
   ```

### 2.3 Update Firebase Configuration (Optional)

If your credentials differ, update `lib/firebase_options.dart`:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'your-project-id',
  storageBucket: 'your-project-id.firebasestorage.app',
);
```

Get these values from:
- Firebase Console → Project Settings → Your apps → Android

## Step 3: Enable Firebase Services

### 3.1 Authentication (Phone Number)

1. In Firebase Console, go to **Authentication**
2. Click **Get started**
3. Click **Phone** sign-in method
4. Enable it
5. Add test phone numbers (optional, for testing):
   - Example: `+1 555-0123`
   - Choose verification code: e.g., `123456`

### 3.2 Firestore Database

1. Go to **Firestore Database** in Firebase Console
2. Click **Create database**
3. Start in **Test mode** (for development)
4. Choose location (closest to your region)
5. Create collections as shown below

### 3.3 Storage

1. Go to **Storage** in Firebase Console
2. Click **Get started**
3. Start in **Test mode**
4. Choose location

### 3.4 Enable Other Services (Optional)

- **Analytics**: Go to Analytics → Enable
- **Crashlytics**: Will auto-initialize with Crashlytics SDK
- **Cloud Messaging**: For push notifications (setup later)

## Step 4: Set Up Firestore Collections

Create these collections in Firestore with sample data:

### Collection: `drivers`
```json
{
  "docId": "DRIVER_UID",
  "name": "John Doe",
  "phone": "+1234567890",
  "email": "john@example.com",
  "licenseNumber": "DL123456789",
  "profileImageUrl": "",
  "status": "active",
  "busId": "BUS001",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### Collection: `attendance`
```json
{
  "attendanceId": "ATT001",
  "driverId": "DRIVER_UID",
  "date": "2024-01-15",
  "checkInTime": "2024-01-15T08:30:00Z",
  "checkOutTime": "2024-01-15T17:30:00Z",
  "status": "present"
}
```

### Collection: `buses`
```json
{
  "busId": "BUS001",
  "busNumber": "ABC-1234",
  "routeName": "Route A - Downtown",
  "driverId": "DRIVER_UID",
  "capacity": 50,
  "currentStatus": "active"
}
```

### Collection: `alerts`
```json
{
  "alertId": "ALR001",
  "driverId": "DRIVER_UID",
  "title": "Safety Check Required",
  "description": "Please perform vehicle safety check",
  "severity": "high",
  "timestamp": "2024-01-15T10:00:00Z",
  "isRead": false
}
```

### Collection: `ratings`
```json
{
  "ratingId": "RAT001",
  "driverId": "DRIVER_UID",
  "passengerId": "PASS001",
  "rating": 5,
  "comment": "Excellent driver!",
  "timestamp": "2024-01-15T18:00:00Z"
}
```

### Collection: `complaints`
```json
{
  "complaintId": "CMP001",
  "driverId": "DRIVER_UID",
  "title": "Vehicle Issue",
  "description": "Air conditioning not working",
  "status": "pending",
  "createdDate": "2024-01-15T09:00:00Z",
  "resolvedDate": null
}
```

## Step 5: Update Firestore Security Rules

Go to **Firestore Database** → **Rules** and replace with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow reads/writes for driver's own data
    match /drivers/{driverId} {
      allow read, write: if request.auth.uid == driverId;
    }
    
    // Allow all reads/writes for authenticated users (development)
    // IMPORTANT: Update these rules for production!
    match /attendance/{doc=**} {
      allow read, write: if request.auth != null;
    }
    match /buses/{doc=**} {
      allow read: if request.auth != null;
    }
    match /alerts/{doc=**} {
      allow read, write: if request.auth != null;
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

⚠️ **Security Warning**: These are development rules. Update them before production!

## Step 6: Test Firebase Connection

1. Rebuild the app:
   ```bash
   cd safe_driver_driver_app
   flutter clean
   flutter pub get
   flutter run
   ```

2. Test phone authentication:
   - Use test phone: `+1 555-0123`
   - Use test code: `123456`
   - You should reach the dashboard

3. Check Firebase Console logs for any errors

## Troubleshooting

### Issue: "Please set a valid API key"
**Solution**: 
- Ensure `google-services.json` is in `android/app/` directory
- Run `flutter clean` and `flutter pub get`
- Rebuild the app

### Issue: "Authentication not enabled"
**Solution**:
- Go to Firebase Console → Authentication
- Enable Phone sign-in method

### Issue: Firestore queries return empty
**Solution**:
- Verify collections are created with correct names (lowercase)
- Check Firestore security rules allow reads
- Verify data has been added to collections

### Issue: App crashes on startup
**Solution**:
- Check logcat for error messages
- Run: `flutter clean && flutter pub get && flutter run`
- Verify Firebase options in `firebase_options.dart`

## Production Checklist

- [ ] Update Firebase security rules (not test mode)
- [ ] Enable App Check in Firebase Console
- [ ] Configure proper authentication methods
- [ ] Set up proper error logging
- [ ] Test on physical Android device
- [ ] Enable Crashlytics for error monitoring
- [ ] Set up backup rules for Firestore

## Security Best Practices

1. **Never commit credentials**: Add `google-services.json` to `.gitignore`
2. **Use security rules**: Always restrict access based on user authentication
3. **Enable App Check**: Prevent unauthorized API calls
4. **Monitor logs**: Regularly check Firebase logs for suspicious activity
5. **Test rules**: Test Firestore security rules thoroughly before production

## Next Steps

1. Complete Firebase setup using this guide
2. Test the app with test credentials
3. Deploy to play testers
4. Monitor Firebase logs and performance
5. Update security rules for production
6. Enable additional Firebase services as needed

## Support Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Console](https://console.firebase.google.com)
- [Flutter Firebase Plugin Docs](https://firebase.flutter.dev/)
- [Android Firebase Setup](https://firebase.google.com/docs/android/setup)

---

**Last Updated**: May 2026
**Version**: 1.0
