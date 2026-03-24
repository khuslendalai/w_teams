import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  final List<Map<String, String>> schedules = const [
    {
      'month': 'NOV',
      'day': '12',
      'time': '9:00 AM',
      'title': 'Sunday Morning Service',
      'role': 'Acoustic Guitar',
      'location': 'Main Sanctuary',
      'status': 'Confirmed',
    },
    {
      'month': 'NOV',
      'day': '19',
      'time': '6:00 PM',
      'title': 'Evening Worship',
      'role': 'Acoustic Guitar',
      'location': 'Main Sanctuary',
      'status': 'Pending',
    },
    {
      'month': 'NOV',
      'day': '26',
      'time': '9:00 AM',
      'title': 'Sunday Morning',
      'role': 'Electric Guitar',
      'location': 'Chapel Hall',
      'status': 'Confirmed',
    },
    {
      'month': 'DEC',
      'day': '03',
      'time': '9:00 AM',
      'title': 'First Advent',
      'role': 'Acoustic Guitar',
      'location': 'Main Sanctuary',
      'status': 'Pending',
    },
    {
      'month': 'DEC',
      'day': '10',
      'time': '9:00 AM',
      'title': 'Second Advent',
      'role': 'Bass Guitar',
      'location': 'Main Sanctuary',
      'status': 'Confirmed',
    },
    {
      'month': 'DEC',
      'day': '24',
      'time': '7:00 PM',
      'title': 'Christmas Eve Service',
      'role': 'Acoustic Guitar',
      'location': 'Main Sanctuary',
      'status': 'Pending',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);

    // Separate confirmed and pending
    final confirmed = schedules.where((s) => s['status'] == 'Confirmed').toList();
    final pending = schedules.where((s) => s['status'] == 'Pending').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Summary Row ────────────────────────────────
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

          // ── Confirmed Section ──────────────────────────
          const Text(
            'CONFIRMED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          ...confirmed.map((item) => _ScheduleCard(item: item)).toList(),
          const SizedBox(height: 24),

          // ── Pending Section ────────────────────────────
          const Text(
            'PENDING RSVP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          ...pending.map((item) => _ScheduleCard(item: item)).toList(),
          const SizedBox(height: 20),

        ],
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Schedule Card ─────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  final Map<String, String> item;

  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);
    final isPending = item['status'] == 'Pending';

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

          // ── Top Row: Date + Title + Status ─────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Date badge
                Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: appColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        item['month']!,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item['day']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Event name & time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_outlined,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            item['time']!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['status']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPending ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ────────────────────────────────────
          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Bottom Row: Role + Location ─────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Assigned Role
                const Icon(Icons.assignment_outlined,
                    size: 14, color: appColor),
                const SizedBox(width: 6),
                Text(
                  item['role']!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: appColor,
                  ),
                ),
                const SizedBox(width: 16),

                // Location
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  item['location']!,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}