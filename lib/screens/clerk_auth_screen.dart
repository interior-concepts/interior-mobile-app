import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:wave/wave.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ClerkAuthenticationScreen extends StatefulWidget {
  const ClerkAuthenticationScreen({
    super.key,
    this.isSignedIn = false,
    this.onContinue,
  });

  final bool isSignedIn;
  final VoidCallback? onContinue;

  @override
  State<ClerkAuthenticationScreen> createState() => _ClerkAuthenticationScreenState();
}

class _ClerkAuthenticationScreenState extends State<ClerkAuthenticationScreen> {
  bool _showClerkBox = false;

  @override
  void initState() {
    super.initState();
    // Allow 3.5 seconds for Clerk to silently restore any active cookie session in the background
    // before we fade in the login form to the user.
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _showClerkBox = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/mobileBanner3.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          
          // Foreground Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Image.asset('assets/icon.png', width: 64, height: 64),
                      ),
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aesthetic Interior Management System',
                        style: TextStyle(
                          fontSize: 16, 
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      
                      // Glass Card containing the Auth/Signed In state
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: SizedBox(
                              height: 380, // Height matching the Clerk vertical login card
                              child: widget.isSignedIn
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 64),
                                          const SizedBox(height: 24),
                                          const Text('You are signed in.', style: TextStyle(fontSize: 16, color: Colors.white70)),
                                          const SizedBox(height: 24),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black87,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                            ),
                                            onPressed: widget.onContinue,
                                            child: const Text('Continue to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(height: 16),
                                          TextButton(
                                            onPressed: () {
                                              ClerkAuth.of(context, listen: false).signOut();
                                            },
                                            child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                                          )
                                        ],
                                      ),
                                    )
                                  : Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // The actual Clerk Authentication widget, loading invisibly first
                                        AnimatedOpacity(
                                          duration: const Duration(milliseconds: 600),
                                          opacity: _showClerkBox ? 1.0 : 0.0,
                                          child: IgnorePointer(
                                            ignoring: !_showClerkBox,
                                            child: const ClerkAuthentication(),
                                          ),
                                        ),
                                        
                                        // The loading spinner, visible while checking for auto-login
                                        if (!_showClerkBox)
                                          Column(
                                            key: const ValueKey('loading_state'),
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SpinKitFoldingCube(
                                                color: Colors.white,
                                                size: 35.0,
                                              ),
                                              const SizedBox(height: 24),
                                              Text(
                                                'Preparing your dashboard...',
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.8),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
