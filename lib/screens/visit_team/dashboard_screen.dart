import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../data/visits/visit.dart';
import '../../data/visits/visit_api_service.dart';
import '../../data/visits/dashboard_performance_data.dart';
import '../../widgets/mobile_app_header.dart';
import '../../theme/crm_colors.dart';

class VisitTeamDashboardScreen extends StatefulWidget {
  const VisitTeamDashboardScreen({super.key});

  @override
  State<VisitTeamDashboardScreen> createState() =>
      _VisitTeamDashboardScreenState();
}

class _VisitTeamDashboardScreenState extends State<VisitTeamDashboardScreen> {
  final VisitApiService _apiService = VisitApiService();

  bool _loading = true;
  String? _error;

  DashboardPerformanceData? _performance;
  List<Visit> _missedVisits = const [];
  int _completedCount = 0;
  int _pendingCount = 0;
  int _rescheduledCount = 0;
  int _canceledCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<String?> _getToken() async {
    try {
      final authState = ClerkAuth.of(context, listen: false);
      final sessionToken = await authState.sessionToken();
      return sessionToken.jwt;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      final perfFuture =
          _apiService.fetchDashboardPerformance(authTokenOverride: token);
      final visitsFuture = _apiService.fetchVisits(authTokenOverride: token);

      final results = await Future.wait([perfFuture, visitsFuture]);
      final perfData = results[0] as DashboardPerformanceData?;
      final visits = results[1] as List<Visit>;

      int completed = 0, pending = 0, rescheduled = 0, canceled = 0;
      final missed = <Visit>[];
      final now = DateTime.now();

      for (var v in visits) {
        // Only include visits for the current month
        if (v.scheduledAt == null ||
            v.scheduledAt!.toLocal().month != now.month ||
            v.scheduledAt!.toLocal().year != now.year) {
          continue;
        }

        if (v.status == VisitStatus.completed) {
          completed++;
        } else if (v.status == VisitStatus.rescheduled) {
          rescheduled++;
        } else if (v.status == VisitStatus.cancelled) {
          canceled++;
        } else if (v.status == VisitStatus.scheduled) {
          if (v.scheduledAt!.isBefore(now)) {
            missed.add(v);
          } else {
            pending++;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _performance = perfData;
        _missedVisits = missed;
        _completedCount = completed;
        _pendingCount = pending;
        _rescheduledCount = rescheduled;
        _canceledCount = canceled;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ─── Action handling (same pattern as visits_screen) ──────────────────────

  Future<void> _showVisitActionSheet(Visit visit) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _VisitActionSheet(visit: visit),
    );

    if (action == null || !mounted) return;
    await _handleVisitAction(action, visit);
  }

  Future<void> _handleVisitAction(String action, Visit visit) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await _getToken();

      if (action == 'complete') {
        // Mark as completed directly via PATCH
        await _apiService.updateVisitStatus(
          visit.id,
          'COMPLETED',
          authTokenOverride: token,
        );
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Visit marked as completed'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      } else if (action == 'reschedule') {
        if (!mounted) return;
        final picked = await showDatePicker(
          context: context,
          initialDate: visit.scheduledAt?.toLocal() ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (picked == null || !mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime:
              TimeOfDay.fromDateTime(visit.scheduledAt?.toLocal() ?? DateTime.now()),
        );
        if (time == null || !mounted) return;
        final newDate = DateTime(
            picked.year, picked.month, picked.day, time.hour, time.minute);
        final reason = await _askReason(
          title: 'Reschedule Request',
          hint: 'Why should this visit be rescheduled?',
        );
        if (reason == null) return;
        await _apiService.createVisitUpdateRequest(
          visit.id,
          type: 'RESCHEDULE',
          reason: reason,
          requestedScheduleAt: newDate.toUtc(),
          authTokenOverride: token,
        );
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Reschedule request sent')),
        );
      } else if (action == 'cancel') {
        final reason = await _askReason(
          title: 'Cancel Visit Request',
          hint: 'Why should this visit be cancelled?',
        );
        if (reason == null) return;
        await _apiService.createVisitUpdateRequest(
          visit.id,
          type: 'CANCEL',
          reason: reason,
          authTokenOverride: token,
        );
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Cancel request sent')),
        );
      }
      await _loadDashboardData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text('Action failed: $e'),
              backgroundColor: CrmColors.error));
    }
  }

  Future<String?> _askReason({
    required String title,
    required String hint,
  }) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: CrmColors.brandPrimary),
            onPressed: () {
              final value = ctrl.text.trim();
              if (value.isEmpty) return;
              Navigator.of(ctx).pop(value);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return reason;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      extendBodyBehindAppBar: true,
      appBar: MobileAppHeader(title: 'Dashboard', onRefresh: _loadDashboardData),
      body: _loading
          ? const Center(
              child: SpinKitFoldingCube(color: CrmColors.brandPrimary, size: 40))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: CrmColors.error),
                      const SizedBox(height: 12),
                      Text('Failed to load dashboard',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: CrmColors.brandPrimary),
                          onPressed: _loadDashboardData,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + kToolbarHeight + 16, 16, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                        // ── Title ─────────────────────────────────────────
                        const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: CrmColors.foreground,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fade(duration: 400.ms).slideY(begin: -0.2),

                        const SizedBox(height: 20),

                        // ── Performance Section ─────────────────────────────
                        if (_performance != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CrmColors.brandPrimary.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: CrmColors.brandPrimary.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.insights_rounded, size: 18, color: CrmColors.brandPrimary),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Performance Metrics',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: CrmColors.brandPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: CrmColors.brandPrimary,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: const Text(
                                        'LIVE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 0.4, end: 1.0, duration: 800.ms),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _VisitPerformanceShuffleCard(
                                  topPerf: _performance!.topPerformer,
                                  myPerf: _performance!.currentUserPerformance,
                                  averagePerformance: _performance!.averagePerformance,
                                ),
                              ],
                            ),
                          ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                          const SizedBox(height: 24),
                        ],

                        // ── 4 Stat Cards ──────────────────────────────────
                        const Text(
                          'Visit Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: CrmColors.foreground,
                          ),
                        ).animate().fade(delay: 200.ms).slideX(begin: -0.1),
                        const SizedBox(height: 12),

                        GridView.count(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.25,
                          children: [
                            _StatCard(
                              title: 'Completed',
                              count: _completedCount,
                              icon: Icons.check_circle_rounded,
                              iconColor: const Color(0xFF00A86B),
                              bgColor: const Color(0xFF00A86B).withValues(alpha: 0.08),
                            ),
                            _StatCard(
                              title: 'Pending',
                              count: _pendingCount,
                              icon: Icons.schedule_rounded,
                              iconColor: const Color(0xFFFF6B35),
                              bgColor: const Color(0xFFFF6B35).withValues(alpha: 0.08),
                            ),
                            _StatCard(
                              title: 'Rescheduled',
                              count: _rescheduledCount,
                              icon: Icons.event_repeat_rounded,
                              iconColor: const Color(0xFF6C47FF),
                              bgColor: const Color(0xFF6C47FF).withValues(alpha: 0.08),
                            ),
                            _StatCard(
                              title: 'Canceled',
                              count: _canceledCount,
                              icon: Icons.cancel_rounded,
                              iconColor: const Color(0xFFE5484D),
                              bgColor: const Color(0xFFE5484D).withValues(alpha: 0.08),
                            ),
                          ],
                        ).animate().fade(delay: 300.ms).slideY(begin: 0.1),

                        // ── Missed Schedule Priority ───────────────────────
                        if (_missedVisits.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          _MissedSectionHeader(count: _missedVisits.length)
                              .animate()
                              .fade(delay: 400.ms)
                              .slideX(begin: -0.1),
                          const SizedBox(height: 12),
                          ...List.generate(_missedVisits.length, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _MissedVisitCard(
                                visit: _missedVisits[i],
                                onTap: () =>
                                    _showVisitActionSheet(_missedVisits[i]),
                              ),
                            )
                                .animate()
                                .fade(delay: (450 + i * 60).ms)
                                .slideY(begin: 0.1);
                          }),
                        ],
                      ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ─── Visit Action Sheet ───────────────────────────────────────────────────────

