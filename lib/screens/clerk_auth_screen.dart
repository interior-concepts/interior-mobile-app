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

class _ClerkDynamicBackground extends Color {
  const _ClerkDynamicBackground() : super(0x00000000);

  @override
  int get value {
    final stack = StackTrace.current.toString();
    if (stack.contains('RenderParagraph') || 
        stack.contains('TextPainter') ||
        stack.contains('Paragraph') ||
        stack.contains('RichText')) {
      return 0xFFFFFFFF; // White for button text/icon
    }
    return 0x00000000; // Transparent background to show background image
  }
}

class _ClerkAuthenticationScreenState extends State<ClerkAuthenticationScreen> {
  bool _showClerkBox = false;

  late final ClerkThemeColors _customClerkDarkColors = ClerkThemeColors(
    background: const _ClerkDynamicBackground(),
    altBackground: Colors.white.withOpacity(0.08),
    borderSide: Colors.white.withOpacity(0.15),
    text: Colors.white,
    icon: Colors.white,
    lightweightText: Colors.white.withOpacity(0.6),
    error: const Color(0xFFff3333),
    accent: const Color(0xFF6c47ff),
  );

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
          // Very light dark overlay so background image is clearly visible
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.15),
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
                      // App Logo (clean and without round circle/border)
                      Image.asset(
                        'assets/ais-icon-dark.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
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
                      
                      // Render ClerkAuthentication or the Signed-in block directly
                      SizedBox(
                        width: double.infinity,
                        child: widget.isSignedIn
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
                                ),
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
                                      child: Theme(
                                        data: ThemeData.dark().copyWith(
                                          extensions: [
                                            ClerkThemeExtension(colors: _customClerkDarkColors),
                                          ],
                                        ),
                                        child: const ClerkAuthentication(),
                                      ),
                                    ),
                                  ),
                                  
                                  // The loading spinner, visible while checking for auto-login
                                  if (!_showClerkBox)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                                      child: Column(
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
                                    ),
                                ],
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
