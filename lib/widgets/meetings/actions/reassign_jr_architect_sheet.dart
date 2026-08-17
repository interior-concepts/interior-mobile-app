import 'package:flutter/material.dart';
import '../../../data/meetings/meeting_api_service.dart';
import '../../../models/meeting_queue_lead.dart';

class ReassignJrArchitectSheet extends StatefulWidget {
  final MeetingQueueLead lead;
  final String token;
  final VoidCallback onSuccess;

  const ReassignJrArchitectSheet({
    super.key,
    required this.lead,
    required this.token,
    required this.onSuccess,
  });

  @override
  State<ReassignJrArchitectSheet> createState() => _ReassignJrArchitectSheetState();
}

class _ReassignJrArchitectSheetState extends State<ReassignJrArchitectSheet> {
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
      _memberOptions = await _meetingApiService.fetchDepartmentMembers(widget.token, 'JR_ARCHITECT');
      
      // Try to pre-select current JR Architect if available
      if (widget.lead.jrArchitectAssignment != null) {
        final currentId = widget.lead.jrArchitectAssignment!.user.id;
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
        const SnackBar(content: Text('Please select a JR Architect')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _meetingApiService.reassignJrArchitect(
        widget.token,
        widget.lead.id,
        _selectedMemberId!,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JR Architect reassigned successfully')),
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
              'Reassign JR Architect',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            _isFetchingMembers
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    initialValue: _selectedMemberId,
                    decoration: const InputDecoration(
                      labelText: 'Select JR Architect',
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
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Reassign Architect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
