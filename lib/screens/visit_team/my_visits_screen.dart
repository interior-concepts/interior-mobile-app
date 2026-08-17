import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../data/visits/visit.dart';
import '../../data/visits/visit_api_service.dart';
import '../../widgets/mobile_app_header.dart';

enum _VisitFilter { today, pending, completed, all }

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
  _VisitFilter _activeFilter = _VisitFilter.all;

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
    final now = DateTime.now();
    List<Visit> filteredVisits;
    switch (_activeFilter) {
      case _VisitFilter.today:
        filteredVisits = _myVisits.where((v) => v.isScheduledOn(now)).toList();
        break;
      case _VisitFilter.pending:
        filteredVisits = _myVisits.where((v) => v.status == VisitStatus.scheduled).toList();
        break;
      case _VisitFilter.completed:
        filteredVisits = _myVisits.where((v) => v.status == VisitStatus.completed).toList();
        break;
      case _VisitFilter.all:
        filteredVisits = _myVisits;
    }
    return Scaffold(
      appBar: MobileAppHeader(title: 'My Visits', onRefresh: _loadMyVisits),
      body: RefreshIndicator(
        onRefresh: _loadMyVisits,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Today'),
                  selected: _activeFilter == _VisitFilter.today,
                  onSelected: (s) => setState(() {
                    _activeFilter = s ? _VisitFilter.today : _VisitFilter.all;
                  }),
                ),
                ChoiceChip(
                  label: const Text('Pending'),
                  selected: _activeFilter == _VisitFilter.pending,
                  onSelected: (s) => setState(() {
                    _activeFilter = s ? _VisitFilter.pending : _VisitFilter.all;
                  }),
                ),
                ChoiceChip(
                  label: const Text('Completed'),
                  selected: _activeFilter == _VisitFilter.completed,
                  onSelected: (s) => setState(() {
                    _activeFilter = s ? _VisitFilter.completed : _VisitFilter.all;
                  }),
                ),
              ],
            ),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: SpinKitFoldingCube(
                    color: Colors.blue,
                    size: 30.0,
                  ),
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
            else if (filteredVisits.isEmpty)
              Text(
                'No visits match this filter.',
                style: textTheme.bodyMedium,
              )
            else
              ...filteredVisits.map((v) => _SimpleVisitCard(
                    v,
                    onAction: (action) async {
                      await _handleVisitAction(action, v);
                    },
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVisitAction(String action, Visit visit) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await _getClerkJwt();
      if (action == 'complete') {
        await _visitApiService.updateVisitStatus(visit.id, 'COMPLETED', authTokenOverride: token);
        if (!mounted) return;
        messenger.showSnackBar(const SnackBar(content: Text('Marked complete')));
      } else if (action == 'cancel') {
        final reason = await _askReason(
          title: 'Cancel Visit Request',
          hint: 'Why should this visit be cancelled?',
        );
        if (reason == null) return;
        await _visitApiService.createVisitUpdateRequest(
          visit.id,
          type: 'CANCEL',
          reason: reason,
          authTokenOverride: token,
        );
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Cancel request sent to JR CRM')),
        );
      } else if (action == 'reschedule') {
        if (!mounted) return;
        final picked = await showDatePicker(
          context: context,
          initialDate: visit.scheduledAt?.toLocal() ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (picked == null) return;
        final reason = await _askReason(
          title: 'Reschedule Request',
          hint: 'Why should this visit be rescheduled?',
        );
        if (reason == null) return;
        await _visitApiService.createVisitUpdateRequest(
          visit.id,
          type: 'RESCHEDULE',
          reason: reason,
          requestedScheduleAt: picked.toUtc(),
          authTokenOverride: token,
        );
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Reschedule request sent to JR CRM')),
        );
      }
      await _loadMyVisits();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }
  }

  Future<String?> _askReason({
    required String title,
    required String hint,
  }) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.of(ctx).pop(value);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    controller.dispose();
    return reason;
  }
}

class _SimpleVisitCard extends StatelessWidget {
  const _SimpleVisitCard(this.visit, {this.onAction});

  final Visit visit;
  final Future<void> Function(String action)? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(visit.clientName),
        subtitle: Text(visit.status.name.toUpperCase()),
        childrenPadding: const EdgeInsets.all(16.0),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => Navigator.of(context).pushNamed('/visit', arguments: visit.id),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                onAction?.call(value);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'complete', child: Text('Complete')),
                const PopupMenuItem(value: 'reschedule', child: Text('Reschedule')),
                const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
              ],
            ),
          ],
        ),
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(visit.location)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text('Assigned: ${visit.assignedTo?.fullName ?? 'Unassigned'}')),
            ],
          ),
        ],
      ),
    );
  }
}
