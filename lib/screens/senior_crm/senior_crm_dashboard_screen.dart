import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:fui_kit/fui_kit.dart';
import 'package:intl/intl.dart';

import '../../widgets/mobile_app_header.dart';
import '../../theme/crm_colors.dart';
import '../../config/app_config.dart';
import '../../data/dashboard/sr_dashboard_api_service.dart';
import '../../data/dashboard/sr_dashboard_models.dart';

class SeniorCrmDashboardScreen extends StatefulWidget {
  const SeniorCrmDashboardScreen({super.key});

  @override
  State<SeniorCrmDashboardScreen> createState() => _SeniorCrmDashboardScreenState();
}

class _SeniorCrmDashboardScreenState extends State<SeniorCrmDashboardScreen> {
  final SrDashboardApiService _apiService = SrDashboardApiService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, String> _debugInfo = {};
  SrDashboardData? _data;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _debugInfo = {};
    });
    try {
      final authState = ClerkAuth.of(context, listen: false);
      final sessionToken = await authState.sessionToken();
      final hasToken = sessionToken.jwt.isNotEmpty;

      setState(() {
        _debugInfo = {
          'API URL': '${AppConfig.apiBaseUrl}/api/sr-dashboard',
          'Has session token': hasToken ? 'Yes (${sessionToken.jwt.length} chars)' : 'NO — not logged in',
        };
      });

      if (!hasToken) throw Exception('No session token. Are you logged in?');

      final data = await _apiService.fetchDashboardData(sessionToken.jwt);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String _formatRelativeTime(DateTime? date) {
    if (date == null) return 'Needs attention';
    final diff = date.difference(DateTime.now());
    final absDiff = diff.abs();
    
    if (absDiff.inMinutes < 60) {
      return diff.isNegative ? '${absDiff.inMinutes}m overdue' : 'in ${absDiff.inMinutes}m';
    } else if (absDiff.inHours < 24) {
      return diff.isNegative ? '${absDiff.inHours}h overdue' : 'in ${absDiff.inHours}h';
    } else {
      return diff.isNegative ? '${absDiff.inDays}d overdue' : 'in ${absDiff.inDays}d';
    }
  }

  String _formatMoney(double? value) {
    if (value == null || value <= 0) return 'Budget not set';
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return format.format(value);
  }
  
  String _formatLabel(String? value) {
    if (value == null) return 'N/A';
    if (value == 'DISCOVERY') return 'Consulting Phase';
    if (value == 'PROPOSAL_SENT') return 'Quotation Sent';
    return value
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  List<Map<String, dynamic>> _buildPriorityActions() {
    if (_data == null) return [];
    
    List<Map<String, dynamic>> actions = [];
    final now = DateTime.now();

    for (var task in _data!.overdueCadTasks) {
      actions.add({
        'title': task.lead.name,
        'label': 'CAD deadline missed',
        'detail': '${task.assigneeName} • ${_formatLabel(task.status)}',
        'tone': 'critical',
        'time': task.dueAt,
      });
    }

    for (var sub in _data!.reviewSubmissions) {
      actions.add({
        'title': sub.lead.name,
        'label': 'CAD review waiting',
        'detail': '${sub.submittedBy} submitted ${sub.fileCount} file(s)',
        'tone': 'warning',
        'time': sub.submittedAt,
      });
    }

    for (var task in _data!.overdueQuotationTasks) {
      actions.add({
        'title': task.lead.name,
        'label': 'Quotation deadline missed',
        'detail': '${task.assigneeName} • ${_formatLabel(task.status)}',
        'tone': 'critical',
        'time': task.dueAt,
      });
    }
    
    if (_data!.designWatch.overdueQueueCount > 0) {
      actions.add({
        'title': '${_data!.designWatch.overdueQueueCount} design item(s)',
        'label': 'Design queue overdue',
        'detail': 'Visualization queue items are aging past 48 hours.',
        'tone': 'critical',
        'time': now.subtract(const Duration(hours: 48)),
      });
    }
    
    if (_data!.visitInsights.pendingOverdueCount > 0) {
      actions.add({
        'title': '${_data!.visitInsights.pendingOverdueCount} visit pending result',
        'label': 'Visit result overdue',
        'detail': 'Scheduled visit time passed but no result submission.',
        'tone': 'critical',
        'time': now,
      });
    }
    
    for (var item in _data!.visitItems.take(3)) {
      actions.add({
        'title': item.leadName,
        'label': 'Visit output ready',
        'detail': '${item.assignedLeadName ?? 'Visit team'} completed site work',
        'tone': 'info',
        'time': item.latestVisitTime ?? now,
      });
    }
    
    for (var meeting in _data!.upcomingMeetings) {
      actions.add({
        'title': meeting.lead.name,
        'label': meeting.type == 'BUDGET_MEETING' ? 'Budget meeting upcoming' : 'Client meeting upcoming',
        'detail': meeting.title,
        'tone': 'success',
        'time': meeting.startsAt,
      });
    }
    
    actions.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));
    return actions.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: MobileAppHeader(
        title: 'Command Center',
        onRefresh: _fetchDashboard,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboard,
        color: CrmColors.brandPrimary,
        child: _errorMessage != null
            ? ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.error_outline, color: Colors.red, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Dashboard failed to load',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  // Debug info panel
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔍 DEBUG INFO',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Divider(color: Colors.grey),
                        ..._debugInfo.entries.map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                entry.value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        )),
                        const Divider(color: Colors.grey),
                        const Text(
                          'ERROR',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _fetchDashboard,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              )
            : Skeletonizer(
                enabled: _isLoading,
                child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHero(),
                    const SizedBox(height: 24),
                    _buildQueueGrid(),
                    const SizedBox(height: 24),
                    _buildPriorityActionsCard(),
                    const SizedBox(height: 24),
                    _buildUpcomingMeetingsCard(),
                    const SizedBox(height: 24),
                    _buildBudgetWatchCard(),
                    const SizedBox(height: 100), // Bottom padding for nav
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return _PerformanceShuffleCard(
      myPerf: _data?.performance?.current,
      topPerf: _data?.performance?.top,
    );
  }

  Widget _buildQueueGrid() {
    final counts = _data?.queueCounts;

    final List<_QueueCard> queues = [
      _QueueCard(
        title: 'Visit Queue',
        value: counts?.visit ?? 0,
        icon: Icons.map_outlined,
        bgColor: Colors.teal.shade50,
        iconColor: Colors.teal.shade700,
      ),
      _QueueCard(
        title: 'CAD Queue',
        value: counts?.cad ?? 0,
        icon: Icons.design_services_outlined,
        bgColor: Colors.lightBlue.shade50,
        iconColor: Colors.lightBlue.shade700,
      ),
      _QueueCard(
        title: 'Review Center',
        value: counts?.review ?? 0,
        icon: Icons.fact_check_outlined,
        bgColor: Colors.amber.shade50,
        iconColor: Colors.amber.shade700,
      ),
      _QueueCard(
        title: 'Meeting Queue',
        value: counts?.meeting ?? 0,
        icon: Icons.handshake_outlined,
        bgColor: const Color(0xFFEDE7F6),
        iconColor: Colors.deepPurple.shade700,
      ),
      _QueueCard(
        title: 'Budget Queue',
        value: counts?.budget ?? 0,
        icon: Icons.account_balance_wallet_outlined,
        bgColor: const Color(0xFFFCE4EC),
        iconColor: Colors.pink.shade700,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Queue Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: queues.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final queue = queues[index];
              return Container(
                width: 140,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: queue.bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(queue.icon, color: queue.iconColor, size: 20),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          queue.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${queue.value}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'open',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityActionsCard() {
    final actions = _buildPriorityActions();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: CrmColors.error, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Priority Action',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${actions.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (actions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.grey.shade300, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'No urgent action right now',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final action = actions[index];
                final isCritical = action['tone'] == 'critical';
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCritical ? Colors.red.withValues(alpha: 0.03) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCritical ? Colors.red.withValues(alpha: 0.1) : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCritical ? Colors.red : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              action['label'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCritical ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Text(
                            _formatRelativeTime(action['time']),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isCritical ? Colors.red.shade700 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action['title'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action['detail'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMeetingsCard() {
    final meetings = _data?.upcomingMeetings ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: CrmColors.brandPrimary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Upcoming Meetings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (meetings.isEmpty)
            Text(
              'No meetings scheduled in the next 7 days.',
              style: TextStyle(color: Colors.grey.shade500),
            )
          else
            Column(
              children: meetings.map((meeting) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: CrmColors.brandPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meeting.lead.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatLabel(meeting.type)} • ${_formatRelativeTime(meeting.startsAt)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetWatchCard() {
    final leads = _data?.budgetLeads ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: Colors.pinkAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Budget Watch',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (leads.isEmpty)
            Text(
              'No active budget records.',
              style: TextStyle(color: Colors.grey.shade500),
            )
          else
            Column(
              children: leads.map((lead) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lead.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${lead.assigneeName ?? 'Unassigned'} • ${_formatMoney(lead.budget)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatLabel(lead.subStatus),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _QueueCard {
  final String title;
  final int value;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _QueueCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

// ─── Performance Shuffle Card ────────────────────────────────────────────────

class _PerformanceShuffleCard extends StatefulWidget {
  final SrPerformanceMember? myPerf;
  final SrPerformanceMember? topPerf;

  const _PerformanceShuffleCard({this.myPerf, this.topPerf});

  @override
  State<_PerformanceShuffleCard> createState() => _PerformanceShuffleCardState();
}

class _PerformanceShuffleCardState extends State<_PerformanceShuffleCard>
    with TickerProviderStateMixin {
  late AnimationController _shuffleController;
  late Animation<double> _slideAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _fadeAnim;

  bool _showingMine = true;

  @override
  void initState() {
    super.initState();
    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shuffleController, curve: Curves.easeInOutCubic),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0), weight: 50),
    ]).animate(_shuffleController);
    _rotateAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.04), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -0.04, end: 0.0), weight: 50),
    ]).animate(_shuffleController);
    _fadeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 60),
    ]).animate(_shuffleController);

    // Auto-shuffle every 4 seconds
    Future.delayed(const Duration(seconds: 4), _autoShuffle);
  }

  void _autoShuffle() {
    if (!mounted) return;
    _doShuffle();
    Future.delayed(const Duration(seconds: 4), _autoShuffle);
  }

  void _doShuffle() {
    if (!mounted) return;
    _shuffleController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _showingMine = !_showingMine);
      }
    });
  }

  @override
  void dispose() {
    _shuffleController.dispose();
    super.dispose();
  }

  Color _scoreColor(int score) => score >= 80
      ? Colors.green.shade600
      : score >= 55
          ? Colors.lightBlue.shade700
          : Colors.amber.shade700;

  Color _scoreBg(int score) => score >= 80
      ? Colors.green.shade50
      : score >= 55
          ? Colors.lightBlue.shade50
          : Colors.amber.shade50;

  String _scoreLabel(int score) => score >= 80
      ? 'Excellent'
      : score >= 55
          ? 'Good'
          : 'Needs Focus';

  @override
  Widget build(BuildContext context) {
    final myScore = widget.myPerf?.totalPerformance ?? 0;
    final topScore = widget.topPerf?.totalPerformance ?? 0;

    return GestureDetector(
      onTap: _doShuffle,
      child: AnimatedBuilder(
        animation: _shuffleController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              // Card slides left on exit, comes from right on enter
              _slideAnim.value < 0.5
                  ? -40 * _slideAnim.value * 2
                  : 40 * (1 - _slideAnim.value) * 2,
              0,
            ),
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Transform.rotate(
                angle: _rotateAnim.value,
                child: Opacity(
                  opacity: _fadeAnim.value.clamp(0.0, 1.0),
                  child: _showingMine
                      ? _buildMyCard(myScore, topScore)
                      : _buildTopCard(topScore),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyCard(int myScore, int topScore) {
    final perf = widget.myPerf;
    final color = _scoreColor(myScore);
    final bg = _scoreBg(myScore);
    final label = _scoreLabel(myScore);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_rounded, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      'My Performance',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              // Tap hint
              Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text(
                    'tap to flip',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name + Score
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perf != null
                          ? 'Hey, ${perf.name.split(' ').first}! 👋'
                          : 'My Score',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This month · SR CRM',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    if (perf != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Working on ${perf.activeProjectSqft} sqft',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      '$myScore',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
              if (topScore > 0)
                Text(
                  'Top: $topScore',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(height: 6),
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
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Top performer marker
              if (topScore > 0)
                FractionallySizedBox(
                  widthFactor: (topScore / 100).clamp(0.0, 1.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 2,
                      height: 10,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
            ],
          ),
          if (perf != null) ...[
            const SizedBox(height: 18),
            // Sub-scores
            Row(
              children: [
                _subChip('Review', perf.reviewScore, 35, Colors.purple.shade600, perf.reviewCount),
                const SizedBox(width: 8),
                _subChip('Meeting', perf.meetingScore, 25, Colors.lightBlue.shade700, perf.meetingCount),
                const SizedBox(width: 8),
                _subChip('Convert', perf.conversionScore, 25, Colors.green.shade700, perf.conversionCount),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopCard(int topScore) {
    final top = widget.topPerf;
    final color = _scoreColor(topScore);
    final bg = _scoreBg(topScore);
    final label = _scoreLabel(topScore);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🏆', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      'Top Performer',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white30),
                  const SizedBox(width: 3),
                  const Text(
                    'tap to flip',
                    style: TextStyle(fontSize: 10, color: Colors.white30),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (top?.name != null && top!.name.trim().isNotEmpty) ? top.name : 'Top Performer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Leading this month',
                      style: TextStyle(fontSize: 13, color: Colors.white54),
                    ),
                    if (top != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Working on ${top.activeProjectSqft} sqft',
                          style: TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$topScore',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber,
                        height: 1,
                      ),
                    ),
                    const Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const Text(
                'Monthly / 100',
                style: TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
          if (top != null) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                _subChip('Review', top.reviewScore, 35, Colors.purple.shade300, top.reviewCount),
                const SizedBox(width: 8),
                _subChip('Meeting', top.meetingScore, 25, Colors.lightBlue.shade300, top.meetingCount),
                const SizedBox(width: 8),
                _subChip('Convert', top.conversionScore, 25, Colors.green.shade300, top.conversionCount),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _subChip(String label, int score, int weight, Color color, int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text('$score',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: color, height: 1)),
            Text('/$weight · $count',
                style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}
