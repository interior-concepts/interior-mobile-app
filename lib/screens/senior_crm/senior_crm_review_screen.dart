import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../widgets/mobile_app_header.dart';
import '../../theme/crm_colors.dart';
import '../../models/review_submission.dart';

class SeniorCrmReviewScreen extends StatefulWidget {
  const SeniorCrmReviewScreen({super.key});

  @override
  State<SeniorCrmReviewScreen> createState() => _SeniorCrmReviewScreenState();
}

class _SeniorCrmReviewScreenState extends State<SeniorCrmReviewScreen> {
  bool _isLoading = true;
  List<ReviewSubmission> _submissions = [];
  String _activeFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // The height of the collapsible section (search + stats)
  static const double _collapseHeight = 184.0;
  // How many pixels of scroll it takes to fully hide the bar
  static const double _collapseThreshold = 80.0;

  double get _collapseProgress {
    if (!_scrollController.hasClients) return 0.0;
    return (_scrollController.offset / _collapseThreshold).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Trigger rebuild on every scroll tick so the animation is driven by position
    _scrollController.addListener(() => setState(() {}));
  }

  Future<String?> _getToken() async {
    try {
      final authState = ClerkAuth.of(context, listen: false);
      final sessionToken = await authState.sessionToken();
      return sessionToken.jwt;
    } catch (e) {
      debugPrint('Error getting Clerk token: $e');
      return null;
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('https://www.aestheticinteriorbd.com/api/cad-work/review-center?limit=50');
      final token = await _getToken();
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final dataList = decoded['data'] as List;
          setState(() {
            _submissions = dataList.map((item) => ReviewSubmission.fromJson(item)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching review submissions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitDecision(String submissionId, String decision, String? summary) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      final url = Uri.parse('https://www.aestheticinteriorbd.com/api/cad-work/review-center/$submissionId/decision');
      final token = await _getToken();
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'decision': decision,
          if (summary != null) 'summary': summary,
        }),
      );
      
      if (mounted) Navigator.of(context).pop(); // dismiss loading dialog
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? 'Decision submitted')));
          _fetchData(); // refresh list
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['error'] ?? 'Failed to submit decision')));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit decision (HTTP ${response.statusCode})')));
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // dismiss loading dialog if error
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showSummaryDialog(ReviewSubmission submission, String decision, String title, String hint) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: decision == 'DROP' ? Colors.red.shade600 : Colors.black87, foregroundColor: Colors.white),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Summary is required')));
                return;
              }
              Navigator.of(ctx).pop();
              _submitDecision(submission.id, decision, text);
            },
            child: const Text('Submit'),
          ),
        ],
      )
    );
  }

  List<ReviewSubmission> get _filteredSubmissions {
    List<ReviewSubmission> filtered = _submissions;

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((s) => 
        s.leadName.toLowerCase().contains(query) ||
        s.leadLocation.toLowerCase().contains(query) ||
        s.submittedBy.toLowerCase().contains(query)
      ).toList();
    }

    // Apply active filter
    if (_activeFilter == 'ALL') return filtered;
    if (_activeFilter == 'CAD') return filtered.where((s) => s.phaseType == 'cad').toList();
    if (_activeFilter == 'QUOTATION') return filtered.where((s) => s.phaseType == 'quotation').toList();
    if (_activeFilter == 'VISUALIZATION') return filtered.where((s) => s.phaseType == 'visualizer').toList();
    return filtered;
  }

  Widget _buildFilterStat(String key, String label, int count, IconData icon, Color baseColor) {
    final isActive = _activeFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = key;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 140,
        decoration: BoxDecoration(
          color: isActive ? baseColor.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? baseColor.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            if (!isActive)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.grey.shade600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: baseColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionBottomSheet(BuildContext context, ReviewSubmission submission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Client info block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: const Icon(Icons.person_outline_rounded, size: 16, color: Colors.black54),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CLIENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Text(
                                submission.leadName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // Client address
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ADDRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Text(
                                submission.leadLocation,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Approve
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _submitDecision(submission.id, 'APPROVE', null);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Approve', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),

              // Correction / Cancel
              OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showSummaryDialog(submission, 'CORRECTION', 'Send for Correction', 'Enter correction summary/details...');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Correction / Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),

              // Drop Project
              OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showSummaryDialog(submission, 'DROP', 'Drop Project', 'Enter reason for dropping project...');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.red.shade200, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Text('Drop Project', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red.shade600)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmissionCard(ReviewSubmission submission) {
    return ReviewSubmissionCard(
      submission: submission,
      onLongPress: () => _showActionBottomSheet(context, submission),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: MobileAppHeader(
        title: 'Review Center',
        onRefresh: _fetchData,
      ),
      body: Column(
              children: [
                // Breadcrumbs
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.home_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('Home', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
                      const Text('Review Center', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                // Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Center',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage and review all incoming submissions.',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),

                // Collapsible: Searchbar + Stats — scroll-driven
                ClipRect(
                  child: SizedBox(
                    height: (_collapseHeight * (1.0 - _collapseProgress)).clamp(0.0, _collapseHeight),
                    child: Opacity(
                      opacity: (1.0 - _collapseProgress * 1.5).clamp(0.0, 1.0),
                      child: Column(
                        children: [
                          // Premium Search Bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setState(() => _searchQuery = value);
                                },
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Search by lead name, location...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.deepPurple.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Stats Filter Section
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 0, 0, 12),
                            child: Skeletonizer(
                              enabled: _isLoading,
                              child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildFilterStat('ALL', 'Total', _submissions.length, Icons.list_alt, Colors.blueGrey),
                                  _buildFilterStat('CAD', 'Cad', _submissions.where((s) => s.phaseType == 'cad').length, Icons.draw, Colors.deepPurple),
                                  _buildFilterStat('QUOTATION', 'Quotation', _submissions.where((s) => s.phaseType == 'quotation').length, Icons.request_quote, Colors.orange),
                                  _buildFilterStat('VISUALIZATION', '3D Visuals', _submissions.where((s) => s.phaseType == 'visualizer').length, Icons.image, Colors.teal),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      ),
                    ),
                  ),
                ),

                // Submissions List
                Expanded(
                  child: (_isLoading && _filteredSubmissions.isEmpty)
                      ? Skeletonizer(
                          enabled: true,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: 3,
                            itemBuilder: (context, index) {
                              return ReviewSubmissionCard(
                                submission: ReviewSubmission(
                                  id: '',
                                  leadName: 'Loading Lead Name Placeholder',
                                  leadPhone: '01712345678',
                                  leadLocation: 'Loading Address Placeholder',
                                  stage: 'CAD_PHASE',
                                  subStatus: 'CAD_COMPLETED',
                                  submittedBy: 'Loading User',
                                  submittedAt: DateTime.now(),
                                  fileCount: 0,
                                  phaseType: 'cad',
                                ),
                              );
                            },
                          ),
                        )
                      : _filteredSubmissions.isEmpty
                          ? const Center(
                              child: Text(
                                'No submissions found.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _filteredSubmissions.length,
                              itemBuilder: (context, index) {
                                return _buildSubmissionCard(_filteredSubmissions[index]);
                              },
                            ),
                ),
              ],
            ),
    );
  }
}

class ReviewSubmissionCard extends StatefulWidget {
  final ReviewSubmission submission;
  final VoidCallback? onLongPress;

  const ReviewSubmissionCard({
    super.key,
    required this.submission,
    this.onLongPress,
  });

  @override
  State<ReviewSubmissionCard> createState() => _ReviewSubmissionCardState();
}

class _ReviewSubmissionCardState extends State<ReviewSubmissionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    
    if (widget.submission.phaseType == 'quotation') {
      baseColor = Colors.orange;
    } else if (widget.submission.phaseType == 'visualizer') {
      baseColor = Colors.teal;
    } else {
      baseColor = Colors.deepPurple;
    }

    final intensity = widget.submission.isPendingReview ? 1.0 : 0.6;
    final fgColor = baseColor.withValues(alpha: 0.9 * intensity);
    final lightBg = baseColor.withValues(alpha: 0.08 * intensity);
    final borderColor = baseColor.withValues(alpha: 0.2 * intensity);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: widget.submission.isPendingReview ? 1.5 : 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            widget.submission.isPendingReview ? baseColor.withValues(alpha: 0.06) : Colors.white,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: widget.submission.isPendingReview ? 0.12 : 0.04),
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
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(24),
          splashColor: baseColor.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.submission.leadName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: lightBg,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            widget.submission.phaseType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: fgColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
                
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _isExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.shade200, height: 1),
                            const SizedBox(height: 16),
                            
                            // Location Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))
                                    ],
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                                  ),
                                  child: Icon(Icons.location_on_outlined, size: 16, color: fgColor),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      widget.submission.leadLocation,
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Assigned By Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))
                                    ],
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                                  ),
                                  child: Icon(Icons.person_outline, size: 16, color: fgColor),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Submitted by ${widget.submission.submittedBy}',
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (widget.submission.note != null && widget.submission.note!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.notes_rounded, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 6),
                                        Text(
                                          'SUBMISSION NOTE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.submission.note!,
                                      style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