class _VisitActionSheet extends StatelessWidget {
  const _VisitActionSheet({required this.visit});
  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final scheduledStr = visit.scheduledAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a')
            .format(visit.scheduledAt!.toLocal())
        : 'Date not set';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visit summary header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.clientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: CrmColors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 13, color: CrmColors.error),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Missed · $scheduledStr',
                        style: const TextStyle(
                            fontSize: 12, color: CrmColors.error),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: CrmColors.mutedForeground),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      visit.location,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: CrmColors.mutedForeground),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          // Actions
          _SheetTile(
            iconBg: const Color(0xFFE8F5E9),
            iconColor: Color(0xFF2E7D32),
            icon: Icons.check_circle_outlined,
            title: 'Mark as Completed',
            subtitle: 'Record this visit as done',
            value: 'complete',
          ),
          _SheetTile(
            iconBg: const Color(0xFFFFF3E0),
            iconColor: Colors.orange,
            icon: Icons.event_repeat_outlined,
            title: 'Request Reschedule',
            subtitle: 'Pick a new date and send request',
            value: 'reschedule',
          ),
          _SheetTile(
            iconBg: const Color(0xFFFFEBEE),
            iconColor: CrmColors.error,
            icon: Icons.cancel_outlined,
            title: 'Request Cancellation',
            titleColor: CrmColors.error,
            subtitle: 'Send a cancel request',
            value: 'cancel',
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.titleColor = CrmColors.foreground,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration:
            BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w700, color: titleColor)),
      subtitle: Text(subtitle,
          style:
              const TextStyle(fontSize: 12, color: CrmColors.mutedForeground)),
      onTap: () => Navigator.of(context).pop(value),
    );
  }
}

