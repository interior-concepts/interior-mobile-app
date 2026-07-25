import 'package:flutter/material.dart';
import '../../widgets/mobile_app_header.dart';
import '../../theme/crm_colors.dart';

class SeniorCrmQueueScreen extends StatelessWidget {
  const SeniorCrmQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: MobileAppHeader(
        title: 'Queue',
        onRefresh: () async {},
      ),
      body: const Center(
        child: Text(
          'Queue Screen',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CrmColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
