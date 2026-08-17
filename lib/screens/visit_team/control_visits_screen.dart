import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../../data/visits/visit.dart';
import '../../data/visits/visit_api_service.dart';
import '../../theme/crm_colors.dart';
import '../../widgets/mobile_app_header.dart';

class ControlVisitsScreen extends StatefulWidget {
  const ControlVisitsScreen({super.key});

  @override
  State<ControlVisitsScreen> createState() => _ControlVisitsScreenState();
}

class _ControlVisitsScreenState extends State<ControlVisitsScreen> {
  final VisitApiService _visitApiService = VisitApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Visit> _visits = const [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
    _loadAllPendingVisits();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  Future<void> _loadAllPendingVisits() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _getClerkJwt();
      final visits = await _visitApiService.fetchVisits(
        status: 'SCHEDULED',
        scope: 'all',
        accessContext: 'queue',
        authTokenOverride: token,
      );
      if (!mounted) return;
      setState(() {
        _visits = visits;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _visits = const [];
      });
    }
  }

  List<Visit> get _filtered {
    if (_query.isEmpty) return _visits;
    return _visits.where((v) {
      return v.clientName.toLowerCase().contains(_query) ||
          v.location.toLowerCase().contains(_query) ||
          (v.assignedTo?.fullName?.toLowerCase().contains(_query) ?? false);
    }).toList();
  }

  Future<void> _showActionSheet(Visit visit) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ActionSheet(
        visit: visit,
        visitApiService: _visitApiService,
        getJwt: _getClerkJwt,
        onDone: _loadAllPendingVisits,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: MobileAppHeader(title: 'Visit Control', onRefresh: _loadAllPendingVisits),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Breadcrumbs + Title ────────────────────────────────────────
          _buildHeader(context),

          // ── Search Bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _SearchBar(controller: _searchCtrl),
          ),

          // ── Visit List ─────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: SpinKitFoldingCube(color: CrmColors.brandPrimary, size: 40),
                  )
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _loadAllPendingVisits)
                    : filtered.isEmpty
                        ? _EmptyView(hasQuery: _query.isNotEmpty)
                        : RefreshIndicator(
                            onRefresh: _loadAllPendingVisits,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _VisitCard(
                                  visit: filtered[i],
                                  onLongPress: () => _showActionSheet(filtered[i]),
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              const Icon(Icons.home_outlined, size: 14, color: CrmColors.mutedForeground),
              const SizedBox(width: 4),
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 12,
                  color: CrmColors.mutedForeground,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, size: 14, color: CrmColors.mutedForeground),
              ),
              const Icon(Icons.admin_panel_settings_outlined, size: 14, color: CrmColors.brandPrimary),
              const SizedBox(width: 4),
              const Text(
                'Visit Control',
                style: TextStyle(
                  fontSize: 12,
                  color: CrmColors.brandPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Screen title + count
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Visit Control',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: CrmColors.foreground,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _loading
                    ? 'Loading visits...'
                    : '${_visits.length} pending visit${_visits.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: CrmColors.mutedForeground,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, color: CrmColors.foreground),
        decoration: InputDecoration(
          hintText: 'Search visits...',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: CrmColors.mutedForeground,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.search_rounded, color: CrmColors.mutedForeground, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, val, x) => val.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: controller.clear,
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: CrmColors.mutedForeground),
                  ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ─── Visit Card ───────────────────────────────────────────────────────────────

class _VisitCard extends StatefulWidget {
  const _VisitCard({required this.visit, required this.onLongPress});

  final Visit visit;
  final VoidCallback onLongPress;

  @override
  State<_VisitCard> createState() => _VisitCardState();
}

class _VisitCardState extends State<_VisitCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final onLongPress = widget.onLongPress;
    final scheduledDate = visit.scheduledAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(visit.scheduledAt!.toLocal())
        : 'Date not set';

    final assignedName =
        visit.assignedTo?.fullName ?? visit.assignedTo?.email ?? 'Unassigned';

    Color statusFg;
    Color statusBg;
    Color statusBorder;
    IconData statusIcon;
    String statusLabel;

    switch (visit.status) {
      case VisitStatus.scheduled:
        statusFg = CrmColors.brandPrimary;
        statusBg = CrmColors.brandPrimary.withValues(alpha: 0.1);
        statusBorder = CrmColors.brandPrimary.withValues(alpha: 0.2);
        statusIcon = Icons.schedule_outlined;
        statusLabel = 'Scheduled';
        break;
      case VisitStatus.completed:
        statusFg = const Color(0xFF2E7D32);
        statusBg = const Color(0xFF2E7D32).withValues(alpha: 0.1);
        statusBorder = const Color(0xFF2E7D32).withValues(alpha: 0.2);
        statusIcon = Icons.check_circle_outline;
        statusLabel = 'Completed';
        break;
      case VisitStatus.rescheduled:
        statusFg = const Color(0xFF1565C0);
        statusBg = const Color(0xFF1565C0).withValues(alpha: 0.1);
        statusBorder = const Color(0xFF1565C0).withValues(alpha: 0.2);
        statusIcon = Icons.event_repeat_outlined;
        statusLabel = 'Rescheduled';
        break;
      case VisitStatus.cancelled:
        statusFg = CrmColors.error;
        statusBg = CrmColors.error.withValues(alpha: 0.1);
        statusBorder = CrmColors.error.withValues(alpha: 0.2);
        statusIcon = Icons.cancel_outlined;
        statusLabel = 'Cancelled';
        break;
      default:
        statusFg = CrmColors.mutedForeground;
        statusBg = CrmColors.mutedForeground.withValues(alpha: 0.1);
        statusBorder = CrmColors.mutedForeground.withValues(alpha: 0.2);
        statusIcon = Icons.help_outline;
        statusLabel = 'Unknown';
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF8F9FE), // very light tint for premium look
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(24),
            splashColor: CrmColors.brandPrimary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(32), // p-8
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title row ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          visit.clientName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: CrmColors.foreground,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: statusBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusFg),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusFg,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24), // mb-6 equivalent between title and body

                  // ── Date ──
                  _CardRow(
                    iconBg: Colors.white,
                    iconColor: CrmColors.brandPrimary.withValues(alpha: 0.6),
                    icon: Icons.calendar_today_outlined,
                    text: scheduledDate,
                    shadowColor: Colors.black.withValues(alpha: 0.05),
                    bold: true,
                  ),

                  if (_isExpanded) ...[
                    const SizedBox(height: 16), // space-y-4
                    // ── Location ──
                    _CardRow(
                      iconBg: Colors.white,
                      iconColor: CrmColors.brandPrimary.withValues(alpha: 0.6),
                      icon: Icons.location_on_outlined,
                      text: visit.location,
                      shadowColor: Colors.black.withValues(alpha: 0.05),
                    ),

                    // ── Assigned to ──
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.only(top: 16), // pt-4
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2), // border-t
                          ),
                        ),
                      ),
                      child: _CardRow(
                        iconBg: CrmColors.brandPrimary.withValues(alpha: 0.05), // bg-primary/5
                        iconColor: CrmColors.brandPrimary,
                        icon: Icons.person_outline_rounded,
                        text: 'Assigned to: $assignedName',
                        textColor: CrmColors.brandPrimary,
                        bold: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),

                  // ── Pending requests badge ──
                  if (visit.updateRequests.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pending_actions_outlined,
                              size: 13, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text(
                            '${visit.updateRequests.length} pending request${visit.updateRequests.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF795548),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Long press hint ──
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Icon(Icons.touch_app_outlined,
                          size: 11, color: CrmColors.mutedForeground),
                      SizedBox(width: 4),
                      Text(
                        'Long press to manage',
                        style: TextStyle(
                            fontSize: 11, color: CrmColors.mutedForeground),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.text,
    this.textColor = CrmColors.mutedForeground,
    this.bold = false,
    this.shadowColor,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String text;
  final Color textColor;
  final bool bold;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: shadowColor != null
                ? [BoxShadow(color: shadowColor!, blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Action Sheet ─────────────────────────────────────────────────────────────

class _ActionSheet extends StatefulWidget {
  const _ActionSheet({
    required this.visit,
    required this.visitApiService,
    required this.getJwt,
    required this.onDone,
  });

  final Visit visit;
  final VisitApiService visitApiService;
  final Future<String?> Function() getJwt;
  final VoidCallback onDone;

  @override
  State<_ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends State<_ActionSheet> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onDone();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Done!'),
          backgroundColor: CrmColors.brandPrimary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: CrmColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onReassign() async {
    final token = await widget.getJwt();
    List<VisitUser> members = [];
    try {
      members = await widget.visitApiService
          .fetchVisitTeamMembers(authTokenOverride: token);
    } catch (_) {}
    if (!mounted) return;

    VisitUser? selected;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reassign Visit',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: members.isEmpty
              ? const Text('No visit team members found.')
              : DropdownButtonFormField<VisitUser>(
                  decoration: const InputDecoration(
                    labelText: 'Select member',
                    border: OutlineInputBorder(),
                  ),
                  items: members
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.fullName ?? m.email ?? 'Unknown'),
                          ))
                      .toList(),
                  onChanged: (v) => selected = v,
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: members.isEmpty ? null : () => Navigator.pop(ctx, true),
            child: const Text('Reassign'),
          ),
        ],
      ),
    );
    if (confirmed != true || selected?.id == null) return;
    await _run(() => widget.visitApiService.reassignVisit(
          widget.visit.id,
          selected!.id!,
          authTokenOverride: token,
        ));
  }

  Future<void> _onReschedule() async {
    final now = DateTime.now();
    final initial = (widget.visit.scheduledAt?.isAfter(now) ?? false)
        ? widget.visit.scheduledAt!.toLocal()
        : now.add(const Duration(days: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null || !mounted) return;

    final newDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
        pickedTime.hour, pickedTime.minute);

    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Reschedule',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEBFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: CrmColors.brandPrimary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(newDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: CrmColors.brandPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    reasonCtrl.dispose();
    if (confirmed != true) return;

    final token = await widget.getJwt();
    await _run(() => widget.visitApiService.rescheduleVisitByLeader(
          widget.visit.id,
          newDate,
          reason:
              reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
          authTokenOverride: token,
        ));
  }

  Future<void> _onCancel() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Visit',
            style: TextStyle(fontWeight: FontWeight.w700, color: CrmColors.error)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'Why is this visit being cancelled?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Back')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CrmColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Visit'),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
    if (confirmed != true) return;

    final token = await widget.getJwt();
    await _run(() => widget.visitApiService.cancelVisit(
          widget.visit.id,
          reason:
              reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
          authTokenOverride: token,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final scheduledStr = visit.scheduledAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(visit.scheduledAt!.toLocal())
        : 'Date not set';

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visit summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visit.clientName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: CrmColors.foreground)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: CrmColors.mutedForeground),
                    const SizedBox(width: 4),
                    Text(scheduledStr,
                        style: const TextStyle(
                            fontSize: 12, color: CrmColors.mutedForeground)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: CrmColors.mutedForeground),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(visit.location,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: CrmColors.mutedForeground)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),

          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                  child: SpinKitFoldingCube(
                      color: CrmColors.brandPrimary, size: 32)),
            )
          else ...[
            // ── Reassign ──
            _ActionTile(
              iconBg: const Color(0xFFEEEBFF),
              iconColor: CrmColors.brandPrimary,
              icon: Icons.swap_horiz_rounded,
              title: 'Reassign',
              subtitle: 'Move to a different team member',
              onTap: _onReassign,
            ),
            // ── Reschedule ──
            _ActionTile(
              iconBg: const Color(0xFFFFF3E0),
              iconColor: Colors.orange,
              icon: Icons.event_repeat_outlined,
              title: 'Reschedule',
              subtitle: 'Set a new date and time',
              onTap: _onReschedule,
            ),
            // ── Cancel ──
            _ActionTile(
              iconBg: const Color(0xFFFFEBEE),
              iconColor: CrmColors.error,
              icon: Icons.cancel_outlined,
              title: 'Cancel Visit',
              subtitle: 'Mark this visit as cancelled',
              titleColor: CrmColors.error,
              onTap: _onCancel,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor = CrmColors.foreground,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w700, color: titleColor)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 12, color: CrmColors.mutedForeground)),
      onTap: onTap,
    );
  }
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasQuery});
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery ? Icons.search_off_rounded : Icons.check_circle_outline,
            size: 56,
            color: hasQuery ? CrmColors.mutedForeground : Colors.green[400],
          ),
          const SizedBox(height: 12),
          Text(
            hasQuery ? 'No results found' : 'No pending visits',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CrmColors.foreground),
          ),
          const SizedBox(height: 4),
          Text(
            hasQuery
                ? 'Try a different search term'
                : 'All visits are up to date.',
            style: const TextStyle(
                fontSize: 13, color: CrmColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: CrmColors.error),
            const SizedBox(height: 12),
            const Text('Failed to load visits',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CrmColors.foreground)),
            const SizedBox(height: 4),
            Text(error,
                style: const TextStyle(
                    fontSize: 12, color: CrmColors.mutedForeground),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: CrmColors.brandPrimary),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
