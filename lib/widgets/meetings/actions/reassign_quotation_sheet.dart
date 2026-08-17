import 'package:flutter/material.dart';
import '../../../data/meetings/meeting_api_service.dart';
import '../../../models/meeting_queue_lead.dart';

class ReassignQuotationSheet extends StatefulWidget {
  final MeetingQueueLead lead;
  final String token;
  final VoidCallback onSuccess;

  const ReassignQuotationSheet({
    super.key,
    required this.lead,
    required this.token,
    required this.onSuccess,
  });

  @override
  State<ReassignQuotationSheet> createState() => _ReassignQuotationSheetState();
}

class _ReassignQuotationSheetState extends State<ReassignQuotationSheet> {
  final _meetingApiService = MeetingApiService();
  
  bool _isLoading = false;
  bool _isFetchingMembers = true;

  List<Map<String, dynamic>> _memberOptions = [];
  String? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isFetchingMembers = true);
    try {
      _memberOptions = await _meetingApiService.fetchDepartmentMembers(widget.token, 'QUOTATION_TEAM');
      
      // Try to pre-select current quotation member if available
      if (widget.lead.subStatus != 'QUOTATION_APPROVED' && widget.lead.quotationAssignment != null) {
        final currentId = widget.lead.quotationAssignment!.user.id;
        if (_memberOptions.any((m) => m['id'] == currentId)) {
          _selectedMemberId = currentId;
        }
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

  Future<void> _submit() async {
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Quotation Member')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isNewQuotation = widget.lead.subStatus == 'QUOTATION_APPROVED';
      
      await _meetingApiService.reassignQuotation(
        widget.token,
        widget.lead.id,
        _selectedMemberId!,
        isNewQuotation,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation member reassigned successfully')),
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
  Widget build(BuildContext context) {
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
            const Text(
              'Reassign Quotation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            _isFetchingMembers
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    initialValue: _selectedMemberId,
                    decoration: const InputDecoration(
                      labelText: 'Select Quotation Member',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
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
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Reassign Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
