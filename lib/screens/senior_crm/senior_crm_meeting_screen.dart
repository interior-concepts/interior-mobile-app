import 'dart:async';
import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../widgets/mobile_app_header.dart';
import '../../theme/crm_colors.dart';
import '../../models/meeting_queue_lead.dart';
import '../../data/meetings/meeting_api_service.dart';
import '../../widgets/meetings/meeting_queue_card.dart';
import '../../widgets/meetings/meeting_stat_cards.dart';
import '../../widgets/meetings/actions/set_meeting_sheet.dart';
import '../../widgets/meetings/actions/complete_meeting_sheet.dart';
import '../../widgets/meetings/actions/reassign_quotation_sheet.dart';
import '../../widgets/meetings/actions/change_project_size_sheet.dart';
import '../../widgets/meetings/actions/drop_project_sheet.dart';
import '../../widgets/meetings/actions/reassign_jr_architect_sheet.dart';

class SeniorCrmMeetingScreen extends StatefulWidget {
  const SeniorCrmMeetingScreen({super.key});

  @override
  State<SeniorCrmMeetingScreen> createState() => _SeniorCrmMeetingScreenState();
}

class _SeniorCrmMeetingScreenState extends State<SeniorCrmMeetingScreen> {
  final MeetingApiService _apiService = MeetingApiService();
  
  bool _isLoading = true;
  List<MeetingQueueLead> _leads = [];
  String _activeFilter = 'ALL';
  String _searchQuery = '';
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  static const double _collapseHeight = 301.0;
  static const double _collapseThreshold = 182.0;

  double get _collapseProgress {
    if (!_scrollController.hasClients) return 0.0;
    return (_scrollController.offset / _collapseThreshold).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final authState = ClerkAuth.of(context, listen: false);
      final sessionToken = await authState.sessionToken();
      
      if (sessionToken.jwt.isEmpty) {
        throw Exception('No token available');
      }

      final meetingLeads = await _apiService.fetchMeetingQueue(
        sessionToken.jwt, 
        search: _searchQuery,
        queueType: 'meeting',
      );
      
      final budgetLeads = await _apiService.fetchMeetingQueue(
        sessionToken.jwt, 
        search: _searchQuery,
        queueType: 'budget',
      );

      final designLeads = await _apiService.fetchMeetingQueue(
        sessionToken.jwt, 
        search: _searchQuery,
        queueType: 'design',
      );

      if (mounted) {
        setState(() {
          final combined = [...meetingLeads, ...budgetLeads, ...designLeads];
          combined.sort((a, b) {
            final dateA = DateTime.tryParse(a.updatedAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
            final dateB = DateTime.tryParse(b.updatedAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
            return dateB.compareTo(dateA); // Descending
          });
          _leads = combined;
        });
      }
    } catch (e) {
      debugPrint('Error fetching meeting queue: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _searchQuery = query);
        _fetchData();
      }
    });
  }

