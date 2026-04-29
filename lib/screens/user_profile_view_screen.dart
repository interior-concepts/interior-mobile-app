// ignore_for_file: implementation_imports

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/widgets/user/clerk_user_profile.dart';
import 'package:flutter/material.dart';

class UserProfileViewScreen extends StatelessWidget {
  const UserProfileViewScreen({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    final authState = ClerkAuth.of(context, listen: false);
    await authState.signOut();
    if (context.mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () => _handleSignOut(context),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: const ClerkUserProfile(),
    );
  }
}
