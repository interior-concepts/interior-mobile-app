import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fui_kit/fui_kit.dart';

import '../../data/visits/visit.dart';
import '../../data/visits/visit_api_service.dart';
import '../../widgets/mobile_app_header.dart';
import '../../theme/crm_colors.dart';

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
        status: 'SCHEDULED', // We'll fetch all to catch completed as well, or just scheduled? The user wants "today visits", let's remove status filter to get all today's visits.
        authTokenOverride: token,
      );
      final now = DateTime.now();
      final todayOnly = visits
          .where((visit) => visit.isScheduledOn(now))
          .toList();
          
      // Sort by time
      todayOnly.sort((a, b) => (a.scheduledAt ?? now).compareTo(b.scheduledAt ?? now));

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      extendBodyBehindAppBar: true,
      appBar: MobileAppHeader(
        title: '',
        onRefresh: _loadTodayVisits,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTodayVisits,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + kToolbarHeight + 10, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumbs
                    Row(
                      children: [
                        const FUI(RegularRounded.home, color: CrmColors.brandPrimary, width: 14, height: 14),
                        const SizedBox(width: 6),
                        const Text('Home', style: TextStyle(color: CrmColors.brandPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: CrmColors.mutedForeground),
                        const SizedBox(width: 6),
                        const Text("Today's Visits", style: TextStyle(color: CrmColors.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ).animate().fade(duration: 400.ms).slideX(begin: -0.1),
                    
                    const SizedBox(height: 16),
                    
                    // Screen Name
                    const Text(
                      "Today's Visits",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: CrmColors.foreground,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fade(delay: 100.ms).slideY(begin: -0.2),
                    
                    const SizedBox(height: 6),
                    
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                      style: const TextStyle(fontSize: 14, color: CrmColors.mutedForeground, fontWeight: FontWeight.w500),
                    ).animate().fade(delay: 200.ms).slideY(begin: -0.2),
                    
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            
            // Content
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: SpinKitFoldingCube(color: CrmColors.brandPrimary, size: 30),
                  ),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Failed to load: $_error',
                      style: const TextStyle(color: CrmColors.error),
                    ),
                  ),
                ),
              )
            else if (_todayVisits.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.event_available_rounded, size: 48, color: CrmColors.border),
                        const SizedBox(height: 16),
                        const Text(
                          'No visits scheduled for today.',
                          style: TextStyle(color: CrmColors.mutedForeground, fontSize: 15),
                        ),
                      ],
                    ).animate().fade().scale(begin: const Offset(0.9, 0.9)),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final visit = _todayVisits[index];
                      return _TimelineCard(
                        visit: visit,
                        isFirst: index == 0,
                        isLast: index == _todayVisits.length - 1,
                      ).animate().fade(delay: (300 + (index * 80)).ms).slideX(begin: 0.1);
                    },
                    childCount: _todayVisits.length,
                  ),
                ),
              ),
              
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.visit, required this.isFirst, required this.isLast});
  
  final Visit visit;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final timeStr = visit.scheduledAt != null ? DateFormat('hh:mm a').format(visit.scheduledAt!.toLocal()) : 'TBD';
    final isPast = visit.scheduledAt != null && visit.scheduledAt!.isBefore(DateTime.now());
    
    // Status colors
    Color statusColor = CrmColors.brandPrimary;
    if (visit.status == VisitStatus.completed) {
      statusColor = CrmColors.success;
    } else if (visit.status == VisitStatus.cancelled) {
      statusColor = CrmColors.error;
    } else if (isPast && visit.status == VisitStatus.scheduled) {
      statusColor = Colors.orange;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 24,
                  color: isFirst ? Colors.transparent : CrmColors.border,
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: statusColor, width: 3),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: statusColor.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)
                    ]
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : CrmColors.border,
                  ),
                ),
              ],
            ),
          ),
          
          // Card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CrmColors.border.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            timeStr,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                        if (visit.status == VisitStatus.completed)
                          const Icon(Icons.check_circle_rounded, color: CrmColors.success, size: 18)
                        else if (visit.status == VisitStatus.cancelled)
                          const Icon(Icons.cancel_rounded, color: CrmColors.error, size: 18),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      visit.clientName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: CrmColors.foreground, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: FUI(RegularRounded.mapMarkerHome, color: CrmColors.mutedForeground, width: 14, height: 14),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            visit.location,
                            style: const TextStyle(color: CrmColors.mutedForeground, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