// ─── Missed Visit Card ────────────────────────────────────────────────────────

class _MissedSectionHeader extends StatelessWidget {
  const _MissedSectionHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.notification_important_rounded, size: 20, color: CrmColors.error),
        const SizedBox(width: 8),
        Text(
          'Missed Schedule Priority',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: CrmColors.foreground,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: CrmColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            '$count ACTION${count == 1 ? '' : 'S'}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: CrmColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

class _MissedVisitCard extends StatelessWidget {
  const _MissedVisitCard({required this.visit, required this.onTap});
  final Visit visit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheduledDate = visit.scheduledAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a')
            .format(visit.scheduledAt!.toLocal())
        : 'Date not set';

    final overdueStr = visit.scheduledAt != null
        ? _overdueLabel(visit.scheduledAt!)
        : '';

    final assignedName =
        visit.assignedTo?.fullName ?? visit.assignedTo?.email ?? 'Unassigned';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CrmColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.alarm_off_rounded,
                color: CrmColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visit.clientName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CrmColors.foreground,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: CrmColors.mutedForeground),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          visit.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CrmColors.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$assignedName • Missed $overdueStr',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CrmColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 24),
          ],
        ),
      ),
    );
  }

  String _overdueLabel(DateTime scheduledAt) {
    final diff = DateTime.now().difference(scheduledAt.toLocal());
    if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inMinutes}m';
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.textColor,
    this.bold = false,
  });

  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Performance Card ─────────────────────────────────────────────────────────

class _VisitPerformanceShuffleCard extends StatefulWidget {
  final VisitTopPerformer? myPerf;
  final VisitTopPerformer? topPerf;
  final int averagePerformance;

  const _VisitPerformanceShuffleCard({
    this.myPerf,
    this.topPerf,
    required this.averagePerformance,
  });

