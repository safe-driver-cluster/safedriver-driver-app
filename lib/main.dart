import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'app/routes.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    debugPrint('Unable to load .env file: $error');
  }
  await _configureGoogleMaps();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final controller = AppController();
  await controller.load();

  runApp(AppScope(controller: controller, child: const DriverApp()));
}

Future<void> _configureGoogleMaps() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  final mapsImplementation = GoogleMapsFlutterAndroid()
    ..useAndroidViewSurface = true;
  GoogleMapsFlutterPlatform.instance = mapsImplementation;
  try {
    await mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
    await mapsImplementation.warmup();
  } catch (_) {
    // Renderer can only be initialized once; the default renderer still works.
  }
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'SafeDriver - Driver App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: controller.themeMode,
          locale: controller.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
