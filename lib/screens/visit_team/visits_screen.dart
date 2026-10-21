import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../data/visits/visit.dart';
import '../../data/visits/visit_api_service.dart';
import '../../data/user/user_api_service.dart';
import '../../widgets/mobile_app_header.dart';
import '../../widgets/visit_card_widget.dart';
import '../../theme/crm_colors.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final VisitApiService _visitApiService = VisitApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Visit> _visits = const [];
  bool _loading = true;
  String? _errorMessage;
  String _searchQuery = '';
  _VisitsFilter _activeFilter = _VisitsFilter.all;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getClerkJwt();
      if (token != null) {
        try {
          final user = await UserApiService().fetchMe(token);
          _currentUserId = user?.id;
        } catch (_) {}
      }

      final items = await _visitApiService.fetchVisits(
        authTokenOverride: token,
      );
      if (!mounted) return;
      
      final now = DateTime.now();
      final thisMonthItems = items.where((v) {
        if (v.scheduledAt == null) return false;
        final local = v.scheduledAt!.toLocal();
        return local.month == now.month && local.year == now.year;
      }).toList();

      setState(() {
        _visits = thisMonthItems;
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }


  int _countToday() {
    final now = DateTime.now();
    return _visits.where((visit) => visit.isScheduledOn(now)).length;
  }

  int _countByStatus(VisitStatus status) {
    return _visits.where((visit) => visit.status == status).length;
  }

  List<Visit> _filteredVisits() {
    final now = DateTime.now();
    List<Visit> base;
    switch (_activeFilter) {
      case _VisitsFilter.today:
        base = _visits.where((v) => v.isScheduledOn(now)).toList();
        break;
      case _VisitsFilter.pending:
        base = _visits.where((v) => v.status == VisitStatus.scheduled).toList();
        break;
      case _VisitsFilter.completed:
        base = _visits.where((v) => v.status == VisitStatus.completed).toList();
        break;
      case _VisitsFilter.all:
        base = _visits;
    }
    if (_searchQuery.isEmpty) return base;
    return base.where((v) {
      return v.clientName.toLowerCase().contains(_searchQuery) ||
          v.location.toLowerCase().contains(_searchQuery) ||
          (v.displayClientId?.toLowerCase().contains(_searchQuery) ?? false) ||
          (v.clientId?.toLowerCase().contains(_searchQuery) ?? false) ||
          (v.leadId?.toLowerCase().contains(_searchQuery) ?? false) ||
          (v.assignedTo?.fullName?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final filteredVisits = _filteredVisits();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: MobileAppHeader(title: 'Visits', onRefresh: _loadVisits),
      body: RefreshIndicator(
        onRefresh: _loadVisits,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Breadcrumbs ───────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.home_outlined,
                      size: 14, color: Color(0xFF6A6A6A)),
                  const SizedBox(width: 4),
                  const Text('Dashboard',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6A6A6A),
                          fontWeight: FontWeight.w400)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.chevron_right,
                        size: 14, color: Color(0xFF6A6A6A)),
                  ),
                  const Icon(Icons.assignment_outlined,
                      size: 14, color: Color(0xFF6C47FF)),
                  const SizedBox(width: 4),
                  const Text('Visits',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C47FF),
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),

              // ── Header ───────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Visits',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF171717),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _loading
                            ? 'Loading...'
                            : '${_visits.length} visit${_visits.length == 1 ? '' : 's'} total',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6A6A6A),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Stat Filter Chips ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _MetricChip(
                      label: 'Today',
                      value: _countToday().toString(),
                      icon: Icons.today_outlined,
                      isSelected: _activeFilter == _VisitsFilter.today,
                      onTap: () => setState(() {
                        _activeFilter = _activeFilter == _VisitsFilter.today
                            ? _VisitsFilter.all
                            : _VisitsFilter.today;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricChip(
                      label: 'Pending',
                      value: _countByStatus(VisitStatus.scheduled).toString(),
                      icon: Icons.pending_actions_outlined,
                      isSelected: _activeFilter == _VisitsFilter.pending,
                      onTap: () => setState(() {
                        _activeFilter = _activeFilter == _VisitsFilter.pending
                            ? _VisitsFilter.all
                            : _VisitsFilter.pending;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricChip(
                      label: 'Done',
                      value: _countByStatus(VisitStatus.completed).toString(),
                      icon: Icons.check_circle_outline,
                      isSelected: _activeFilter == _VisitsFilter.completed,
                      onTap: () => setState(() {
                        _activeFilter = _activeFilter == _VisitsFilter.completed
                            ? _VisitsFilter.all
                            : _VisitsFilter.completed;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Search Bar ────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: CrmColors.brandPrimary.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: CrmColors.foreground),
                  decoration: InputDecoration(
                    hintText: 'Search by client or location...',
                    hintStyle: TextStyle(
                        fontSize: 15, color: CrmColors.mutedForeground),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 18, right: 12),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: CrmColors.brandPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.search_rounded,
                            color: CrmColors.brandPrimary, size: 20),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchCtrl,
                      builder: (_, val, child) => val.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              onPressed: _searchCtrl.clear,
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 16, color: Colors.grey),
                              ),
                            ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Visit List ────────────────────────────────────────────
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: SpinKitFoldingCube(
                        color: Color(0xFF6C47FF), size: 36.0),
                  ),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Error loading visits: $_errorMessage',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: Colors.red),
                  ),
                )
              else if (_visits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.assignment_outlined,
                            size: 52, color: Color(0xFF6A6A6A)),
                        const SizedBox(height: 12),
                        Text('No visits found',
                            style: textTheme.titleMedium),
                      ],
                    ),
                  ),
                )
              else if (filteredVisits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 52, color: Color(0xFF6A6A6A)),
                        const SizedBox(height: 12),
                        Text('No visits match this filter.',
                            style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                )
              else
                for (var i = 0; i < filteredVisits.length; i++) ...[
                  VisitCardWidget(
                    visit: filteredVisits[i],
                    currentUserId: _currentUserId,
                    onTap: () => _showVisitActionMenu(filteredVisits[i]),
                    onLongPress: () => _showVisitActionMenu(filteredVisits[i]),
                  ),
                  if (i != filteredVisits.length - 1)
                    const SizedBox(height: 12),
                ],
            ],
          ),
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
        final isCompletedOrCancelled = visit.status == VisitStatus.completed ||
            visit.status == VisitStatus.cancelled;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompletedOrCancelled)
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
              if (!isCompletedOrCancelled)
                ListTile(
                  leading: const Icon(Icons.event_repeat_outlined),
                  title: const Text('Reschedule'),
                  onTap: () => Navigator.of(ctx).pop('reschedule'),
                ),
              if (!isCompletedOrCancelled)
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
    await _handleVisitAction(action, visit);
  }

  Future<void> _handleVisitAction(String action, Visit visit) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await _getClerkJwt();
      if (action == 'complete') {
        final payload = await _showCompleteVisitResultSheet();
        if (payload == null) return;
        final files = <http.MultipartFile>[];
        for (final filePath in payload.filePaths) {
          files.add(await http.MultipartFile.fromPath('files', filePath));
        }
        await _visitApiService.submitVisitResult(
          visit.id,
          payload.submission,
          authTokenOverride: token,
          files: files,
        );
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Visit result submitted')),
        );
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
      } else if (action == 'add_support') {
        await _showAddSupportMemberSheet(visit);
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
      await _loadVisits();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }
  }

  Future<void> _showAddSupportMemberSheet(Visit visit) async {
    final token = await _getClerkJwt();
    List<Map<String, dynamic>> availableMembers = [];
    bool isLoading = true;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            if (isLoading) {
              _visitApiService
                  .fetchSupportMembers(visit.id, authTokenOverride: token)
                  .then((members) {
                if (ctx.mounted) {
                  setModalState(() {
                    availableMembers = members;
                    isLoading = false;
                  });
                }
              }).catchError((e) {
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to load members: $e')),
                  );
                }
              });
              return const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (availableMembers.isEmpty) {
              return const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No available support members.')),
                ),
              );
            }

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Add Support Member',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableMembers.length,
                      itemBuilder: (ctx, i) {
                        final member = availableMembers[i];
                        return ListTile(
                          leading:
                              const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(member['fullName'] ?? 'Unknown'),
                          subtitle: Text(member['email'] ?? ''),
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            try {
                              await _visitApiService.addSupportMember(
                                visit.id,
                                member['id'],
                                authTokenOverride: token,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Support member added')),
                                );
                                _loadVisits(); // refresh
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  Future<_VisitResultPayload?> _showCompleteVisitResultSheet() async {
    final summaryCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final attachedFiles = <String>[];
    String? clientMood;
    String? clientPersonality;

    String? projectStatus;
    int step = 0;
    String? potentiality;
    String? projectType;
    String? budgetRange;
    String? timelineUrgency;
    String? stylePreference;

    final result = await showModalBottomSheet<_VisitResultPayload>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Complete Visit',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text('Step ${step + 1} of 3'),
                      const SizedBox(height: 12),
                      // ── Step 1: Summary ───────────────────────────────
                      if (step == 0) ...[
                        TextField(
                          controller: summaryCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Write visit outcome summary... *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: clientMood,
                          decoration: const InputDecoration(
                            labelText: 'Client Mood',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'HAPPY', child: Text('Happy')),
                            DropdownMenuItem(value: 'NEUTRAL', child: Text('Neutral')),
                            DropdownMenuItem(value: 'EXCITED', child: Text('Excited')),
                            DropdownMenuItem(value: 'CONCERNED', child: Text('Concerned')),
                            DropdownMenuItem(value: 'UNHAPPY', child: Text('Unhappy')),
                          ],
                          onChanged: (v) => setModalState(() => clientMood = v),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: projectStatus,
                          decoration: const InputDecoration(
                            labelText: 'Select project status',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'UNDER_CONSTRUCTION',
                              child: Text('Under Construction'),
                            ),
                            DropdownMenuItem(value: 'READY', child: Text('Ready')),
                          ],
                          onChanged: (v) => setModalState(() => projectStatus = v),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: noteCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Add note for the lead timeline...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      // ── Step 2: Lead Details ──────────────────────────
                      if (step == 1) ...[
                        DropdownButtonFormField<String>(
                          initialValue: potentiality,
                          decoration: const InputDecoration(
                            labelText: 'Potentiality',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'HOT', child: Text('Hot')),
                            DropdownMenuItem(value: 'WARM', child: Text('Warm')),
                            DropdownMenuItem(value: 'COLD', child: Text('Cold')),
                          ],
                          onChanged: (v) => setModalState(() => potentiality = v),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: projectType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'DUPLEX', child: Text('Duplex')),
                            DropdownMenuItem(value: 'APARTMENT', child: Text('Apartment')),
                            DropdownMenuItem(value: 'VILLA', child: Text('Villa')),
                            DropdownMenuItem(value: 'OFFICE', child: Text('Office')),
                            DropdownMenuItem(value: 'COMMERCIAL', child: Text('Commercial')),
                            DropdownMenuItem(value: 'RESIDENTIAL', child: Text('Residential')),
                          ],
                          onChanged: (v) => setModalState(() => projectType = v),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: clientPersonality,
                          decoration: const InputDecoration(
                            labelText: 'Client Personality',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'ANALYTICAL', child: Text('Analytical')),
                            DropdownMenuItem(value: 'DRIVER', child: Text('Driver')),
                            DropdownMenuItem(value: 'EXPRESSIVE', child: Text('Expressive')),
                            DropdownMenuItem(value: 'AMIABLE', child: Text('Amiable')),
                          ],
                          onChanged: (v) => setModalState(() => clientPersonality = v),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: budgetRange,
                          decoration: const InputDecoration(
                            labelText: 'Budget Range',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'UNDER_10L', child: Text('Under 10L')),
                            DropdownMenuItem(value: '10L_TO_20L', child: Text('10L - 20L')),
                            DropdownMenuItem(value: '20L_TO_35L', child: Text('20L - 35L')),
                            DropdownMenuItem(value: '35L_TO_50L', child: Text('35L - 50L')),
                            DropdownMenuItem(value: '50L_TO_75L', child: Text('50L - 75L')),
                            DropdownMenuItem(value: 'ABOVE_75L', child: Text('Above 75L')),
                          ],
                          onChanged: (v) => setModalState(() => budgetRange = v),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: timelineUrgency,
                          decoration: const InputDecoration(
                            labelText: 'Timeline / Urgency',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'IMMEDIATE', child: Text('Immediate')),
                            DropdownMenuItem(
                              value: 'THREE_TO_SIX_MONTHS',
                              child: Text('3-6 months'),
                            ),
                            DropdownMenuItem(
                              value: 'MORE_THAN_SIX_MONTHS',
                              child: Text('More than 6 months'),
                            ),
                          ],
                          onChanged: (v) => setModalState(() => timelineUrgency = v),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: stylePreference,
                          decoration: const InputDecoration(
                            labelText: 'Style Preference',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'MODERN', child: Text('Modern')),
                            DropdownMenuItem(
                              value: 'TRADITIONAL',
                              child: Text('Traditional'),
                            ),
                            DropdownMenuItem(value: 'MINIMALIST', child: Text('Minimalist')),
                            DropdownMenuItem(value: 'LUXURY', child: Text('Luxury')),
                          ],
                          onChanged: (v) => setModalState(() => stylePreference = v),
                        ),
                      ],
                      // ── Step 3: Attachments ───────────────────────────
                      if (step == 2) ...[
                        Text(
                          'Attachments & Photos',
                          style: Theme.of(ctx).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 10),
                        _AttachmentPicker(
                          attachedFiles: attachedFiles,
                          setModalState: setModalState,
                        ),
                        const SizedBox(height: 8),
                        _AttachedFileList(
                          attachedFiles: attachedFiles,
                          setModalState: setModalState,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                if (step > 0) {
                                  setModalState(() => step -= 1);
                                  return;
                                }
                                Navigator.of(ctx).pop();
                              },
                              child: Text(step > 0 ? 'Back' : 'Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                if (step == 0) {
                                  if (summaryCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Summary is required')),
                                    );
                                    return;
                                  }
                                  setModalState(() => step = 1);
                                  return;
                                }
                                if (step == 1) {
                                  setModalState(() => step = 2);
                                  return;
                                }
                                // step == 2 → submit
                                Navigator.of(ctx).pop(
                                  _VisitResultPayload(
                                    submission: VisitResultSubmission(
                                      summary: summaryCtrl.text.trim(),
                                      clientMood: clientMood,
                                      note: noteCtrl.text,
                                      projectStatus: projectStatus,
                                      resultType: 'LEAD',
                                      clientPotentiality: potentiality,
                                      projectType: projectType,
                                      clientPersonality: clientPersonality,
                                      budgetRange: budgetRange,
                                      timelineUrgency: timelineUrgency,
                                      stylePreference: stylePreference,
                                    ),
                                    filePaths: List<String>.from(attachedFiles),
                                  ),
                                );
                              },
                              child: Text(step < 2 ? 'Next' : 'Submit'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    summaryCtrl.dispose();
    noteCtrl.dispose();

    return result;
  }
}

