import 'package:flutter/material.dart';
import '../../widgets/mobile_app_header.dart';
import '../../theme/crm_colors.dart';

class SeniorCrmMeetingScreen extends StatelessWidget {
  const SeniorCrmMeetingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: MobileAppHeader(
        title: 'Meeting',
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
      ),
      body: const Center(
        child: Text(
          'Meeting Module\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CrmColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
