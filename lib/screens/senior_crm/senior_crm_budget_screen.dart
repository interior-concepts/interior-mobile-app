import 'package:flutter/material.dart';
import '../../widgets/mobile_app_header.dart';
import '../../theme/crm_colors.dart';

class SeniorCrmBudgetScreen extends StatelessWidget {
  const SeniorCrmBudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: MobileAppHeader(
        title: 'Budget',
        onRefresh: () async {},
      ),
      body: const Center(
        child: Text(
          'Budget Screen',
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
