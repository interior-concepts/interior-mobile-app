import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

import '../../data/visits/visit.dart';
import '../../data/visits/visit_api_service.dart';
import '../../widgets/mobile_app_header.dart';

class MyVisitsScreen extends StatefulWidget {
  const MyVisitsScreen({super.key});

  @override
  State<MyVisitsScreen> createState() => _MyVisitsScreenState();
}

class _MyVisitsScreenState extends State<MyVisitsScreen> {
  final VisitApiService _visitApiService = VisitApiService();

  bool _loading = true;
  String? _error;
  List<Visit> _myVisits = const [];

  @override
  void initState() {
    super.initState();
    _loadMyVisits();
  }

  Future<void> _loadMyVisits() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getClerkJwt();
      final visits = await _visitApiService.fetchVisits(
        mode: 'lead',
        authTokenOverride: token,
      );
      if (!mounted) return;
      setState(() {
        _myVisits = visits;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _myVisits = const [];
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
      appBar: MobileAppHeader(title: 'My Visits', onRefresh: _loadMyVisits),
      body: RefreshIndicator(
        onRefresh: _loadMyVisits,
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
                'Failed to load your visits: $_error',
                style: textTheme.bodyMedium?.copyWith(color: Colors.red),
              )
            else if (_myVisits.isEmpty)
              Text(
                'No visits assigned to you yet.',
                style: textTheme.bodyMedium,
              )
            else
              ..._myVisits.map(_SimpleVisitCard.new),
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
