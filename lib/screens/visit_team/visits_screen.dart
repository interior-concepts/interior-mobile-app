import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

import '../../data/visits/visit.dart';
import '../../data/visits/visit_api_service.dart';
import '../../widgets/mobile_app_header.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final VisitApiService _visitApiService = VisitApiService();

  List<Visit> _visits = const [];
  bool _loading = true;
  String? _errorMessage;
  FileLoader? _fileLoader;
  bool _riveChecked = false;

  @override
  void initState() {
    super.initState();
    _initRiveLoader();
    _loadVisits();
  }

  Future<void> _initRiveLoader() async {
    final exists = await _checkRiveAssetExists();
    if (!mounted) return;

    if (!exists) {
      setState(() {
        _riveChecked = true;
      });
      return;
    }

    final loader = FileLoader.fromAsset(
      'assets/animations/visits.riv',
      riveFactory: Factory.flutter,
    );

    setState(() {
      _fileLoader = loader;
      _riveChecked = true;
    });
  }

  Future<void> _loadVisits() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getClerkJwt();
      final items = await _visitApiService.fetchVisits(
        authTokenOverride: token,
      );
      if (!mounted) return;
      setState(() {
        _visits = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
        _visits = const [];
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

  Future<bool> _checkRiveAssetExists() async {
    try {
      final data = await rootBundle.load('assets/animations/visits.riv');
      return data.lengthInBytes > 0;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _fileLoader?.dispose();
    super.dispose();
  }

  int _countToday() {
    final now = DateTime.now();
    return _visits.where((visit) => visit.isScheduledOn(now)).length;
  }

  int _countByStatus(VisitStatus status) {
    return _visits.where((visit) => visit.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: MobileAppHeader(title: 'Visits', onRefresh: _loadVisits),
      body: RefreshIndicator(
        onRefresh: _loadVisits,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.14),
                      colorScheme.primary.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'VISIT SCHEDULE',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_visits.length} total visits',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Live data from website API: /api/visit-schedule',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.68,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child: _buildRiveArea()),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricChip(
                      label: 'Today',
                      value: _countToday().toString(),
                      icon: Icons.today_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricChip(
                      label: 'Pending',
                      value: _countByStatus(VisitStatus.scheduled).toString(),
                      icon: Icons.pending_actions_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricChip(
                      label: 'Completed',
                      value: _countByStatus(VisitStatus.completed).toString(),
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Upcoming Visits', style: textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: _loadVisits,
                    icon: const Icon(Icons.sync_outlined, size: 18),
                    label: const Text('Sync'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Error loading visits: $_errorMessage',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.red),
                  ),
                )
              else if (_visits.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'No upcoming visits.',
                    style: textTheme.bodyMedium,
                  ),
                )
              else
                for (var i = 0; i < _visits.length; i++) ...[
                  _VisitCard(visit: _visits[i]),
                  if (i != _visits.length - 1) const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiveArea() {
    if (!_riveChecked) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_fileLoader == null) {
      return const _MissingRiveAssetMessage();
    }

    return RiveWidgetBuilder(
      fileLoader: _fileLoader!,
      builder: (context, state) {
        if (state is RiveLoaded) {
          return RiveWidget(controller: state.controller, fit: Fit.contain);
        }
        if (state is RiveFailed) {
          return const _MissingRiveAssetMessage();
        }
        return const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}

class _MissingRiveAssetMessage extends StatelessWidget {
  const _MissingRiveAssetMessage();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.animation_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'Add a Rive animation at assets/animations/visits.riv',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final statusLabel = _statusLabel(visit.status);
    final isCompleted = visit.status == VisitStatus.completed;
    final dateTimeLabel = _formatDateTime(visit.scheduledAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _locationIcon(visit.location),
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visit',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(visit.clientName, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isCompleted ? Colors.green : Colors.orange)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: isCompleted
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 17),
                const SizedBox(width: 6),
                Text(dateTimeLabel, style: textTheme.bodyMedium),
                const SizedBox(width: 16),
                const Icon(Icons.place_outlined, size: 17),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    visit.location,
                    style: textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(VisitStatus status) {
    switch (status) {
      case VisitStatus.scheduled:
        return 'Pending';
      case VisitStatus.completed:
        return 'Completed';
      case VisitStatus.rescheduled:
        return 'Rescheduled';
      case VisitStatus.cancelled:
        return 'Cancelled';
      case VisitStatus.unknown:
        return 'Unknown';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Date unavailable';

    final local = dateTime.toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[local.month - 1];
    final day = local.day;
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';

    return '$month $day • $hour:$minute $amPm';
  }

  IconData _locationIcon(String location) {
    final normalized = location.toLowerCase();
    if (normalized.contains('remote') || normalized.contains('online')) {
      return Icons.phone_in_talk_outlined;
    }
    return Icons.location_on_outlined;
  }
}
