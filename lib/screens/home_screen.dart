import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'songs_screen.dart';
import 'schedules_screen.dart';
import 'teams_screen.dart';
import 'settings_screen.dart';


class HomeScreen extends StatefulWidget {
  final String email;

  const HomeScreen({super.key, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _handleLogout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  final List<String> _pageTitles = [
    'Home', 'Songs', 'Schedule', 'Teams', 'Settings'
  ];

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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: appColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
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
                onPressed: () {},
              ),
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
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note_outlined),
            activeIcon: Icon(Icons.music_note),
            label: 'Songs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt),
            label: 'Team',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  // ── Dashboard Page ────────────────────────────────────────
  Widget _buildDashboard() {
    const appColor = Color.fromARGB(255, 1, 4, 104);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Hello Card ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
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
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color.fromARGB(255, 1, 4, 104),
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${widget.email.split('@')[0]}!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: appColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'You have 1 pending invitation',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Your Next Service ───────────────────────────
          const Text(
            'YOUR NEXT SERVICE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner image placeholder
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
                            color: Colors.white24, size: 64),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PENDING RSVP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Service details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sunday Morning Service',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          Icon(Icons.calendar_today_outlined,
                              size: 13, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Nov 12, 9:00 AM',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Assigned Role chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.assignment_outlined,
                                size: 14, color: appColor),
                            SizedBox(width: 6),
                            Text(
                              'Assigned Role:  ',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              'Acoustic Guitar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: appColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Accept / Decline buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
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
                              onPressed: () {},
                              icon: const Icon(Icons.cancel_outlined,
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
          ),
          const SizedBox(height: 24),

          // ── This Week's Setlist ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "THIS WEEK'S SETLIST",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.black54,
                ),
              ),
              // View All → navigates to Songs tab
              GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = 1);
                },
                child: const Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 12,
                    color: appColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
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
            child: Column(
              children: [
                _SongItem(
                    number: 1,
                    title: 'Gratitude',
                    artist: 'Brandon Lake',
                    keyLabel: 'Key of B'),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _SongItem(
                    number: 2,
                    title: 'Worthy of It All',
                    artist: 'CeCe Winans',
                    keyLabel: 'Key of D'),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _SongItem(
                    number: 3,
                    title: 'Firm Foundation',
                    artist: 'Cody Carnes',
                    keyLabel: 'Key of Bb'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Upcoming Assignments ────────────────────────
          const Text(
            'UPCOMING ASSIGNMENTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Container(
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
            child: Column(
              children: [
                _AssignmentItem(
                    month: 'NOV',
                    day: '19',
                    title: 'Evening Worship',
                    role: 'Acoustic Guitar'),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _AssignmentItem(
                    month: 'NOV',
                    day: '26',
                    title: 'Sunday Morning',
                    role: 'Electric Guitar'),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _AssignmentItem(
                    month: 'DEC',
                    day: '03',
                    title: 'First Advent',
                    role: 'Acoustic Guitar'),
              ],
            ),
          ),
          const SizedBox(height: 20),

        ],
      ),
    );
  }

  // ── Placeholder Pages ─────────────────────────────────────
  Widget _buildPlaceholder(IconData icon, String title) {
    const appColor = Color.fromARGB(255, 1, 4, 104);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: appColor),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: appColor)),
          const SizedBox(height: 8),
          Text('$title page coming soon.',
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // ── Settings Page ─────────────────────────────────────────
  Widget _buildSettings(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings_outlined, size: 64, color: appColor),
            const SizedBox(height: 16),
            const Text('Settings',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: appColor)),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout, color: appColor),
              label: const Text('Logout',
                  style: TextStyle(color: appColor, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: appColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Song Item Widget ──────────────────────────────────────
class _SongItem extends StatelessWidget {
  final int number;
  final String title;
  final String artist;
  final String keyLabel;

  const _SongItem({
    required this.number,
    required this.title,
    required this.artist,
    required this.keyLabel,
  });

  @override
  Widget build(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text('$number',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 13)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text('$artist • $keyLabel',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Chords',
                style: TextStyle(
                    fontSize: 11,
                    color: appColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Assignment Item Widget ────────────────────────────────
class _AssignmentItem extends StatelessWidget {
  final String month;
  final String day;
  final String title;
  final String role;

  const _AssignmentItem({
    required this.month,
    required this.day,
    required this.title,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: appColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(month,
                    style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
                Text(day,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(role,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}