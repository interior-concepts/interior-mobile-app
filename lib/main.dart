import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

import 'screens/visit_team/visit_team_home_screen.dart';
import 'screens/clerk_auth_screen.dart';
import 'theme/crm_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      config: ClerkAuthConfig(publishableKey: _clerkPublishableKey),
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
        home: ClerkErrorListener(
          child: ClerkAuthBuilder(
            signedInBuilder: (context, authState) =>
                const VisitTeamHomeScreen(),
            signedOutBuilder: (context, authState) =>
                const ClerkAuthenticationScreen(),
          ),
        ),
      ),
    );
  }
}
