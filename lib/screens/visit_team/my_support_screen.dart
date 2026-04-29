import 'package:flutter/material.dart';
import '../../widgets/mobile_app_header.dart';

class MySupportScreen extends StatelessWidget {
  const MySupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MobileAppHeader(title: 'My Support'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for support content
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('Support - Item 1')),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('Support - Item 2')),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('Support - Item 3')),
            ),
          ],
        ),
      ),
    );
  }
}
