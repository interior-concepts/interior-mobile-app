import 'package:flutter/material.dart';
import '../../../data/meetings/meeting_api_service.dart';
import '../../../models/meeting_queue_lead.dart';

class SetMeetingSheet extends StatefulWidget {
  final MeetingQueueLead lead;
  final String token;
  final VoidCallback onSuccess;

  const SetMeetingSheet({
    super.key,
    required this.lead,
    required this.token,
    required this.onSuccess,
  });

  @override
  State<SetMeetingSheet> createState() => _SetMeetingSheetState();
}

class _SetMeetingSheetState extends State<SetMeetingSheet> {
  final _meetingApiService = MeetingApiService();
  
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _meetingMode = 'ONLINE';
  final _noteController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final meetingKind = widget.lead.queueCategory == 'budget' ? 'BUDGET' : 'FIRST';
      final startsAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await _meetingApiService.scheduleMeeting(
        widget.token,
        widget.lead.id,
        meetingKind,
        startsAt,
        _meetingMode,
        _noteController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting scheduled successfully')),
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
        setState(() {
          _isLoading = false;
        });
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
    final title = widget.lead.queueCategory == 'budget' ? 'Set Budget Meeting' : 'Set First Meeting';

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

            // Date Picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Meeting Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              ),
            ),
            const SizedBox(height: 16),

            // Time Picker
            InkWell(
              onTap: () => _selectTime(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Meeting Time',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                child: Text(_selectedTime.format(context)),
              ),
            ),
            const SizedBox(height: 16),

            // Mode Selector
            DropdownButtonFormField<String>(
              initialValue: _meetingMode,
              decoration: const InputDecoration(
                labelText: 'Meeting Mode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.videocam),
              ),
              items: const [
                DropdownMenuItem(value: 'ONLINE', child: Text('Online')),
                DropdownMenuItem(value: 'OFFLINE', child: Text('Offline / In Person')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _meetingMode = val);
              },
            ),
            const SizedBox(height: 16),

            // Note
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
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
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Schedule Meeting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
