import 'package:flutter/material.dart';
import '../../models/meeting_queue_lead.dart';

class MeetingQueueCard extends StatefulWidget {
  final MeetingQueueLead lead;
  final VoidCallback onSetMeeting;
  final VoidCallback onCompleteMeeting;
  final VoidCallback onReassignQuotation;
  final VoidCallback onChangeProjectSize;
  final VoidCallback onDropProject;
  final VoidCallback onReassignJrArchitect;
  final String? queueCategory;

  const MeetingQueueCard({
    super.key,
    required this.lead,
    required this.onSetMeeting,
    required this.onCompleteMeeting,
    required this.onReassignQuotation,
    required this.onChangeProjectSize,
    required this.onDropProject,
    required this.onReassignJrArchitect,
    this.queueCategory,
  });

  @override
  State<MeetingQueueCard> createState() => _MeetingQueueCardState();
}

class _MeetingQueueCardState extends State<MeetingQueueCard> {
  bool _isExpanded = false;

  String _formatLabel(String? value) {
    if (value == null) return 'N/A';
    if (value == 'DISCOVERY') return 'Consulting Phase';
    if (value == 'PROPOSAL_SENT') return 'Quotation Sent';
    return value
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  Color _getSubStatusColor(String? subStatus) {
    switch (subStatus) {
      case 'CAD_ASSIGNED':
        return Colors.lightBlue;
      case 'CAD_WORKING':
        return Colors.amber;
      case 'CAD_COMPLETED':
        return Colors.deepPurpleAccent;
      case 'CAD_APPROVED':
        return Colors.green;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color subStatusColor;
    if (widget.queueCategory == 'budget') {
      subStatusColor = Colors.orange.shade700;
    } else if (widget.queueCategory == 'design') {
      subStatusColor = Colors.teal.shade700;
    } else {
      subStatusColor = _getSubStatusColor(widget.lead.subStatus);
    }
    
    final borderColor = subStatusColor.withValues(alpha: 0.3);
    final lightBg = subStatusColor.withValues(alpha: 0.08);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name and Stage/SubStatus
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                onLongPress: () {
                  _showActionBottomSheet(context);
                },
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lead.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.lead.phone != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.lead.phone!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatLabel(widget.lead.stage),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: lightBg,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            _formatLabel(widget.lead.subStatus),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: subStatusColor,
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

                          // Info grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoRow(Icons.calendar_month, 'Visit', _formatDate(widget.lead.latestCompletedVisit?.scheduledAt)),
                              ),
                              Expanded(
                                child: _buildInfoRow(Icons.location_on, 'Location', widget.lead.location ?? 'N/A'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoRow(Icons.person, 'JR Arch', widget.lead.jrArchitectAssignment?.user.fullName ?? 'N/A'),
                              ),
                              Expanded(
                                child: _buildInfoRow(Icons.people, 'SR CRM / Visit', _getVisitTeamName()),
                              ),
                            ],
                          ),

                          if (widget.lead.latestFirstMeeting != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.event,
                              'Meeting',
                              _formatDateTime(widget.lead.latestFirstMeeting!.startsAt),
                              isHighlighted: true,
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlighted = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isHighlighted ? Colors.blueAccent : Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: isHighlighted ? Colors.blueAccent.shade700 : Colors.black87,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'No Visit';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return 'Invalid Date';
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      
      String dateStr;
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        dateStr = 'Today';
      } else if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
        dateStr = 'Tomorrow';
      } else {
        dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }

      final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      
      return '$dateStr at $hour:$minute $period';
    } catch (e) {
      return isoString;
    }
  }

  void _showActionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Actions for ${widget.lead.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.lead.canSetMeeting)
                  ListTile(
                    leading: const Icon(Icons.event, color: Colors.blueAccent),
                    title: Text(widget.queueCategory == 'budget' ? 'Set Budget Meeting' : 'Set Meeting'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSetMeeting();
                    },
                  ),
                if (widget.lead.canSubmitMeetingData)
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(widget.queueCategory == 'budget' ? 'Complete Budget Meeting' : 'Complete Meeting'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onCompleteMeeting();
                    },
                  ),
                if (widget.lead.canReassignQuotation == true)
                  ListTile(
                    leading: const Icon(Icons.assignment_ind, color: Colors.orange),
                    title: const Text('Reassign Quotation'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onReassignQuotation();
                    },
                  ),
                if (widget.lead.latestCompletedVisit != null)
                  ListTile(
                    leading: const Icon(Icons.square_foot, color: Colors.blueGrey),
                    title: Text(widget.lead.latestCompletedVisit?.projectSqft != null ? 'Change Project Size' : 'Add Project Size'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onChangeProjectSize();
                    },
                  ),
                if (widget.lead.canReassignJrArchitect == true)
                  ListTile(
                    leading: const Icon(Icons.engineering, color: Colors.indigo),
                    title: const Text('Reassign JR Architect'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onReassignJrArchitect();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Drop Project', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDropProject();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getVisitTeamName() {
    final srName = widget.lead.srCrmAssignment?.user.fullName ?? 'Unassigned';
    final visit = widget.lead.latestCompletedVisit;
    if (visit == null) return srName;
    
    final names = <String>[];
    if (visit.assignedVisitLead != null) {
      names.add(visit.assignedVisitLead!.fullName);
    }
    for (var member in visit.supportMembers) {
      names.add(member.fullName);
    }
    
    if (names.isEmpty) return srName;
    return '$srName | ${names.join(' + ')}';
  }
}
