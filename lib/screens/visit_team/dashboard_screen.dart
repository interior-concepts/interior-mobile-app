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
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
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
                                _StackedPerformanceCards(
                                  topPerformer: _performance!.topPerformer,
                                  currentUserPerformance: _performance!.currentUserPerformance,
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
                              color: const Color(0xFF00A86B),
                              gradientColors: const [Color(0xFF00C87A), Color(0xFF007A4D)],
                            ),
                            _StatCard(
                              title: 'Pending',
                              count: _pendingCount,
                              icon: Icons.schedule_rounded,
                              color: const Color(0xFFFF6B35),
                              gradientColors: const [Color(0xFFFF8C42), Color(0xFFE84E0F)],
                            ),
                            _StatCard(
                              title: 'Rescheduled',
                              count: _rescheduledCount,
                              icon: Icons.event_repeat_rounded,
                              color: const Color(0xFF6C47FF),
                              gradientColors: const [Color(0xFF8B6EFF), Color(0xFF5232D4)],
                            ),
                            _StatCard(
                              title: 'Canceled',
                              count: _canceledCount,
                              icon: Icons.cancel_rounded,
                              color: const Color(0xFFE5484D),
                              gradientColors: const [Color(0xFFFF6B6B), Color(0xFFC0392B)],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CrmColors.error,
            CrmColors.error.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CrmColors.error.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Missed Schedule Priority',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count visit${count == 1 ? '' : 's'} require immediate attention · Tap a card to act',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CrmColors.error.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: CrmColors.error.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Red overdue banner
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: CrmColors.error.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alarm_off_rounded,
                      size: 13, color: CrmColors.error),
                  const SizedBox(width: 6),
                  Text(
                    'Overdue · $overdueStr',
                    style: const TextStyle(
                        color: CrmColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 11),
                  ),
                ],
              ),
            ),
            // Card body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client name row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          visit.clientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: CrmColors.foreground,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      // Tap to act badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: CrmColors.brandPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded,
                                size: 11, color: CrmColors.brandPrimary),
                            SizedBox(width: 4),
                            Text(
                              'TAP TO ACT',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: CrmColors.brandPrimary,
                                  letterSpacing: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Location
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: visit.location,
                    iconColor: CrmColors.brandPrimary.withValues(alpha: 0.6),
                    textColor: CrmColors.mutedForeground,
                  ),
                  const SizedBox(height: 6),

                  // Scheduled date
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text: scheduledDate,
                    iconColor: CrmColors.brandPrimary.withValues(alpha: 0.6),
                    textColor: CrmColors.mutedForeground,
                    bold: true,
                  ),
                  const SizedBox(height: 10),

                  // Divider + assigned
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    text: 'Assigned to: $assignedName',
                    iconColor: CrmColors.brandPrimary,
                    textColor: CrmColors.brandPrimary,
                    bold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _overdueLabel(DateTime scheduledAt) {
    final diff = DateTime.now().difference(scheduledAt.toLocal());
    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inMinutes}m ago';
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

class _StackedPerformanceCards extends StatefulWidget {
  const _StackedPerformanceCards({
    required this.topPerformer,
    required this.currentUserPerformance,
  });

  final VisitTopPerformer? topPerformer;
  final VisitTopPerformer? currentUserPerformance;

  @override
  State<_StackedPerformanceCards> createState() => _StackedPerformanceCardsState();
}

class _StackedPerformanceCardsState extends State<_StackedPerformanceCards> {
  bool _isMineFront = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        _isMineFront = !_isMineFront;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topScore = widget.topPerformer?.performance ?? 1;
    final myScore = widget.currentUserPerformance?.performance ?? 0;
    
    final maxScore = topScore > 0 ? topScore : 1; 
    final myProgress = (myScore / maxScore).clamp(0.0, 1.0);

    final topCard = _PerformanceCard(
      title: 'Top Performer',
      name: widget.topPerformer?.fullName ?? 'N/A',
      score: widget.topPerformer?.performance ?? 0,
      icon: Icons.emoji_events_rounded,
      gradientColors: const [Color(0xFFFFB347), Color(0xFFFF6B00)],
      accentColor: Colors.amber,
      isTop: true,
    );

    final myCard = _PerformanceCard(
      title: 'My Performance',
      name: widget.currentUserPerformance?.fullName ?? 'You',
      score: widget.currentUserPerformance?.performance ?? 0,
      icon: Icons.person_rounded,
      gradientColors: const [Color(0xFF8B6EFF), Color(0xFF5232D4)],
      accentColor: CrmColors.brandPrimary,
    );

    final topCardWidget = AnimatedPositioned(
      key: const ValueKey('topCard'),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      top: !_isMineFront ? 24 : 0,
      left: !_isMineFront ? 0 : 24,
      right: !_isMineFront ? 24 : 0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        scale: !_isMineFront ? 1.0 : 0.88,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          opacity: !_isMineFront ? 1.0 : 0.35,
          child: topCard,
        ),
      ),
    );

    final myCardWidget = AnimatedPositioned(
      key: const ValueKey('myCard'),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      top: _isMineFront ? 24 : 0,
      left: _isMineFront ? 0 : 24,
      right: _isMineFront ? 24 : 0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        scale: _isMineFront ? 1.0 : 0.88,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          opacity: _isMineFront ? 1.0 : 0.35,
          child: myCard,
        ),
      ),
    );

    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: _isMineFront
            ? [topCardWidget, myCardWidget]
            : [myCardWidget, topCardWidget],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.title,
    required this.name,
    required this.score,
    required this.icon,
    required this.gradientColors,
    required this.accentColor,
    this.progress,
    this.isTop = false,
  });

  final String title;
  final String name;
  final int score;
  final IconData icon;
  final List<Color> gradientColors;
  final Color accentColor;
  final double? progress;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: -6,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Large bg decorative icon
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 110,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (isTop)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text(
                            '🏆 #1',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Score
                  Text(
                    score.toString(),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 16),
                    // Progress label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'vs. Top Performer',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(progress! * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 7,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
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
    required this.color,
    required this.gradientColors,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.45),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Decorative large background icon
          Positioned(
            right: -16,
            bottom: -16,
            child: Icon(
              icon,
              size: 90,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          // Decorative circle accent top-right
          Positioned(
            top: -18,
            right: -18,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon badge
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: Colors.white),
                ),
                // Count + label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
