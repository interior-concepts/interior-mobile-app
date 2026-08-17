import 'package:flutter/material.dart';
import '../../../data/meetings/meeting_api_service.dart';
import '../../../models/meeting_queue_lead.dart';

class ChangeProjectSizeSheet extends StatefulWidget {
  final MeetingQueueLead lead;
  final String token;
  final VoidCallback onSuccess;

  const ChangeProjectSizeSheet({
    super.key,
    required this.lead,
    required this.token,
    required this.onSuccess,
  });

  @override
  State<ChangeProjectSizeSheet> createState() => _ChangeProjectSizeSheetState();
}

class _ChangeProjectSizeSheetState extends State<ChangeProjectSizeSheet> {
  final _meetingApiService = MeetingApiService();
  final _sqftController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.lead.latestCompletedVisit?.projectSqft != null) {
      _sqftController.text = widget.lead.latestCompletedVisit!.projectSqft.toString();
    }
  }

  @override
  void dispose() {
    _sqftController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final sqftText = _sqftController.text.trim();
    if (sqftText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the project size')),
      );
      return;
    }

    final sqft = double.tryParse(sqftText);
    if (sqft == null || sqft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number greater than 0')),
      );
      return;
    }

    final visitId = widget.lead.latestCompletedVisit?.id;
    if (visitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot update: No completed visit found')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _meetingApiService.updateProjectSize(
        widget.token,
        visitId,
        sqft,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project size updated successfully')),
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
              'Change Project Size (Sqft)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _sqftController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Project Size (Sqft)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.square_foot),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Update Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
