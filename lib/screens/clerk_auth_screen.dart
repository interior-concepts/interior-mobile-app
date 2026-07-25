import 'dart:async';
import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:wave/wave.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ClerkAuthenticationScreen extends StatefulWidget {
  const ClerkAuthenticationScreen({super.key});

  @override
  State<ClerkAuthenticationScreen> createState() => _ClerkAuthenticationScreenState();
}

class _ClerkAuthenticationScreenState extends State<ClerkAuthenticationScreen> {
  bool _showClerkBox = false;

  @override
  void initState() {
    super.initState();
    // Simulate loading for a few seconds before showing Clerk auth
    Timer(const Duration(milliseconds: 2500), () {
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Waves at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: WaveWidget(
              config: CustomConfig(
                colors: [
                  Colors.blue.withOpacity(0.3),
                  Colors.blue.withOpacity(0.6),
                ],
                durations: [35000, 19440],
                heightPercentages: [0.20, 0.25],
                blur: const MaskFilter.blur(BlurStyle.solid, 10),
              ),
              waveAmplitude: 20,
              size: const Size(double.infinity, 250),
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
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Aesthetic Interior Management System',
                        style: TextStyle(
                          fontSize: 16, 
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      
                      // Loading or Clerk Box
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 800),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _showClerkBox
                            ? const ClerkAuthentication()
                            : const Column(
                                key: ValueKey('loading_state'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SpinKitFoldingCube(
                                    color: Colors.blue,
                                    size: 35.0,
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    'Preparing your dashboard...',
                                    style: TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 100), // padding for wave
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
