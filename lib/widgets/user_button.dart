import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../screens/user_profile_view_screen.dart';

/// Flutter equivalent of Clerk Android `UserButton()`.
/// Renders avatar-only and opens profile view on tap.
class UserButton extends StatelessWidget {
  const UserButton({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClerkAuthBuilder(
      builder: (context, authState) {
        if (authState.user == null) {
          return const SizedBox.shrink();
        }
        final user = authState.user!;
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const UserProfileViewScreen(),
              ),
            );
          },
          child: Container(
            width: size,
            height: size,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: user.imageUrl?.isNotEmpty == true
                ? Image.network(
                    user.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _avatarFallback(),
                  )
                : _avatarFallback(),
          ),
        );
      },
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: const Color(0xFFEAEAEA),
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 18, color: Color(0xFF7A7A7A)),
    );
  }
}
