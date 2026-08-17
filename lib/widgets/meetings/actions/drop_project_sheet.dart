import 'package:flutter/material.dart';
import '../../../data/meetings/meeting_api_service.dart';
import '../../../models/meeting_queue_lead.dart';

class DropProjectSheet extends StatefulWidget {
  final MeetingQueueLead lead;
  final String token;
  final VoidCallback onSuccess;

  const DropProjectSheet({
    super.key,
    required this.lead,
    required this.token,
    required this.onSuccess,
  });

  @override
  State<DropProjectSheet> createState() => _DropProjectSheetState();
}

class _DropProjectSheetState extends State<DropProjectSheet> {
  final _meetingApiService = MeetingApiService();
  bool _isLoading = false;
  String _selectedReason = 'PROJECT_DROPPED';

  final List<Map<String, String>> _dropReasons = [
    {'value': 'PROJECT_DROPPED', 'label': 'Project Dropped'},
    {'value': 'REJECTED_OFFER', 'label': 'Rejected Offer'},
    {'value': 'SMALL_BUDGET', 'label': 'Small Budget'},
    {'value': 'INVALID', 'label': 'Invalid Lead'},
    {'value': 'NOT_INTERESTED', 'label': 'Not Interested'},
    {'value': 'LOST', 'label': 'Lost to Competitor'},
    {'value': 'DEAD_LEAD', 'label': 'Dead Lead'},
  ];

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      await _meetingApiService.dropProject(
        widget.token,
        widget.lead.id,
        _selectedReason,
        widget.lead.queueCategory ?? 'unknown',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project dropped successfully')),
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
              'Drop Project',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to drop this project? This will move the lead to the CLOSED stage.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Reason for Dropping',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cancel_outlined, color: Colors.red),
              ),
              items: _dropReasons.map((r) {
                return DropdownMenuItem<String>(
                  value: r['value'],
                  child: Text(r['label']!),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedReason = val);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Drop', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
