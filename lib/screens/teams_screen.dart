import 'package:flutter/material.dart';
class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  final List<Map<String, String>> members = const [
    {
      'name': 'Sarah Johnson',
      'role': 'Acoustic Guitar',
      'status': 'Active',
      'email': 'sarah@example.com',
    },
    {
      'name': 'Mark Dela Cruz',
      'role': 'Electric Guitar',
      'status': 'Active',
      'email': 'mark@example.com',
    },
    {
      'name': 'Lisa Reyes',
      'role': 'Vocals',
      'status': 'Active',
      'email': 'lisa@example.com',
    },
    {
      'name': 'James Santos',
      'role': 'Bass Guitar',
      'status': 'Active',
      'email': 'james@example.com',
    },
    {
      'name': 'Anna Cruz',
      'role': 'Keyboard',
      'status': 'Inactive',
      'email': 'anna@example.com',
    },
    {
      'name': 'David Lim',
      'role': 'Drums',
      'status': 'Active',
      'email': 'david@example.com',
    },
    {
      'name': 'Grace Tan',
      'role': 'Vocals',
      'status': 'Active',
      'email': 'grace@example.com',
    },
    {
      'name': 'Paul Garcia',
      'role': 'Sound Engineer',
      'status': 'Inactive',
      'email': 'paul@example.com',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);

    final active = members.where((m) => m['status'] == 'Active').toList();
    final inactive = members.where((m) => m['status'] == 'Inactive').toList();

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
                  label: 'Active',
                  count: active.length,
                  color: Colors.green,
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SummaryCard(
                  label: 'Inactive',
                  count: inactive.length,
                  color: Colors.grey,
                  icon: Icons.person_off_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Create New Team Button ─────────────────────
          GestureDetector(
            onTap: () {
              _showCreateTeamDialog(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_add_outlined,
                      color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Create New Team',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Active Members ─────────────────────────────
          const Text(
            'ACTIVE MEMBERS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          ...active
              .map((member) => _MemberCard(member: member))
              .toList(),
          const SizedBox(height: 24),

          // ── Inactive Members ───────────────────────────
          const Text(
            'INACTIVE MEMBERS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          ...inactive
              .map((member) => _MemberCard(member: member))
              .toList(),
          const SizedBox(height: 20),

        ],
      ),
    );
  }

  // ── Create Team Dialog ────────────────────────────────────
  void _showCreateTeamDialog(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);
    final TextEditingController teamNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.group_add_outlined, color: appColor),
              SizedBox(width: 8),
              Text(
                'Create New Team',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: appColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter a name for your new worship team.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: teamNameController,
                decoration: InputDecoration(
                  labelText: 'Team Name',
                  prefixIcon:
                      const Icon(Icons.people_outline, color: appColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: appColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // Cancel
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            // Create
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (teamNameController.text.trim().isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '✅ Team "${teamNameController.text.trim()}" created!'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
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
                '$count Members',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Member Card ───────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final Map<String, String> member;

  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);
    final isActive = member['status'] == 'Active';

    // Get initials from name
    final nameParts = member['name']!.split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'
        : nameParts[0][0];

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

          // ── Top: Avatar + Name + Status ─────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with initials
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      isActive ? appColor : Colors.grey.shade300,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['name']!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.music_note_outlined,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            member['role']!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status indicator
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      member['status']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Divider ────────────────────────────────────
          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Bottom: Contact Button ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.email_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    member['email']!,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ),
                // Contact button
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Contacting ${member['name']}...'),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.send_outlined,
                            size: 13, color: appColor),
                        SizedBox(width: 5),
                        Text(
                          'Contact',
                          style: TextStyle(
                            fontSize: 12,
                            color: appColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}