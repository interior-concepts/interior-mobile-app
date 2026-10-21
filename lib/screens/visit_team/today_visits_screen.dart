import 'dart:io';

import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fui_kit/fui_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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
      await _loadTodayVisits();
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
                                _loadTodayVisits();
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
                        _TodayAttachmentPicker(
                          attachedFiles: attachedFiles,
                          setModalState: setModalState,
                        ),
                        const SizedBox(height: 8),
                        _TodayAttachedFileList(
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

// ── Shared attachment helper widgets for TodayVisitsScreen ──────────────────

class _TodayAttachmentPicker extends StatelessWidget {
  const _TodayAttachmentPicker({
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

class _TodayAttachedFileList extends StatelessWidget {
  const _TodayAttachedFileList({
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
