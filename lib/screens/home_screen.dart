import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'songs_screen.dart';
import 'schedules_screen.dart';
import 'teams_screen.dart';
import 'settings_screen.dart';
import '../models/song_model.dart';
import '../services/song_service.dart';

// ─────────────────────────────────────────────────────────────
//  Data Models
// ─────────────────────────────────────────────────────────────

class ServiceInvitation {
  final String id;
  final String eventId;
  final String title;
  final DateTime dateTime;
  final String location;
  final String status;

  const ServiceInvitation({
    required this.id,
    required this.eventId,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.status,
  });
}

// ─────────────────────────────────────────────────────────────
//  HomeScreen
// ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final String email;

  const HomeScreen({super.key, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Nav ───────────────────────────────────────────────────
  int _selectedIndex = 0;

  // ── Firebase refs ─────────────────────────────────────────
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  // ── Services ──────────────────────────────────────────────
  final _songService = SongService();

  // ── State ─────────────────────────────────────────────────
  String _displayName = '';

  ServiceInvitation? _nextInvitation;
  bool _invitationLoading = true;

  List<EventItem> _upcomingEvents = [];
  bool _eventsLoading = true;

  List<Song> _setlistSongs = [];
  bool _songsLoading = true;

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadDisplayName();
    _loadNextInvitation();
    _loadUpcomingEvents();
    _loadSetlistSongs();
  }

  // ── Auth: real display name ───────────────────────────────
  void _loadDisplayName() {
    final user = _auth.currentUser;
    if (user == null) return;

    _db.collection('users').doc(user.uid).get().then((snap) {
      if (!mounted) return;
      final name = (snap.data()?['displayName'] as String?)?.isNotEmpty == true
          ? snap.data()!['displayName'] as String
          : (user.displayName?.isNotEmpty == true
              ? user.displayName!
              : user.email!.split('@')[0]);
      setState(() => _displayName = name);
    }).catchError((_) {
      if (!mounted) return;
      setState(() =>
          _displayName = user.email?.split('@')[0] ?? 'Worshiper');
    });
  }

  // ── Firestore: pending invitation ─────────────────────────
  void _loadNextInvitation() {
    final email = _auth.currentUser?.email?.toLowerCase();
    if (email == null) {
      setState(() => _invitationLoading = false);
      return;
    }

    _db
        .collection('invitations')
        .where('memberEmail', isEqualTo: email)
        .where('status', isEqualTo: 'Sent')
        .snapshots()
        .listen((snap) async {
      if (!mounted) return;

      if (snap.docs.isEmpty) {
        setState(() {
          _nextInvitation = null;
          _invitationLoading = false;
        });
        return;
      }

      ServiceInvitation? soonest;
      for (final doc in snap.docs) {
        final data = doc.data();
        final eventId = data['eventId']?.toString() ?? '';
        if (eventId.isEmpty) continue;

        final eventSnap =
            await _db.collection('events').doc(eventId).get();
        if (!eventSnap.exists) continue;

        final ed = eventSnap.data()!;
        final ts = ed['eventDateTime'] as Timestamp?;
        if (ts == null) continue;
        final dt = ts.toDate();
        if (dt.isBefore(DateTime.now())) continue;

        final inv = ServiceInvitation(
          id: doc.id,
          eventId: eventId,
          title: ed['title'] ?? 'Service',
          dateTime: dt,
          location: ed['location'] ?? '',
          status: data['status'] ?? 'Sent',
        );

        if (soonest == null || dt.isBefore(soonest.dateTime)) {
          soonest = inv;
        }
      }

      if (mounted) {
        setState(() {
          _nextInvitation = soonest;
          _invitationLoading = false;
        });
      }
    }, onError: (_) {
      if (mounted) setState(() => _invitationLoading = false);
    });
  }

  // ── Firestore: upcoming events ────────────────────────────
  void _loadUpcomingEvents() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _eventsLoading = false);
      return;
    }

    final userDoc = await _db.collection('users').doc(uid).get();
    final teamId = userDoc.data()?['teamId']?.toString() ?? '';

    if (teamId.isEmpty) {
      if (mounted) setState(() => _eventsLoading = false);
      return;
    }

    _db
        .collection('events')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final now = DateTime.now();
      final events = snap.docs
          .map((d) => EventItem.fromFirestore(d))
          .where((e) => e.eventDateTime.isAfter(now))
          .toList()
        ..sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

      setState(() {
        _upcomingEvents = events.take(5).toList();
        _eventsLoading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _eventsLoading = false);
    });
  }

  // ── Firestore: real setlist songs ─────────────────────────
  void _loadSetlistSongs() {
    _songService.getSongs().listen((songs) {
      if (!mounted) return;
      setState(() {
        _setlistSongs = songs.take(5).toList();
        _songsLoading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _songsLoading = false);
    });
  }

  // ── RSVP actions ──────────────────────────────────────────
  Future<void> _respondToInvitation(
      String invitationId, String response) async {
    try {
      await _db.collection('invitations').doc(invitationId).update({
        'status': response,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      if (response == 'Accepted' && _nextInvitation != null) {
        await _db
            .collection('events')
            .doc(_nextInvitation!.eventId)
            .update({'status': 'Confirmed'});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response == 'Accepted'
                ? '✅ You accepted the invitation!'
                : '❌ You declined the invitation.'),
            backgroundColor:
                response == 'Accepted' ? Colors.green : Colors.grey[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> _handleLogout(BuildContext context) async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboard(),
      const SongsScreen(),
      const ScheduleScreen(),
      const TeamsScreen(),
      SettingsScreen(email: widget.email),
    ];

    const appColor = Color.fromARGB(255, 1, 4, 104);
    final int pendingCount = _nextInvitation != null ? 1 : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: appColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Worship Team',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),
              if (pendingCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: appColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.music_note_outlined),
              activeIcon: Icon(Icons.music_note),
              label: 'Songs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Schedule'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt),
              label: 'Team'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Dashboard
  // ─────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Hello Card ────────────────────────────────────
          _HelloCard(
            displayName: _displayName.isEmpty
                ? widget.email.split('@')[0]
                : _displayName,
            pendingCount: _nextInvitation != null ? 1 : 0,
          ),
          const SizedBox(height: 24),

          // ── Next Service ──────────────────────────────────
          const _SectionHeader(label: 'YOUR NEXT SERVICE'),
          const SizedBox(height: 10),
          _invitationLoading
              ? const _LoadingCard()
              : _nextInvitation != null
                  ? _ServiceCard(
                      invitation: _nextInvitation!,
                      onAccept: () => _respondToInvitation(
                          _nextInvitation!.id, 'Accepted'),
                      onDecline: () => _respondToInvitation(
                          _nextInvitation!.id, 'Declined'),
                    )
                  : const _EmptyCard(
                      icon: Icons.church,
                      message: 'No pending service invitations.',
                    ),
          const SizedBox(height: 24),

          // ── This Week's Setlist ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader(label: "THIS WEEK'S SETLIST"),
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 1),
                child: const Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 1, 4, 104),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _songsLoading
              ? const _LoadingCard()
              : _setlistSongs.isEmpty
                  ? const _EmptyCard(
                      icon: Icons.queue_music,
                      message: 'No songs in the setlist yet.',
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _setlistSongs.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (_, i) {
                          final song = _setlistSongs[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black38,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${song.artist} • Key of ${song.key}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (song.bpm > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F2FF),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${song.bpm} BPM',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color.fromARGB(
                                            255, 1, 4, 104),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          const SizedBox(height: 24),

          // ── Upcoming Events ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader(label: 'UPCOMING EVENTS'),
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 2),
                child: const Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 1, 4, 104),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _eventsLoading
              ? const _LoadingCard()
              : _upcomingEvents.isEmpty
                  ? const _EmptyCard(
                      icon: Icons.event_busy,
                      message: 'No upcoming events scheduled.',
                    )
                  : _UpcomingEventsCard(events: _upcomingEvents),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Reusable layout widgets
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.black54,
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color.fromARGB(255, 1, 4, 104),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 28),
          const SizedBox(width: 14),
          Text(message,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Hello Card
// ─────────────────────────────────────────────────────────────

class _HelloCard extends StatelessWidget {
  final String displayName;
  final int pendingCount;
  const _HelloCard({required this.displayName, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: appColor,
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $displayName!',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appColor),
              ),
              const SizedBox(height: 4),
              Text(
                pendingCount > 0
                    ? 'You have $pendingCount pending invitation'
                    : 'No pending invitations',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Service / Invitation Card
// ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatefulWidget {
  final ServiceInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _ServiceCard({
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _busy = false;

  Future<void> _handle(VoidCallback action) async {
    setState(() => _busy = true);
    action();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);
    final inv = widget.invitation;

    final dateLabel =
        '${_monthName(inv.dateTime.month)} ${inv.dateTime.day}, '
        '${_pad(inv.dateTime.hour % 12 == 0 ? 12 : inv.dateTime.hour % 12)}:'
        '${_pad(inv.dateTime.minute)} '
        '${inv.dateTime.hour < 12 ? 'AM' : 'PM'}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            height: 130,
            decoration: const BoxDecoration(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
              color: Color(0xFF1A1A2E),
            ),
            child: Stack(
              children: [
                const Center(
                    child: Icon(Icons.church,
                        color: Colors.white24, size: 64)),
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text(
                      'PENDING RSVP',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(dateLabel,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                if (inv.location.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0F2FF),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: appColor),
                        const SizedBox(width: 6),
                        const Text('Location:  ',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        Text(
                          inv.location,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: appColor),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                _busy
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: appColor),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _handle(widget.onAccept),
                              icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 16),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _handle(widget.onDecline),
                              icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 16),
                              label: const Text('Decline'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey,
                                side: const BorderSide(
                                    color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  static String _pad(int n) => n.toString().padLeft(2, '0');
}

// ─────────────────────────────────────────────────────────────
//  Upcoming Events Card
// ─────────────────────────────────────────────────────────────

class _UpcomingEventsCard extends StatelessWidget {
  final List<EventItem> events;
  const _UpcomingEventsCard({required this.events});

  static const _appColor = Color.fromARGB(255, 1, 4, 104);

  static String _monthAbbr(int m) => const [
        '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
      ][m];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (_, i) {
          final e = events[i];
          final isConfirmed = e.status == 'Confirmed';
          final statusColor =
              isConfirmed ? Colors.green : Colors.orange;

          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                      color: _appColor,
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Text(
                        _monthAbbr(e.eventDateTime.month),
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${e.eventDateTime.day}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      if (e.location.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 11, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(e.location,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey)),
                          ],
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    e.status,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}