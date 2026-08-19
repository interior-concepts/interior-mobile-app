import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fui_kit/fui_kit.dart';

import '../../data/visits/visit.dart';
import '../../data/visits/visit_api_service.dart';
import '../../data/user/user_api_service.dart';
import '../../widgets/mobile_app_header.dart';
import '../../theme/crm_colors.dart';
import '../../widgets/visit_card_widget.dart';

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
  String? _currentUserId;

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
      if (token != null) {
        try {
          final user = await UserApiService().fetchMe(token);
          _currentUserId = user?.id;
        } catch (_) {}
      }
      
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VisitCardWidget(
                          visit: visit,
                          currentUserId: _currentUserId,
                          onTap: () => _showVisitActionMenu(visit),
                          onLongPress: () => _showVisitActionMenu(visit),
                        ).animate().fade(delay: (300 + (index * 80)).ms).slideX(begin: 0.1),
                      );
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

  Future<void> _showVisitActionMenu(Visit visit) async {
    final isAssigned = _currentUserId != null &&
        visit.assignedToId != null &&
        _currentUserId == visit.assignedToId;

    if (!isAssigned) {
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => SupportMemberSheet(visit: visit),
      );
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Complete'),
                onTap: () => Navigator.of(ctx).pop('complete'),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1_outlined),
                title: const Text('Add Support Members'),
                onTap: () => Navigator.of(ctx).pop('add_support'),
              ),
              ListTile(
                leading: const Icon(Icons.event_repeat_outlined),
                title: const Text('Reschedule'),
                onTap: () => Navigator.of(ctx).pop('reschedule'),
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(ctx).pop('cancel'),
              ),
            ],
          ),
        );
      },
    );

    if (action == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action "$action" needs to be implemented here (like in Visits page)')),
    );
  }
}
