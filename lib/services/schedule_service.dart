import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduleService {
  final _events = FirebaseFirestore.instance.collection('events');
  final _invitations =
      FirebaseFirestore.instance.collection('invitations');
  final _members = FirebaseFirestore.instance.collection('members');

  // ── Get current user's teamId ────────────────────────
  Future<String?> getTeamId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data()?['teamId'];
  }

  // ── Stream of events for team ────────────────────────
  Stream<List<EventData>> eventsStream(String teamId) {
    return _events
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snap) {
      final events =
          snap.docs.map((d) => EventData.fromFirestore(d)).toList();
      events
          .sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
      return events;
    });
  }

  // ── Create event + send invitations ──────────────────
  Future<void> createEvent({
    required String teamId,
    required String title,
    required String description,
    required String location,
    required DateTime eventDateTime,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final eventRef = await _events.add({
      'teamId': teamId,
      'title': title,
      'description': description,
      'location': location,
      'eventDateTime': Timestamp.fromDate(eventDateTime),
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
    });

    final membersSnap = await _members
        .where('teamId', isEqualTo: teamId)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in membersSnap.docs) {
      final invRef = _invitations.doc();
      batch.set(invRef, {
        'eventId': eventRef.id,
        'teamId': teamId,
        'memberId': doc.id,
        'memberEmail': (doc.data()['email'] ?? '').toString(),
        'status': 'Sent',
        'sentAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ── Auto-close past events ────────────────────────────
  Future<void> closePastEvents(String teamId) async {
    final now = DateTime.now();
    final snap = await _events
        .where('teamId', isEqualTo: teamId)
        .where('status', isEqualTo: 'Pending')
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      final ts = doc.data()['eventDateTime'] as Timestamp?;
      if (ts != null && ts.toDate().isBefore(now)) {
        batch.update(doc.reference, {'status': 'Closed'});
      }
    }
    await batch.commit();
  }

  // ── RSVP ─────────────────────────────────────────────
  Future<void> respondToInvitation({
    required String invitationId,
    required String eventId,
    required String status,
  }) async {
    await _invitations.doc(invitationId).update({
      'status': status,
      'respondedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'Accepted') {
      await _events.doc(eventId).update({'status': 'Confirmed'});
    }
  }
}

// ── EventData model ───────────────────────────────────
class EventData {
  final String id;
  final String title;
  final String description;
  final DateTime eventDateTime;
  final String location;
  final String status;
  final String teamId;

  EventData({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDateTime,
    required this.location,
    required this.status,
    required this.teamId,
  });

  factory EventData.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>?;
    final ts = d?['eventDateTime'];
    return EventData(
      id: doc.id,
      title: d?['title'] ?? '',
      description: d?['description'] ?? '',
      eventDateTime: ts is Timestamp
          ? ts.toDate()
          : DateTime.now(),
      location: d?['location'] ?? '',
      status: d?['status'] ?? 'Pending',
      teamId: d?['teamId'] ?? '',
    );
  }
}