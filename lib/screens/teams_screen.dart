import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/member_model.dart';
import '../models/team_model.dart';
import '../services/member_service.dart';
import '../services/team_service.dart';
import 'add_member_screen.dart';
import 'create_team_screen.dart';
import 'join_team_screen.dart';
import 'member_detail_screen.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  static const appColor = Color.fromARGB(255, 1, 4, 104);

  final _memberService = MemberService();
  final _teamService = TeamService();

  Team? _team;
  bool _loadingTeam = true;
  bool _codeVisible = false;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    final teamId = await _teamService.getCurrentTeamId();
    if (teamId != null) {
      final team = await _teamService.getTeam(teamId);
      if (mounted) setState(() => _team = team);
    }
    if (mounted) setState(() => _loadingTeam = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Team Header ──────────────────────────────────
          _loadingTeam
              ? _buildHeaderSkeleton()
              : _team == null
                  ? _buildNoTeamCard()
                  : _buildTeamHeader(_team!),

          const SizedBox(height: 20),

          // ── Action Buttons ───────────────────────────────
          if (_team != null) ...[
            _buildButton(
              label: 'Add New Member',
              icon: Icons.person_add_outlined,
              filled: true,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddMemberScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          if (_team == null && !_loadingTeam) ...[
            _buildButton(
              label: 'Create New Team',
              icon: Icons.group_add_outlined,
              filled: true,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateTeamScreen(),
                  ),
                );
                _loadTeam();
              },
            ),
            const SizedBox(height: 12),
            _buildButton(
              label: 'Join a Team',
              icon: Icons.login_outlined,
              filled: false,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const JoinTeamScreen(),
                  ),
                );
                _loadTeam();
              },
            ),
            const SizedBox(height: 20),
          ],

          // ── Members Section ──────────────────────────────
          if (_team != null) ...[
            // ── Member Count Summary ───────────────────────
            StreamBuilder<List<Member>>(
              stream: _memberService.getMembers(),
              builder: (context, snapshot) {
                final members = snapshot.data ?? [];
                final count = members.length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Summary Row ──────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            label: 'Total Members',
                            value: '$count',
                            icon: Icons.people_outline,
                            color: appColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            label: 'Roles Filled',
                            value:
                                '${members.map((m) => m.role).toSet().length}',
                            icon: Icons.music_note_outlined,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Members Label ────────────────────
                    const Text(
                      'TEAM MEMBERS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Members List ─────────────────────
                    if (snapshot.connectionState ==
                        ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (members.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'No members yet.\nTap "Add New Member" to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...members.map(
                        (m) => GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MemberDetailScreen(member: m),
                            ),
                          ),
                          child: _MemberCard(
                            member: m,
                            memberService: _memberService,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Team Header Card ──────────────────────────────────────
  Widget _buildTeamHeader(Team team) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: appColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Team Name Row ──────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.group_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR TEAM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white60,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // ── Invite Code Row ────────────────────────────
          Row(
            children: [
              const Text(
                'Invite Code',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),

              // Code (hidden or visible)
              GestureDetector(
                onTap: () =>
                    setState(() => _codeVisible = !_codeVisible),
                child: Text(
                  _codeVisible ? team.inviteCode : '••••••',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Toggle visibility
              GestureDetector(
                onTap: () =>
                    setState(() => _codeVisible = !_codeVisible),
                child: Icon(
                  _codeVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),

              // Copy button
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: team.inviteCode),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Invite code copied!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.copy_outlined,
                          color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── No Team Card ──────────────────────────────────────────
  Widget _buildNoTeamCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: const Column(
        children: [
          Icon(Icons.group_off_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'You are not part of a team yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Create a new team or join one\nusing an invite code.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── Header Skeleton (loading state) ──────────────────────
  Widget _buildHeaderSkeleton() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // ── Summary Card ──────────────────────────────────────────
  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Reusable Button ───────────────────────────────────────
  Widget _buildButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: filled ? appColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: appColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(filled ? 0.1 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: filled ? Colors.white : appColor, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : appColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member Card ───────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final Member member;
  final MemberService memberService;

  const _MemberCard({
    required this.member,
    required this.memberService,
  });

  static const appColor = Color.fromARGB(255, 1, 4, 104);

  @override
  Widget build(BuildContext context) {
    final nameParts = member.name.split(' ');
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

          // ── Top: Avatar + Name + Delete ──────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: appColor,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
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
                            member.role,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Delete Button ──────────────────────────
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: const Text('Remove Member'),
                        content: Text(
                            'Remove ${member.name} from the team?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, true),
                            child: const Text('Remove',
                                style: TextStyle(
                                    color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await memberService.deleteMember(member.id);
                    }
                  },
                ),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────
          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Bottom: Email + Contact ───────────────────────
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
                    member.email,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Contacting ${member.name}...'),
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