import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../data/user/user_api_service.dart';
import '../services/user_session_manager.dart';
import '../theme/crm_colors.dart';
import 'visit_team/visit_team_home_screen.dart';
import 'senior_crm/senior_crm_home_screen.dart';
import '../services/notification_manager.dart';
import '../services/fcm_service.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _isLoading = true;
  bool _isSeniorCrm = false;
  bool _isVisitTeam = false;
  bool _isNetworkError = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  @override
  void dispose() {
    NotificationManager.instance.stopPolling();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    // 1. Immediately restore cached role if available, so user lands in app instantly
    final cachedUser = await UserSessionManager.getCachedUser();
    if (cachedUser != null && mounted) {
      setState(() {
        _isSeniorCrm = cachedUser.isSeniorCrm;
        _isVisitTeam = cachedUser.isVisitTeam;
        _isLoading = false;
        _isNetworkError = false;
      });
    }

    try {
      final authState = ClerkAuth.of(context, listen: false);

      // Keep Clerk client persistent so mobile never logs out on background exit
      UserSessionManager.persistClerkClient(authState);

      final sessionToken = await authState.sessionToken();
      final token = sessionToken.jwt;
      if (token.isEmpty) {
        if (cachedUser == null && mounted) {
          setState(() {
            _isLoading = false;
            _isNetworkError = true;
          });
        }
        return;
      }

      // Always register FCM device token for authenticated user immediately
      FcmService.registerToken(token);

      final user = await UserApiService().fetchMe(token);
      if (!mounted) return;

      if (user != null) {
        // Cache user for persistent offline & background resumes
        await UserSessionManager.saveUser(user);

        setState(() {
          _isSeniorCrm = user.isSeniorCrm;
          _isVisitTeam = user.isVisitTeam;
          _isLoading = false;
          _isNetworkError = false;
        });

        if (user.isSeniorCrm || user.isVisitTeam) {
          // Start polling for in-app badge updates.
          // Pass a tokenRefresher so every API call uses a fresh JWT (Clerk JWTs expire ~60s).
          NotificationManager.instance.startPolling(
            token,
            tokenRefresher: () async {
              try {
                final freshSession = await authState.sessionToken();
                return freshSession.jwt.isNotEmpty ? freshSession.jwt : null;
              } catch (_) {
                return null;
              }
            },
          );
        }
      } else {
        // fetchMe returned null (e.g. network timeout or server glitch)
        if (cachedUser == null && mounted) {
          setState(() {
            _isLoading = false;
            _isNetworkError = true;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ [RootScreen] Error checking user role: $e');
      if (cachedUser == null && mounted) {
        setState(() {
          _isLoading = false;
          _isNetworkError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: SpinKitFoldingCube(color: CrmColors.brandPrimary, size: 40.0),
        ),
      );
    }

    if (_isSeniorCrm) {
      return const SeniorCrmHomeScreen();
    }

    if (_isVisitTeam) {
      return const VisitTeamHomeScreen();
    }

    if (_isNetworkError) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 64, color: CrmColors.brandPrimary),
                const SizedBox(height: 20),
                const Text(
                  'Connection Problem',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Unable to reach the server. Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CrmColors.mutedForeground, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CrmColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _isNetworkError = false;
                    });
                    _checkUserRole();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If they have neither department, block entry.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: Colors.white,
        foregroundColor: CrmColors.foreground,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 64, color: CrmColors.error),
            const SizedBox(height: 16),
            const Text(
              'Not Authorized',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You must be in the SR_CRM or VISIT_TEAM\ndepartment to access this app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CrmColors.mutedForeground),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await UserSessionManager.clearUser();
                if (context.mounted) {
                  ClerkAuth.of(context, listen: false).signOut();
                }
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
