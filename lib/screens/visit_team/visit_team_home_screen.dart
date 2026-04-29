import 'package:flutter/material.dart';
import 'visits_screen.dart';
import 'today_visits_screen.dart';
import 'my_visits_screen.dart';
import 'my_support_screen.dart';

class VisitTeamHomeScreen extends StatefulWidget {
  const VisitTeamHomeScreen({super.key});

  @override
  State<VisitTeamHomeScreen> createState() => _VisitTeamHomeScreenState();
}

class _VisitTeamHomeScreenState extends State<VisitTeamHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const VisitsScreen(),
    const TodayVisitsScreen(),
    const MyVisitsScreen(),
    const MySupportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Visits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'My Visits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Support',
          ),
        ],
      ),
    );
  }
}
