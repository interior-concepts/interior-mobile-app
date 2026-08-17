import 'package:flutter/material.dart';
import '../../../data/meetings/meeting_api_service.dart';
import '../../../models/meeting_queue_lead.dart';

class CompleteMeetingSheet extends StatefulWidget {
  final MeetingQueueLead lead;
  final String token;
  final VoidCallback onSuccess;

  const CompleteMeetingSheet({
    super.key,
    required this.lead,
    required this.token,
    required this.onSuccess,
  });

  @override
  State<CompleteMeetingSheet> createState() => _CompleteMeetingSheetState();
}

class _CompleteMeetingSheetState extends State<CompleteMeetingSheet> {
  final _meetingApiService = MeetingApiService();
  
  bool _isLoading = false;
  bool _isFetchingMembers = true;
  final _noteController = TextEditingController();

  List<Map<String, dynamic>> _memberOptions = [];
  String? _selectedMemberId;

  // For Budget meetings
  String _clientApproval = 'NO_APPROVAL';

  bool get _isBudgetMeeting => 
      widget.lead.stage == 'BUDGET_PHASE' && widget.lead.subStatus == 'BUDGET_MEETING_SET';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isFetchingMembers = true);
    try {
      if (_isBudgetMeeting) {
        if (_clientApproval != 'NO_APPROVAL') {
          _memberOptions = await _meetingApiService.fetchDepartmentMembers(widget.token, '3D_VISUALIZER');
        } else {
          _memberOptions = [];
        }
      } else {
        // First Meeting
        _memberOptions = await _meetingApiService.fetchDepartmentMembers(widget.token, 'QUOTATION_TEAM');
      }
      
      // Reset selected member if it's no longer in the list
      if (_selectedMemberId != null && !_memberOptions.any((m) => m['id'] == _selectedMemberId)) {
        _selectedMemberId = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load team members: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingMembers = false);
      }
    }
  }

  void _onApprovalChanged(String? value) {
    if (value != null && value != _clientApproval) {
      setState(() {
        _clientApproval = value;
      });
      _loadMembers();
    }
  }

  Future<void> _submit() async {
    if (_isBudgetMeeting && _clientApproval != 'NO_APPROVAL' && _selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a 3D Visualizer')),
      );
      return;
    }
    
    if (!_isBudgetMeeting && _selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Quotation Member')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isBudgetMeeting) {
        await _meetingApiService.completeBudgetMeeting(
          widget.token,
          widget.lead.id,
          _noteController.text,
          _clientApproval,
          _selectedMemberId,
        );
      } else {
        await _meetingApiService.completeFirstMeeting(
          widget.token,
          widget.lead.id,
          _noteController.text,
          _selectedMemberId,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting completed successfully')),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isBudgetMeeting ? 'Complete Budget Meeting' : 'Complete First Meeting';
    final memberLabel = _isBudgetMeeting ? 'Assign 3D Visualizer' : 'Assign Quotation Member';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (_isBudgetMeeting) ...[
              DropdownButtonFormField<String>(
                initialValue: _clientApproval,
                decoration: const InputDecoration(
                  labelText: 'Client Approval Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.verified),
                ),
                items: const [
                  DropdownMenuItem(value: 'NO_APPROVAL', child: Text('No Approval Yet')),
                  DropdownMenuItem(value: 'DESIGN_AGREEMENT', child: Text('Design Agreement')),
                  DropdownMenuItem(value: 'FITOUT_AGREEMENT', child: Text('Fitout Agreement')),
                ],
                onChanged: _onApprovalChanged,
              ),
              const SizedBox(height: 16),
            ],

            if (!_isBudgetMeeting || _clientApproval != 'NO_APPROVAL') ...[
              _isFetchingMembers
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      initialValue: _selectedMemberId,
                      decoration: InputDecoration(
                        labelText: memberLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      items: _memberOptions.map((m) {
                        return DropdownMenuItem<String>(
                          value: m['id'],
                          child: Text(m['fullName'] ?? 'Unknown User'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMemberId = val);
                      },
                    ),
              const SizedBox(height: 16),
            ],

            // Note
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Meeting Notes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Complete Meeting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
