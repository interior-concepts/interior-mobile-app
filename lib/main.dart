import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/root_screen.dart';
import 'screens/clerk_auth_screen.dart';
import 'theme/crm_theme.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for FCM).
  await Firebase.initializeApp();

  // Initialize FCM and register background handler.
  await FcmService.initialize();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const CrmMobileApp());
}

class CrmMobileApp extends StatelessWidget {
  const CrmMobileApp({super.key});

  // TODO: Replace with your Clerk publishable key or inject via environment.
  static const _clerkPublishableKey =
      'pk_test_a25vd24tcGFuZ29saW4tOTUuY2xlcmsuYWNjb3VudHMuZGV2JA';

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: _clerkPublishableKey,
        loading: const _AuthBootSplash(),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Aesthetic OMS',
        theme: CrmTheme.light(),
        builder: (context, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: ClerkAuthBuilder(
          signedInBuilder: (context, authState) => const RootScreen(),
          signedOutBuilder: (context, authState) => const ClerkAuthenticationScreen(),
        ),
      ),
    );
  }
}

class _AuthBootSplash extends StatelessWidget {
  const _AuthBootSplash();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: SpinKitFoldingCube(
              color: Colors.blue,
              size: 50.0,
            ),
          ),
        ),
      ),
    );
  }
}