  @override
  State<_VisitPerformanceShuffleCard> createState() => _VisitPerformanceShuffleCardState();
}

class _VisitPerformanceShuffleCardState extends State<_VisitPerformanceShuffleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showingTop = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      _toggleCard();
    });
  }

  void _toggleCard() {
    setState(() {
      _showingTop = !_showingTop;
    });
    _controller.forward(from: 0).then((_) {
      if (!mounted) return;
      _controller.value = 1.0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildMyCard(int myScore) {
    final perf = widget.myPerf;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_rounded, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'My Performance',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'This month · Visits',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perf != null
                          ? 'Hey, ${perf.fullName.split(' ').first}! 👋'
                          : 'My Score',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: CrmColors.foreground,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: myScore >= 80
                      ? Colors.green.shade50
                      : myScore >= 55
                          ? Colors.blue.shade50
                          : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: myScore >= 80
                        ? Colors.green.shade200
                        : myScore >= 55
                            ? Colors.blue.shade200
                            : Colors.orange.shade200,
                  ),
                ),
                child: Text(
                  '$myScore',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: myScore >= 80
                        ? Colors.green.shade700
                        : myScore >= 55
                            ? Colors.blue.shade700
                            : Colors.orange.shade700,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Score progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CrmColors.mutedForeground,
                ),
              ),
              Text(
                'Avg: ${widget.averagePerformance}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CrmColors.brandPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (myScore / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: myScore >= 80
                        ? Colors.green.shade500
                        : myScore >= 55
                            ? Colors.blue.shade500
                            : Colors.orange.shade500,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (widget.averagePerformance > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (widget.averagePerformance / 100).clamp(0.0, 1.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 4,
                        height: 12,
                        decoration: BoxDecoration(
                          color: CrmColors.brandPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Your score is based on completed and punctual visits this month.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCard(int topScore) {
    final top = widget.topPerf;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CrmColors.foreground,
            CrmColors.foreground.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CrmColors.foreground.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    const Text(
                      'Top Performer',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'Leading this month',
                style: TextStyle(fontSize: 13, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  (top?.fullName != null && top!.fullName.trim().isNotEmpty) ? top.fullName : 'Top Performer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$topScore',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Score progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                ),
              ),
              const Text(
                'Monthly / 100',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (topScore / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your score is based on completed and punctual visits this month.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myScore = widget.myPerf?.performance ?? 0;
    final topScore = widget.topPerf?.performance ?? 0;

    return GestureDetector(
      onTap: () {
        _startTimer();
        _toggleCard();
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 100) {
          _startTimer();
          _toggleCard();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack);
          final slideOut = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.2, 0)).evaluate(curve);
          final slideIn = Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).evaluate(curve);
          final scaleOut = Tween<double>(begin: 1.0, end: 0.95).evaluate(curve);
          final scaleIn = Tween<double>(begin: 0.95, end: 1.0).evaluate(curve);

          final progress = _controller.value;

          return Stack(
            children: [
              if (_showingTop || progress > 0)
                Transform.translate(
                  offset: Offset((_showingTop ? slideIn.dx : slideOut.dx) * 200, 0),
                  child: Transform.scale(
                    scale: _showingTop ? scaleIn : scaleOut,
                    child: Opacity(
                      opacity: _showingTop ? progress : (1 - progress),
                      child: _buildTopCard(topScore),
                    ),
                  ),
                ),
              if (!_showingTop || progress > 0)
                Transform.translate(
                  offset: Offset((!_showingTop ? slideIn.dx : slideOut.dx) * 200, 0),
                  child: Transform.scale(
                    scale: !_showingTop ? scaleIn : scaleOut,
                    child: Opacity(
                      opacity: !_showingTop ? progress : (1 - progress),
                      child: _buildMyCard(myScore),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: CrmColors.foreground,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CrmColors.mutedForeground,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
