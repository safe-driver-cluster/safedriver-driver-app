import 'package:flutter/foundation.dart';

Future<bool> ensureGoogleMapsWebApiReady() async {
  if (!kIsWeb) return true;

  // Web support will be wired in the next phase with Maps JavaScript loading.
  return true;
}
