import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:wave/wave.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../widgets/block_building_background.dart';
import '../services/user_session_manager.dart';

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
    return 0x00000000; // Transparent background to show background animation
  }
}

class _ClerkAuthenticationScreenState extends State<ClerkAuthenticationScreen> {
  bool _showClerkBox = false;

  late final ClerkThemeColors _customClerkLightColors = ClerkThemeColors(
    background: const _ClerkDynamicBackground(),
    altBackground: Colors.white.withValues(alpha: 0.35),
    borderSide: const Color(0xFF0284C7).withValues(alpha: 0.25),
    text: const Color(0xFF0F172A),
    icon: const Color(0xFF0F172A),
    lightweightText: const Color(0xFF475569),
    error: const Color(0xFFEF4444),
    accent: const Color(0xFF0284C7),
  );

  @override
  void initState() {
    super.initState();
    // Smooth fade in for Clerk login form
    Timer(const Duration(milliseconds: 400), () {
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
      backgroundColor: const Color(0xFFFAFAFA),
      body: BlockBuildingBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo (Commented out)
                    /*
                    Image.asset(
                      'assets/interior-concept-icon-dark.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 18),
                    */
                    
                    // Prominent Company Brand Name (High-Contrast Charcoal/Navy)
                    const Text(
                      'INTERIOR CONCEPTS STUDIO',
                      style: TextStyle(
                        fontSize: 26, 
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: 2.0,
                        height: 1.25,
                        shadows: [
                          Shadow(
                            color: Color(0x330284C7),
                            blurRadius: 16,
                          ),
                          Shadow(
                            color: Color(0x266366F1),
                            blurRadius: 32,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                      
                      // Render ClerkAuthentication or the Signed-in block directly
                      SizedBox(
                        width: double.infinity,
                        child: widget.isSignedIn
                              ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3), width: 1.0),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 64),
                                    const SizedBox(height: 24),
                                    const Text('You are signed in.', style: TextStyle(fontSize: 16, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                        backgroundColor: const Color(0xFF0284C7),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                      onPressed: widget.onContinue,
                                      child: const Text('Continue to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton(
                                      onPressed: () async {
                                        await UserSessionManager.clearUser();
                                        if (context.mounted) {
                                          ClerkAuth.of(context, listen: false).signOut();
                                        }
                                      },
                                      child: const Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444))),
                                    )
                                  ],
                                ),
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  // The actual Clerk Authentication widget with transparent background
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 600),
                                    opacity: _showClerkBox ? 1.0 : 0.0,
                                    child: IgnorePointer(
                                      ignoring: !_showClerkBox,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.50),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.30), width: 1.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Theme(
                                          data: ThemeData.light().copyWith(
                                            extensions: [
                                              ClerkThemeExtension(colors: _customClerkLightColors),
                                            ],
                                          ),
                                          child: const ClerkAuthentication(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // The loading spinner
                                  if (!_showClerkBox)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SpinKitFoldingCube(
                                            color: Color(0xFF0284C7),
                                            size: 35.0,
                                          ),
                                          const SizedBox(height: 24),
                                          const Text(
                                            'Preparing your dashboard...',
                                            style: TextStyle(
                                              color: Color(0xFF475569),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
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
        ),
      );
  }
}
