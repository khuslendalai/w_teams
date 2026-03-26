import 'package:flutter/material.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  final List<Map<String, String>> members = const [
    {
      'name': 'Sarah Johnson',
      'role': 'Acoustic Guitar',
      'email': 'sarah@example.com',
    },
    {
      'name': 'Mark Dela Cruz',
      'role': 'Electric Guitar',
      'email': 'mark@example.com',
    },
    {
      'name': 'Lisa Reyes',
      'role': 'Vocals',
      'email': 'lisa@example.com',
    },
    {
      'name': 'James Santos',
      'role': 'Bass Guitar',
      'email': 'james@example.com',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Team Button
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
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_add_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Create New Team',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'TEAM MEMBERS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          ...members.map((member) => _MemberCard(member: member)).toList(),
        ],
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Create Team'),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, String> member;

  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);

    final nameParts = member['name']!.split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'
        : nameParts[0][0];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: appColor,
            child: Text(initials),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member['name']!),
                Text(member['role']!),
                Text(member['email']!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}