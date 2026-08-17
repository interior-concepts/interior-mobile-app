import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_flutter/src/widgets/user/clerk_user_profile.dart';
import '../../widgets/mobile_app_header.dart';
import '../../theme/crm_colors.dart';

class SeniorCrmProfileScreen extends StatelessWidget {
  const SeniorCrmProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: MobileAppHeader(
        title: 'Profile',
        onRefresh: () async {},
      ),
      body: const ClerkUserProfile(),
    );
  }
}
