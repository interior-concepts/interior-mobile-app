import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

class ClerkAuthenticationScreen extends StatelessWidget {
  const ClerkAuthenticationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Sign In',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                // Clerk provides a drop-in authentication widget.
                ClerkAuthentication(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