  Future<void> _showSetMeetingSheet(MeetingQueueLead lead) async {
    final authState = ClerkAuth.of(context, listen: false);
    final sessionToken = await authState.sessionToken();
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SetMeetingSheet(
        lead: lead,
        token: sessionToken.jwt,
        onSuccess: _fetchData,
      ),
    );
  }

  Future<void> _showCompleteMeetingSheet(MeetingQueueLead lead) async {
    final authState = ClerkAuth.of(context, listen: false);
    final sessionToken = await authState.sessionToken();
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => CompleteMeetingSheet(
        lead: lead,
        token: sessionToken.jwt,
        onSuccess: _fetchData,
      ),
    );
  }

  Future<void> _showReassignQuotationSheet(MeetingQueueLead lead) async {
    final authState = ClerkAuth.of(context, listen: false);
    final sessionToken = await authState.sessionToken();
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ReassignQuotationSheet(
        lead: lead,
        token: sessionToken.jwt,
        onSuccess: _fetchData,
      ),
    );
  }

  Future<void> _showChangeProjectSizeSheet(MeetingQueueLead lead) async {
    final authState = ClerkAuth.of(context, listen: false);
    final sessionToken = await authState.sessionToken();
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeProjectSizeSheet(
        lead: lead,
        token: sessionToken.jwt,
        onSuccess: _fetchData,
      ),
    );
  }

  Future<void> _showDropProjectSheet(MeetingQueueLead lead) async {
    final authState = ClerkAuth.of(context, listen: false);
    final sessionToken = await authState.sessionToken();
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DropProjectSheet(
        lead: lead,
        token: sessionToken.jwt,
        onSuccess: _fetchData,
      ),
    );
  }

  Future<void> _showReassignJrArchitectSheet(MeetingQueueLead lead) async {
    final authState = ClerkAuth.of(context, listen: false);
    final sessionToken = await authState.sessionToken();
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ReassignJrArchitectSheet(
        lead: lead,
        token: sessionToken.jwt,
        onSuccess: _fetchData,
      ),
    );
  }

  List<Map<String, dynamic>> get _currentFilters {
    return [
      {'id': 'ALL', 'label': 'Total Leads', 'icon': Icons.list_alt},
      {'id': 'meeting', 'label': 'Consulting', 'icon': Icons.event_available},
      {'id': 'budget', 'label': 'Budget', 'icon': Icons.request_quote},
      {'id': 'design', 'label': 'Design', 'icon': Icons.brush},
    ];
  }

  List<MeetingQueueLead> get _filteredLeads {
    if (_activeFilter == 'ALL') return _leads;
    return _leads.where((l) => l.queueCategory == _activeFilter).toList();
  }

  Map<String, int> get _statCounts {
    final counts = <String, int>{'ALL': _leads.length};
    for (var filter in _currentFilters) {
      if (filter['id'] != 'ALL') {
        counts[filter['id'] as String] = _leads.where((l) => l.queueCategory == filter['id']).length;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLeads;
    final displayList = _isLoading && filtered.isEmpty
        ? List.generate(
            3,
            (_) => MeetingQueueLead(
              id: '',
              name: 'Loading Lead Name',
              phone: '01712345678',
              stage: 'LOADING',
              updatedAt: '',
              canSetMeeting: false,
              canSubmitMeetingData: false,
            ),
          )
        : filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: MobileAppHeader(
        title: 'Meeting Queue',
        onRefresh: _fetchData,
      ),
      body: Stack(
        children: [
          // Main List
          RefreshIndicator(
            onRefresh: _fetchData,
            color: CrmColors.brandPrimary,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: _collapseHeight + 16,
                bottom: 100, // nav bar space
                left: 20,
                right: 20,
              ),
              itemCount: displayList.isEmpty ? 1 : displayList.length,
              itemBuilder: (context, index) {
                if (!_isLoading && displayList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(
                      child: Text(
                        'No leads found matching your criteria.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                
                final lead = displayList[index];
                return Skeletonizer(
                  enabled: _isLoading,
                  child: MeetingQueueCard(
                    lead: lead,
                    queueCategory: lead.queueCategory,
                    onSetMeeting: () => _showSetMeetingSheet(lead),
                    onCompleteMeeting: () => _showCompleteMeetingSheet(lead),
                    onReassignQuotation: () => _showReassignQuotationSheet(lead),
                    onChangeProjectSize: () => _showChangeProjectSizeSheet(lead),
                    onDropProject: () => _showDropProjectSheet(lead),
                    onReassignJrArchitect: () => _showReassignJrArchitectSheet(lead),
                  ),
                );
              },
            ),
          ),
          
          // Collapsible Header (Search & Stats)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Transform.translate(
              offset: Offset(0, -(_collapseHeight - 100) * _collapseProgress),
              child: Container(
                height: _collapseHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8FC),
                  boxShadow: [
                    if (_collapseProgress > 0)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05 * _collapseProgress),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Breadcrumbs & Screen Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('CRM', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                              Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
                              Text('SR CRM', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                              Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
                              const Text('Meeting Queue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Meeting Queue',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'CAD and Quotation approved leads for scheduling and follow-up.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search leads...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Stat Cards
                    Expanded(
                      child: Skeletonizer(
                        enabled: _isLoading,
                        child: MeetingStatCards(
                          activeFilter: _activeFilter,
                          filters: _currentFilters,
                          counts: _statCounts,
                          onFilterChanged: (filterId) {
                            setState(() => _activeFilter = filterId);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
