import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleMapsConfig {
  static String get apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static bool get isConfigured => apiKey.isNotEmpty;
}
