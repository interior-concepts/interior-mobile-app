import 'package:flutter/material.dart';
import '../../widgets/mobile_app_header.dart';
import '../../theme/crm_colors.dart';



class SeniorCrmDashboardScreen extends StatefulWidget {
  const SeniorCrmDashboardScreen({super.key});

  @override
  State<SeniorCrmDashboardScreen> createState() => _SeniorCrmDashboardScreenState();
}

class _SeniorCrmDashboardScreenState extends State<SeniorCrmDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: MobileAppHeader(
        title: 'Home',
        onRefresh: () async {},
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Home Screen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CrmColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
