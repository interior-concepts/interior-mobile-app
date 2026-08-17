import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'screens/clerk_auth_screen.dart';
import 'screens/root_screen.dart';
import 'services/fcm_service.dart';
import 'theme/crm_theme.dart';

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

  static const _clerkPublishableKey =
      'pk_test_a25vd24tcGFuZ29saW4tOTUuY2xlcmsuYWNjb3VudHMuZGV2JA';

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: _clerkPublishableKey,
        loading: const _AuthBootSplash(),
        flags: const ClerkSdkFlags(clearCookiesOnSignOut: true),
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
            // Wrap the entire app with ClerkErrorListener so every auth
            // error shows a friendly alert dialog to guide the user.
            child: ClerkErrorListener(
              handler: _handleClerkError,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: const AppRoot(),
      ),
    );
  }

  /// Converts a [clerk.ClerkError] into a friendly alert dialog with a

  /// clear title and an actionable hint so the user knows exactly what to do.
  static Future<void> _handleClerkError(
    BuildContext context,
    clerk.ClerkError error,
  ) async {
    if (!context.mounted) return;

    final String title;
    final String body;
    final String? hint;

    // Map known ClerkErrorCode values to friendly messages.
    switch (error.code) {
      case clerk.ClerkErrorCode.serverErrorResponse:
        // The server returned a descriptive message — display it directly.
        final serverMsg = error.errors?.errorMessage ?? error.message;
        final lower = serverMsg.toLowerCase();
        if (lower.contains('password') || lower.contains('incorrect')) {
          // Return early to let Clerk display password errors inline inside the form.
          return;
        } else if (lower.contains('identifier') ||
            lower.contains('email') ||
            lower.contains('not found') ||
            lower.contains('no user')) {
          // Return early to let Clerk display email/identifier errors inline inside the form.
          return;
        } else if (lower.contains('already signed in') ||
            lower.contains('session exists')) {
          // Ghost-session: user is already being redirected — skip the dialog.
          return;
        } else if (lower.contains('verification') ||
            lower.contains('code') ||
            lower.contains('otp')) {
          title = 'Verification Failed';
          body = 'The verification code is incorrect or has expired.';
          hint = 'Request a new code and try again.';
        } else if (lower.contains('not allowed') ||
            lower.contains('forbidden') ||
            lower.contains('unauthorized')) {
          title = 'Access Denied';
          body = 'Your account does not have permission to access this app.';
          hint = 'Please contact your administrator to request access.';
        } else {
          title = 'Login Error';
          body = serverMsg;
          hint = 'If this keeps happening, please contact support.';
        }

      case clerk.ClerkErrorCode.tooManyRetries:
        title = 'Too Many Attempts';
        body = 'You have tried too many times. Please wait a few minutes.';
        hint = 'For security, Clerk temporarily blocks repeated attempts.';

      case clerk.ClerkErrorCode.noSessionTokenRetrieved:
        title = 'Session Expired';
        body = 'Your session has expired. Please sign in again.';
        hint = null;

      case clerk.ClerkErrorCode.passwordMatchError:
        title = 'Passwords Do Not Match';
        body = 'The password and confirmation you entered are different.';
        hint = 'Please retype your new password in both fields.';

      case clerk.ClerkErrorCode.clientAppError:
        final lower = error.message.toLowerCase();
        if (lower.contains('network') ||
            lower.contains('connection') ||
            lower.contains('socket') ||
            lower.contains('timeout')) {
          title = 'Connection Error';
          body = 'Unable to reach the server.';
          hint =
              'Make sure you have an active internet connection, then try again.';
        } else {
          title = 'App Error';
          body = error.message;
          hint = 'Please try again. If the problem continues, contact support.';
        }

      default:
        title = 'Something Went Wrong';
        body = error.message.isNotEmpty
            ? error.message
            : 'An unexpected error occurred.';
        hint = 'Please try again or contact support if the problem persists.';
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body, style: const TextStyle(fontSize: 14, height: 1.5)),
            if (hint != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.blue, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        hint,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
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

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _didContinue = false;

  @override
  Widget build(BuildContext context) {
    return ClerkAuthBuilder(
      signedInBuilder: (context, authState) {
        if (_didContinue) {
          return const RootScreen();
        } else {
          return ClerkAuthenticationScreen(
            isSignedIn: true,
            onContinue: () {
              setState(() {
                _didContinue = true;
              });
            },
          );
        }
      },
      signedOutBuilder: (context, authState) {
        // Reset state so next time they login they see the button again
        if (_didContinue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _didContinue = false);
          });
        }
        return const ClerkAuthenticationScreen(isSignedIn: false);
      },
    );
  }
}
