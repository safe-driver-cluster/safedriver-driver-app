class GoogleMapsConfig {
  static const String apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyBc2q2xuY7I0gpZVHW5qm-dtahYBj6xghY',
  );

  static bool get isConfigured => apiKey.isNotEmpty;
}
