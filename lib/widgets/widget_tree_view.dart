import 'package:flutter/material.dart';

class WidgetTreeView extends StatelessWidget {
  const WidgetTreeView({super.key});

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      'CrmMobileApp (StatelessWidget)',
      '  └─ ClerkAuth',
      '      └─ MaterialApp',
      '          ├─ AnnotatedRegion<SystemUiOverlayStyle>',
      '          └─ home: ClerkAuthBuilder',
      '              ├─ SignedIn -> RootScreen',
      '              └─ SignedOut -> ClerkAuthenticationScreen',
      '',
      'RootScreen (StatefulWidget)',
      '  ├─ Loading: Scaffold > Center > SpinKitFoldingCube',
      '  ├─ SeniorCrmHomeScreen',
      '  │   ├─ Scaffold',
      '  │   ├─ body: AnimatedSwitcher -> Dashboard / Queue / Budget / Profile',
      '  │   └─ bottomNavigationBar: NavigationBar',
      '  ├─ VisitTeamHomeScreen',
      '  │   ├─ Scaffold',
      '  │   ├─ body: AnimatedSwitcher -> Dashboard / Visits / TodayVisits / Profile/Control',
      '  │   └─ bottomNavigationBar: NavigationBar',
      '  └─ Access Denied: Scaffold > Column > [Icon, Text, Button]',
      '',
      'ClerkAuthenticationScreen (StatefulWidget)',
      '  ├─ Scaffold > Stack',
      '  ├─ WaveWidget (background)',
      '  └─ SafeArea > Center > Column (Welcome, ClerkAuthentication or Loader)',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Widget Tree')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          lines.join('\n'),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        ),
      ),
    );
  }
}
