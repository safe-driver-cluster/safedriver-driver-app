import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('si'), Locale('ta')];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _values = {
    'en': {
      'appName': 'SafeDriver Driver',
      'tagline': 'Focused tools for safer bus operations',
      'version': 'Version',
      'skip': 'Skip',
      'next': 'Next',
      'getStarted': 'Get Started',
      'selectLanguage': 'Choose Language',
      'continueText': 'Continue',
      'loginTitle': 'Driver login',
      'loginSubtitle': 'Use the phone number registered by admin.',
      'phoneNumber': 'Registered phone number',
      'sendOtp': 'Send OTP',
      'otpTitle': 'Enter verification code',
      'otpSubtitle': 'We sent an OTP to your phone number.',
      'otpCode': 'OTP code',
      'verifyLogin': 'Verify and login',
      'resendOtp': 'Resend OTP',
      'resendIn': 'Resend in',
      'dashboard': 'Dashboard',
      'myAttendance': 'My attendance',
      'myBuses': 'My buses',
      'myAlerts': 'My alerts',
      'ratings': 'Ratings',
      'complaints': 'Complaints',
      'profile': 'My profile',
      'map': 'Map',
      'support': 'Help & support',
      'settings': 'Settings',
      'logout': 'Logout',
      'darkMode': 'Dark mode',
      'language': 'Language',
      'refresh': 'Refresh',
      'active': 'Active',
      'inactive': 'Inactive',
      'noData': 'No data available',
      'noAssignedBuses': 'No assigned buses found',
      'noAlerts': 'No alerts found',
      'noRatings': 'No passenger ratings found',
      'noAttendance': 'No attendance records found',
      'submitComplaint': 'Submit complaint',
      'complaintTitle': 'Complaint title',
      'complaintMessage': 'Message',
      'submit': 'Submit',
      'profilePhotoOnly': 'Only profile photo can be updated from this app.',
      'updatePhoto': 'Update photo',
      'license': 'License',
      'employeeId': 'Employee ID',
      'currentBus': 'Current bus',
      'safetyScore': 'Safety score',
      'passengerRating': 'Passenger rating',
      'today': 'Today',
      'totalRatings': 'Total ratings',
      'contactAdmin': 'Contact admin',
      'faqs': 'FAQs',
      'emergencyHelp': 'Emergency help',
      'routeGuidance': 'Route guidance',
      'attendanceHint': 'Attendance is shown from driver attendance records.',
      'phoneRequired': 'Enter your registered phone number',
      'otpRequired': 'Enter the OTP code',
      'driverNotFound': 'No active driver found for this phone number.',
      'otpFailed': 'Could not send OTP. Please try again.',
      'loginFailed': 'Login failed. Please check the code and try again.',
      'complaintSent': 'Complaint sent to admin.',
      'fieldRequired': 'This field is required',
    },
    'si': {},
    'ta': {},
  };

  String t(String key) {
    return _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
