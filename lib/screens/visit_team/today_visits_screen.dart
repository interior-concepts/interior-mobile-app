import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

import '../../data/visits/visit.dart';
import '../../data/visits/visit_api_service.dart';
import '../../widgets/mobile_app_header.dart';

class TodayVisitsScreen extends StatefulWidget {
  const TodayVisitsScreen({super.key});

  @override
  State<TodayVisitsScreen> createState() => _TodayVisitsScreenState();
}

class _TodayVisitsScreenState extends State<TodayVisitsScreen> {
  final VisitApiService _visitApiService = VisitApiService();

  bool _loading = true;
  String? _error;
  List<Visit> _todayVisits = const [];

  @override
  void initState() {
    super.initState();
    _loadTodayVisits();
  }

  Future<void> _loadTodayVisits() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getClerkJwt();
      final visits = await _visitApiService.fetchVisits(
        status: 'SCHEDULED',
        authTokenOverride: token,
      );
      final now = DateTime.now();
      final todayOnly = visits
          .where((visit) => visit.isScheduledOn(now))
          .toList();

      if (!mounted) return;
      setState(() {
        _todayVisits = todayOnly;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _todayVisits = const [];
      });
    }
  }

  Future<String?> _getClerkJwt() async {
    try {
      final authState = ClerkAuth.of(context, listen: false);
      final sessionToken = await authState.sessionToken();
      return sessionToken.jwt;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: MobileAppHeader(
        title: 'Today\'s Visits',
        onRefresh: _loadTodayVisits,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTodayVisits,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Text(
                'Failed to load today\'s visits: $_error',
                style: textTheme.bodyMedium?.copyWith(color: Colors.red),
              )
            else if (_todayVisits.isEmpty)
              Text(
                'No visits scheduled for today.',
                style: textTheme.bodyMedium,
              )
            else
              ..._todayVisits.map(_SimpleVisitCard.new),
          ],
        ),
      ),
    );
  }
}

class _SimpleVisitCard extends StatelessWidget {
  const _SimpleVisitCard(this.visit);

  final Visit visit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(visit.clientName),
        subtitle: Text(visit.location),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
