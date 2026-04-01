import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/team_service.dart';

const scheduleAppColor = Color.fromARGB(255, 1, 4, 104);

class EventItem {
  final String id;
  final String title;
  final String description;
  final DateTime eventDateTime;
  final String location;
  final String status;
  final String teamId;

  EventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDateTime,
    required this.location,
    required this.status,
    required this.teamId,
  });

  factory EventItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final eventDateTimestamp = data?['eventDateTime'] as Timestamp?;

    return EventItem(
      id: doc.id,
      title: data?['title'] ?? '',
      description: data?['description'] ?? '',
      eventDateTime: eventDateTimestamp?.toDate() ?? DateTime.now(),
      location: data?['location'] ?? '',
      status: data?['status'] ?? 'Pending',
      teamId: data?['teamId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'eventDateTime': eventDateTime,
      'location': location,
      'status': status,
      'teamId': teamId,
      'createdAt': DateTime.now(),
    };
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TeamService _teamService = TeamService();

  String? _teamId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamId();
  }

  Future<void> _loadTeamId() async {
    final teamId = await _teamService.getCurrentTeamId();
    if (mounted) {
      setState(() {
        _teamId = teamId;
        _isLoading = false;
      });
    }
  }

  Stream<List<EventItem>> _eventsStream() {
    if (_teamId == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('events')
        .where('teamId', isEqualTo: _teamId)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => EventItem.fromFirestore(doc))
              .toList();
          events.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
          return events;
        });
  }

  Future<void> _createEvent() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final save = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          String formatTime(TimeOfDay? time) {
            if (time == null) return 'Select time';
            final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
            final period = time.period == DayPeriod.am ? 'AM' : 'PM';
            return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
          }

          return AlertDialog(
            title: const Text('Create Event'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Builder(builder: (context) {
                          final date = selectedDate;
                          if (date == null) {
                            return const Text('Pick date');
                          }
                          return Text('${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}');
                        }),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => selectedDate = picked);
                        },
                        child: const Text('Date'),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(formatTime(selectedTime))),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) setState(() => selectedTime = picked);
                        },
                        child: const Text('Time'),
                      )
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty ||
                      locationController.text.trim().isEmpty ||
                      selectedDate == null ||
                      selectedTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please complete required fields'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );

    if (save != true || _teamId == null) return;

    final eventDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final eventRef = await FirebaseFirestore.instance.collection('events').add({
      'teamId': _teamId,
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'location': locationController.text.trim(),
      'eventDateTime': eventDateTime,
      'status': 'Pending',
      'createdAt': DateTime.now(),
      'createdBy': FirebaseFirestore.instance.app.name,
    });

    final membersSnapshot = await FirebaseFirestore.instance
        .collection('members')
        .where('teamId', isEqualTo: _teamId)
        .get();

    for (final memberDoc in membersSnapshot.docs) {
      await FirebaseFirestore.instance.collection('invitations').add({
        'eventId': eventRef.id,
        'teamId': _teamId,
        'memberId': memberDoc.id,
        'memberEmail': (memberDoc.data()['email'] ?? '').toString(),
        'status': 'Sent',
        'sentAt': DateTime.now(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created and invitations sent')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teamId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You are not in a team yet.'),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: scheduleAppColor),
              onPressed: () {},
              child: const Text('Join or create a team first'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Schedule',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.mail_outline),
                label: const Text('Invitations'),
                style: ElevatedButton.styleFrom(backgroundColor: scheduleAppColor),
                onPressed: () {
                  final userEmail = FirebaseAuth.instance.currentUser?.email;
                  if (userEmail == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Login required for invitations')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InvitationsScreen(email: userEmail),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create Event'),
                style: ElevatedButton.styleFrom(backgroundColor: scheduleAppColor),
                onPressed: _createEvent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<EventItem>>(
            stream: _eventsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data ?? [];
              final confirmed = events.where((e) => e.status == 'Confirmed').toList();
              final pending = events.where((e) => e.status != 'Confirmed').toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Confirmed',
                          count: confirmed.length,
                          color: Colors.green,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Pending',
                          count: pending.length,
                          color: Colors.orange,
                          icon: Icons.hourglass_empty_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('CONFIRMED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.black54)),
                  const SizedBox(height: 10),
                  ...confirmed.map((event) => _EventCard(event: event)).toList(),
                  const SizedBox(height: 24),
                  const Text('PENDING RSVP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.black54)),
                  const SizedBox(height: 10),
                  ...pending.map((event) => _EventCard(event: event)).toList(),
                  const SizedBox(height: 20),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class InvitationsScreen extends StatefulWidget {
  final String email;

  const InvitationsScreen({required this.email});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  Stream<QuerySnapshot> _invitationsStream() {
    return FirebaseFirestore.instance
        .collection('invitations')
        .where('memberEmail', isEqualTo: widget.email.toLowerCase())
        .snapshots();
  }

  Future<void> _setInvitationStatus(DocumentSnapshot invitationDoc, String status) async {
    try {
      await FirebaseFirestore.instance.collection('invitations').doc(invitationDoc.id).update({
            'status': status,
            'respondedAt': DateTime.now(),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('RSVP set to $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to set RSVP: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Invitations'),
        backgroundColor: scheduleAppColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _invitationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final invitations = snapshot.data?.docs ?? [];
          if (invitations.isEmpty) {
            return const Center(child: Text('No invitations found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              final data = invitation.data() as Map<String, dynamic>;
              final status = data['status']?.toString() ?? 'Sent';
              final eventId = data['eventId']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('Event $eventId', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  subtitle: Text('Status: $status', style: const TextStyle(color: Colors.black)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _setInvitationStatus(invitation, 'Accepted'),
                        child: const Text('Accept'),
                      ),
                      TextButton(
                        onPressed: () => _setInvitationStatus(invitation, 'Declined'),
                        child: const Text('Decline'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EventCard extends StatefulWidget {
  final EventItem event;

  const _EventCard({required this.event});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _isAdmin = false;
  bool _isLoading = true;
  String? _invitationStatus;
  String? _invitationId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _invitationSubscription;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _invitationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadContext() async {
    final role = await TeamService().getCurrentUserRole();
    final userEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase();

    if (userEmail != null) {
      _invitationSubscription = FirebaseFirestore.instance
          .collection('invitations')
          .where('eventId', isEqualTo: widget.event.id)
          .where('memberEmail', isEqualTo: userEmail)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (!mounted) return;

        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final status = doc.data()['status']?.toString();
          setState(() {
            _invitationId = doc.id;
            _invitationStatus = status;
          });
        } else {
          setState(() {
            _invitationId = null;
            _invitationStatus = null;
          });
        }
      });
    }

    if (mounted) {
      setState(() {
        _isAdmin = role == 'admin';
        _isLoading = false;
      });
    }
  }

  Future<void> _setInvitationStatus(String status) async {
    final userEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (userEmail == null || widget.event.teamId.isEmpty) return;

    try {
      if (_invitationId != null) {
        await FirebaseFirestore.instance
            .collection('invitations')
            .doc(_invitationId)
            .update({'status': status, 'respondedAt': DateTime.now()});
      } else {
        final doc = await FirebaseFirestore.instance.collection('invitations').add({
          'eventId': widget.event.id,
          'teamId': widget.event.teamId,
          'memberEmail': userEmail,
          'status': status,
          'sentAt': DateTime.now(),
          'respondedAt': DateTime.now(),
        });
        _invitationId = doc.id;
      }
      if (mounted) {
        setState(() => _invitationStatus = status);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to set RSVP: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _toggleEventStatus() async {
    final newStatus = widget.event.status == 'Confirmed' ? 'Pending' : 'Confirmed';
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .update({'status': newStatus});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update event status: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAccepted = _invitationStatus == 'Accepted';
    final hasDeclined = _invitationStatus == 'Declined';
    final displayStatus = hasAccepted
        ? 'Accepted'
        : hasDeclined
            ? 'Declined'
            : widget.event.status;

    final statusColor = displayStatus == 'Confirmed' || displayStatus == 'Accepted'
        ? Colors.green
        : displayStatus == 'Declined'
            ? Colors.red
            : Colors.orange;

    final dateLabel = '${widget.event.eventDateTime.month.toString().padLeft(2, '0')}/${widget.event.eventDateTime.day.toString().padLeft(2, '0')}/${widget.event.eventDateTime.year}';
    final hour = widget.event.eventDateTime.hour == 0 ? 12 : (widget.event.eventDateTime.hour > 12 ? widget.event.eventDateTime.hour - 12 : widget.event.eventDateTime.hour);
    final period = widget.event.eventDateTime.hour >= 12 ? 'PM' : 'AM';
    final timeLabel = '${hour.toString().padLeft(2, '0')}:${widget.event.eventDateTime.minute.toString().padLeft(2, '0')} $period';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.event.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(displayStatus,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(widget.event.description,
              style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w400)),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
            const SizedBox(width: 4),
            Text(dateLabel, style: const TextStyle(fontSize: 12, color: Colors.black)),
            const SizedBox(width: 16),
            const Icon(Icons.access_time, size: 14, color: Colors.black54),
            const SizedBox(width: 4),
            Text(timeLabel, style: const TextStyle(fontSize: 12, color: Colors.black)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 14, color: Colors.black54),
            const SizedBox(width: 4),
            Text(widget.event.location, style: const TextStyle(fontSize: 12, color: Colors.black)),
          ]),
          const SizedBox(height: 12),
          if (!_isLoading) ...[
            Row(
              children: [
                Text(
                  'RSVP: ${_invitationStatus ?? 'Not invited'}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if ((_invitationStatus == null || _invitationStatus == 'Sent' || _invitationStatus == 'Pending'))
                  TextButton(
                    onPressed: () => _setInvitationStatus('Accepted'),
                    child: const Text('Accept'),
                  ),
                if ((_invitationStatus == null || _invitationStatus == 'Sent' || _invitationStatus == 'Pending'))
                  TextButton(
                    onPressed: () => _setInvitationStatus('Declined'),
                    child: const Text('Decline'),
                  ),
              ],
            ),
            if (_isAdmin)
              Row(
                children: [
                  const Text('Event status:'),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _toggleEventStatus,
                    child: Text(widget.event.status == 'Confirmed' ? 'Set Pending' : 'Set Confirmed'),
                  ),
                ],
              ),
          ]
        ],
      ),
    );
  }
}