class _VisitResultPayload {
  const _VisitResultPayload({
    required this.submission,
    required this.filePaths,
  });

  final VisitResultSubmission submission;
  final List<String> filePaths;
}

enum _VisitsFilter { today, pending, completed, all }


class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(label, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}


// ── Shared attachment helper widgets ────────────────────────────────────────

/// A row with [Attach Files] + [Take Photo] buttons.
/// Calls [setModalState] to trigger the bottom-sheet rebuild.
class _AttachmentPicker extends StatelessWidget {
  const _AttachmentPicker({
    required this.attachedFiles,
    required this.setModalState,
  });

  final List<String> attachedFiles;
  final StateSetter setModalState;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final picked = await FilePicker.platform.pickFiles(
                allowMultiple: true,
                type: FileType.any,
              );
              if (picked == null) return;
              setModalState(() {
                attachedFiles.addAll(picked.paths.whereType<String>());
              });
            },
            icon: const Icon(Icons.attach_file),
            label: const Text('Attach Files'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
            ),
            onPressed: () async {
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.camera);
              if (image == null) return;
              setModalState(() {
                attachedFiles.add(image.path);
              });
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
          ),
        ),
      ],
    );
  }
}

/// Shows the list of attached files with image thumbnails and remove buttons.
class _AttachedFileList extends StatelessWidget {
  const _AttachedFileList({
    required this.attachedFiles,
    required this.setModalState,
  });

  final List<String> attachedFiles;
  final StateSetter setModalState;

  @override
  Widget build(BuildContext context) {
    if (attachedFiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.attach_file, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text('No files attached yet.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: attachedFiles.map((f) {
        final lower = f.toLowerCase();
        final isImage = lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp');
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: CrmColors.brandPrimary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: CrmColors.brandPrimary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              if (isImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(f),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.photo_camera_rounded,
                      color: CrmColors.brandPrimary,
                      size: 30,
                    ),
                  ),
                )
              else
                const Icon(Icons.insert_drive_file,
                    color: CrmColors.brandPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  f.split('/').last,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                onPressed: () =>
                    setModalState(() => attachedFiles.remove(f)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
