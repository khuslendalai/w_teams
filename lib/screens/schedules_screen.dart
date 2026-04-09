import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/schedule_service.dart';
import '../services/team_service.dart';

const scheduleAppColor = Color.fromARGB(255, 1, 4, 104);

// ── EventItem kept for home_screen.dart compatibility ─
class EventItem {
  final String id;
  final String title;
  final String description;
  final DateTime eventDateTime;
  final String location;
  final String status;
  final String teamId;
  final String createdBy;

  EventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDateTime,
    required this.location,
    required this.status,
    required this.teamId,
    this.createdBy = '',
  });

  factory EventItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final ts = data?['eventDateTime'] as Timestamp?;
    return EventItem(
      id: doc.id,
      title: data?['title'] ?? '',
      description: data?['description'] ?? '',
      eventDateTime: ts?.toDate() ?? DateTime.now(),
      location: data?['location'] ?? '',
      status: data?['status'] ?? 'Pending',
      teamId: data?['teamId'] ?? '',
      createdBy: data?['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'eventDateTime': eventDateTime,
        'location': location,
        'status': status,
        'teamId': teamId,
        'createdAt': DateTime.now(),
      };
}

// ─────────────────────────────────────────────────────
//  ScheduleScreen
// ─────────────────────────────────────────────────────
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _scheduleService = ScheduleService();
  final _teamService = TeamService();

  String? _teamId;
  bool _isLoading = true;
  bool _showPastEvents = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final teamId = await _teamService.getCurrentTeamId();
    if (mounted) {
      setState(() {
        _teamId = teamId;
        _isLoading = false;
      });
    }
    if (teamId != null) {
      await _scheduleService.closePastEvents(teamId);
    }
  }

  Stream<List<EventItem>> _eventsStream() {
    if (_teamId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('events')
        .where('teamId', isEqualTo: _teamId)
        .snapshots()
        .map((snap) {
      final events =
          snap.docs.map((d) => EventItem.fromFirestore(d)).toList();
      events.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
      return events;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _invitationsStream() {
    if (_teamId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('invitations')
        .where('teamId', isEqualTo: _teamId)
        .snapshots();
  }

  // ── Delete event + its invitations ───────────────────
  Future<void> _deleteEvent(EventItem event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Event'),
        content: Text(
            'Delete "${event.title}"? This will also remove all invitations for this event.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Delete invitations first
    final invSnap = await FirebaseFirestore.instance
        .collection('invitations')
        .where('eventId', isEqualTo: event.id)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in invSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(
        FirebaseFirestore.instance.collection('events').doc(event.id));
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event deleted.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── Create Event Dialog ───────────────────────────────
  Future<void> _createEvent() async {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    final locationC = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          String formatDate(DateTime? d) => d == null
              ? 'Pick date *'
              : '${d.day.toString().padLeft(2, '0')}/'
                  '${d.month.toString().padLeft(2, '0')}/'
                  '${d.year}';

          String formatTime(TimeOfDay? t) {
            if (t == null) return 'Pick time *';
            final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
            final p = t.period == DayPeriod.am ? 'AM' : 'PM';
            return '$h:${t.minute.toString().padLeft(2, '0')} $p';
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.event_outlined, color: scheduleAppColor),
                SizedBox(width: 8),
                Text(
                  'Create Event',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheduleAppColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(titleC, 'Title *',
                      Icons.title_outlined),
                  const SizedBox(height: 12),
                  _dialogField(
                      descC, 'Description', Icons.notes_outlined,
                      maxLines: 3),
                  const SizedBox(height: 12),
                  _dialogField(locationC, 'Location *',
                      Icons.location_on_outlined),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: scheduleAppColor),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setDlg(() => selectedDate = picked);
                      }
                    },
                    child: _pickerBox(
                      icon: Icons.calendar_today_outlined,
                      text: formatDate(selectedDate),
                      selected: selectedDate != null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.now(),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: scheduleAppColor),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setDlg(() => selectedTime = picked);
                      }
                    },
                    child: _pickerBox(
                      icon: Icons.access_time_outlined,
                      text: formatTime(selectedTime),
                      selected: selectedTime != null,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheduleAppColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (titleC.text.trim().isEmpty ||
                      locationC.text.trim().isEmpty ||
                      selectedDate == null ||
                      selectedTime == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please fill all required fields'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );

    if (save != true || _teamId == null) return;

    final eventDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    await _scheduleService.createEvent(
      teamId: _teamId!,
      title: titleC.text.trim(),
      description: descC.text.trim(),
      location: locationC.text.trim(),
      eventDateTime: eventDateTime,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Event created and invitations sent!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  static Widget _pickerBox({
    required IconData icon,
    required String text,
    required bool selected,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? scheduleAppColor : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheduleAppColor),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: selected ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _dialogField(
    TextEditingController c,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: scheduleAppColor),
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: scheduleAppColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: color,
          ),
        ),
      ],
    );
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
            const Icon(Icons.group_off_outlined,
                size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'You are not in a team yet.',
              style:
                  TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheduleAppColor,
                foregroundColor: Colors.white,
              ),
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

          // ── Header Row ─────────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Schedule',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.mail_outline, size: 16),
                label: const Text('Invitations'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheduleAppColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final email =
                      FirebaseAuth.instance.currentUser?.email;
                  if (email == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InvitationsScreen(email: email),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheduleAppColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _createEvent,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Summary Cards ──────────────────────────────
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _invitationsStream(),
            builder: (context, snapshot) {
              final invitations = snapshot.data?.docs ?? [];
              final acceptedCount = invitations
                  .where((d) =>
                      d.data()['status']?.toString() == 'Accepted')
                  .length;
              final pendingCount = invitations.where((d) {
                final s = d.data()['status']?.toString();
                return s != 'Accepted' && s != 'Declined';
              }).length;

              return Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Confirmed',
                      count: acceptedCount,
                      color: Colors.green,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Pending',
                      count: pendingCount,
                      color: Colors.orange,
                      icon: Icons.hourglass_empty_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Events List ────────────────────────────────
          StreamBuilder<List<EventItem>>(
            stream: _eventsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final events = snapshot.data ?? [];
              final now = DateTime.now();
              final currentUid =
                  FirebaseAuth.instance.currentUser?.uid ?? '';

              final confirmed = events
                  .where((e) => e.status == 'Confirmed')
                  .toList();
              final pending = events
                  .where((e) =>
                      e.status == 'Pending' &&
                      e.eventDateTime.isAfter(now))
                  .toList();
              final closed = events
                  .where((e) =>
                      e.status == 'Closed' ||
                      e.eventDateTime.isBefore(now))
                  .toList();

              if (events.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No events yet.\nTap "Create Event" to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Confirmed ────────────────────────
                  if (confirmed.isNotEmpty) ...[
                    _sectionLabel('CONFIRMED', Colors.green),
                    const SizedBox(height: 10),
                    ...confirmed.map((e) => _EventCard(
                          event: e,
                          canDelete: e.createdBy == currentUid,
                          onDelete: () => _deleteEvent(e),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // ── Pending ──────────────────────────
                  if (pending.isNotEmpty) ...[
                    _sectionLabel('PENDING RSVP', Colors.orange),
                    const SizedBox(height: 10),
                    ...pending.map((e) => _EventCard(
                          event: e,
                          canDelete: e.createdBy == currentUid,
                          onDelete: () => _deleteEvent(e),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // ── Past / Closed ─────────────────────
                  if (closed.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => setState(
                          () => _showPastEvents = !_showPastEvents),
                      child: Row(
                        children: [
                          _sectionLabel(
                              'PAST / CLOSED (${closed.length})',
                              Colors.grey),
                          const Spacer(),
                          Icon(
                            _showPastEvents
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showPastEvents ? 'Hide' : 'Show',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showPastEvents) ...[
                      const SizedBox(height: 10),
                      // Scrollable container capped at 3 visible
                      SizedBox(
                        height: closed.length > 2 ? 240 : null,
                        child: closed.length > 2
                            ? SingleChildScrollView(
                                child: Column(
                                  children: closed
                                      .map((e) => _EventCard(
                                            event: e,
                                            canDelete:
                                                e.createdBy ==
                                                    currentUid,
                                            onDelete: () =>
                                                _deleteEvent(e),
                                          ))
                                      .toList(),
                                ),
                              )
                            : Column(
                                children: closed
                                    .map((e) => _EventCard(
                                          event: e,
                                          canDelete:
                                              e.createdBy ==
                                                  currentUid,
                                          onDelete: () =>
                                              _deleteEvent(e),
                                        ))
                                    .toList(),
                              ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────
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
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Invitations Screen ────────────────────────────────
class InvitationsScreen extends StatefulWidget {
  final String email;
  const InvitationsScreen({super.key, required this.email});

  @override
  State<InvitationsScreen> createState() =>
      _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  Stream<QuerySnapshot> _stream() {
    return FirebaseFirestore.instance
        .collection('invitations')
        .where('memberEmail',
            isEqualTo: widget.email.toLowerCase())
        .snapshots();
  }

  Future<void> _respond(DocumentSnapshot doc, String status) async {
    await FirebaseFirestore.instance
        .collection('invitations')
        .doc(doc.id)
        .update(
            {'status': status, 'respondedAt': DateTime.now()});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'Accepted'
              ? '✅ Invitation accepted!'
              : '❌ Invitation declined.'),
          backgroundColor:
              status == 'Accepted' ? Colors.green : Colors.grey,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Your Invitations',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: scheduleAppColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No invitations found.',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data =
                  docs[i].data() as Map<String, dynamic>;
              final status =
                  data['status']?.toString() ?? 'Sent';
              Color statusColor = Colors.orange;
              if (status == 'Accepted') statusColor = Colors.green;
              if (status == 'Declined') statusColor = Colors.red;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Event Invitation',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  statusColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (status == 'Sent' ||
                        status == 'Pending') ...[
                      TextButton(
                        onPressed: () =>
                            _respond(docs[i], 'Accepted'),
                        child: const Text('Accept',
                            style:
                                TextStyle(color: Colors.green)),
                      ),
                      TextButton(
                        onPressed: () =>
                            _respond(docs[i], 'Declined'),
                        child: const Text('Decline',
                            style:
                                TextStyle(color: Colors.red)),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Event Card ────────────────────────────────────────
class _EventCard extends StatefulWidget {
  final EventItem event;
  final bool canDelete;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _isAdmin = false;
  bool _isLoading = true;
  bool _showRSVPDetails = false;
  String? _invitationStatus;
  String? _invitationId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadContext() async {
    final role = await TeamService().getCurrentUserRole();
    final email =
        FirebaseAuth.instance.currentUser?.email?.toLowerCase();

    if (email != null) {
      _sub = FirebaseFirestore.instance
          .collection('invitations')
          .where('eventId', isEqualTo: widget.event.id)
          .where('memberEmail', isEqualTo: email)
          .limit(1)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first;
          setState(() {
            _invitationId = doc.id;
            _invitationStatus =
                doc.data()['status']?.toString();
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

  Future<void> _rsvp(String status) async {
    final email =
        FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (email == null) return;

    if (_invitationId != null) {
      await FirebaseFirestore.instance
          .collection('invitations')
          .doc(_invitationId)
          .update(
              {'status': status, 'respondedAt': DateTime.now()});
    } else {
      final doc = await FirebaseFirestore.instance
          .collection('invitations')
          .add({
        'eventId': widget.event.id,
        'teamId': widget.event.teamId,
        'memberEmail': email,
        'status': status,
        'sentAt': DateTime.now(),
        'respondedAt': DateTime.now(),
      });
      _invitationId = doc.id;
    }

    if (status == 'Accepted') {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .update({'status': 'Confirmed'});
    }

    if (mounted) setState(() => _invitationStatus = status);
  }

  Future<void> _toggleStatus() async {
    final newStatus = widget.event.status == 'Confirmed'
        ? 'Pending'
        : 'Confirmed';
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = widget.event.eventDateTime.isBefore(now);
    final isClosed = widget.event.status == 'Closed' || isPast;

    final displayStatus = _invitationStatus == 'Accepted'
        ? 'Accepted'
        : _invitationStatus == 'Declined'
            ? 'Declined'
            : isClosed
                ? 'Closed'
                : widget.event.status;

    final statusColor =
        displayStatus == 'Confirmed' || displayStatus == 'Accepted'
            ? Colors.green
            : displayStatus == 'Declined'
                ? Colors.red
                : displayStatus == 'Closed'
                    ? Colors.grey
                    : Colors.orange;

    final dt = widget.event.eventDateTime;
    final dateLabel =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final hour = dt.hour == 0
        ? 12
        : dt.hour > 12
            ? dt.hour - 12
            : dt.hour;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final timeLabel =
        '$hour:${dt.minute.toString().padLeft(2, '0')} $period';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Colored top bar ──────────────────────────
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Title + Status + Delete ──────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        displayStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),

                    // ── Delete (creator only) ────────────
                    if (widget.canDelete) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: widget.onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // ── Description ──────────────────────────
                if (widget.event.description.isNotEmpty) ...[
                  Text(
                    widget.event.description,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                ],

                // ── Date + Time ──────────────────────────
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(dateLabel,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87)),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(timeLabel,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 6),

                // ── Location ─────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.event.location,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),

                // ── RSVP section (active events only) ────
                if (!_isLoading && !isClosed) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'RSVP: ${_invitationStatus ?? 'Pending'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_invitationStatus == null ||
                          _invitationStatus == 'Sent' ||
                          _invitationStatus == 'Pending') ...[
                        ElevatedButton(
                          onPressed: () => _rsvp('Accepted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize
                                .shrinkWrap,
                          ),
                          child: const Text('Accept',
                              style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _rsvp('Declined'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(
                                color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize
                                .shrinkWrap,
                          ),
                          child: const Text('Decline',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                  if (_isAdmin) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _toggleStatus,
                      icon: const Icon(Icons.swap_horiz,
                          size: 16),
                      label: Text(
                        widget.event.status == 'Confirmed'
                            ? 'Set Pending'
                            : 'Set Confirmed',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheduleAppColor,
                        side: const BorderSide(
                            color: scheduleAppColor),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                  TextButton(
                    onPressed: () => setState(() =>
                        _showRSVPDetails = !_showRSVPDetails),
                    style: TextButton.styleFrom(
                      foregroundColor: scheduleAppColor,
                      padding: EdgeInsets.zero,
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _showRSVPDetails
                          ? 'Hide attendees'
                          : 'View attendees',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (_showRSVPDetails)
                    _RSVPDetails(eventId: widget.event.id),
                ],

                // ── Past label ───────────────────────────
                if (isClosed) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'This event has passed.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── RSVP Details Widget ───────────────────────────────
class _RSVPDetails extends StatelessWidget {
  final String eventId;
  const _RSVPDetails({required this.eventId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('invitations')
          .where('eventId', isEqualTo: eventId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
                child:
                    CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final accepted = docs
            .where((d) => d.data()['status'] == 'Accepted')
            .toList();
        final declined = docs
            .where((d) => d.data()['status'] == 'Declined')
            .toList();
        final pending = docs
            .where((d) =>
                d.data()['status'] != 'Accepted' &&
                d.data()['status'] != 'Declined')
            .toList();

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No responses yet.',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey)),
          );
        }

        Widget section(String label, List docs, Color color) {
          if (docs.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label (${docs.length})',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 12),
              ),
              const SizedBox(height: 4),
              ...docs.take(10).map((d) {
                final email =
                    (d.data() as Map<String, dynamic>)[
                            'memberEmail']
                        ?.toString() ??
                        'unknown';
                return Text('• $email',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54));
              }),
              const SizedBox(height: 8),
            ],
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              section('Accepted', accepted, Colors.green),
              section('Declined', declined, Colors.red),
              section('Pending', pending, Colors.orange),
            ],
          ),
        );
      },
    );
  }
}