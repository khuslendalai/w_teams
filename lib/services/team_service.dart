import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/team_model.dart';

class TeamService {
  final _teams = FirebaseFirestore.instance.collection('teams');
  final _users = FirebaseFirestore.instance.collection('users');
  final _members = FirebaseFirestore.instance.collection('members');

  // ── Generate a random 6-char code like AB12CD ──────────
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // ── Create a new team, returns the team ────────────────
  Future<Team> createTeam(String name) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final code = _generateCode();

    final docRef = await _teams.add({
      'name': name,
      'inviteCode': code,
      'createdBy': uid,
      'createdAt': DateTime.now(),
    });

    // Save team data to current user's doc
    await _users.doc(uid).set({
      'teamId': docRef.id,
      'teamName': name,
      'role': 'admin',
    }, SetOptions(merge: true));

    // Add current user as team member in members collection
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final email = currentUser.email ?? '';
      final displayName = currentUser.displayName?.trim();
      final nameToUse = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : email.isNotEmpty
              ? email.split('@').first
              : 'Team Member';

      final existingMember = await _members
          .where('teamId', isEqualTo: docRef.id)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingMember.docs.isEmpty) {
        await _members.add({
          'name': nameToUse,
          'role': 'admin',
          'email': email,
          'teamId': docRef.id,
          'createdAt': DateTime.now(),
        });
      }
    }

    return Team(
      id: docRef.id,
      name: name,
      inviteCode: code,
      createdBy: uid,
    );
  }

  // ── Join a team using invite code ──────────────────────
  Future<bool> joinTeam(String code) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Find team with matching code
    final query = await _teams
        .where('inviteCode', isEqualTo: code.toUpperCase().trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;

    final teamId = query.docs.first.id;

    // Link user to team
    // Also store teamName so Settings can display the team immediately.
    final team = await getTeam(teamId);
    final teamName = team?.name ?? '';

    await _users.doc(uid).set({
      'teamId': teamId,
      'teamName': teamName,
      'role': 'member',
    }, SetOptions(merge: true));

    // Add user as member to team if not already present
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final email = currentUser.email ?? '';
      final displayName = currentUser.displayName?.trim();
      final nameToUse = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : email.isNotEmpty
              ? email.split('@').first
              : 'Team Member';

      final existingMember = await _members
          .where('teamId', isEqualTo: teamId)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingMember.docs.isEmpty) {
        await _members.add({
          'name': nameToUse,
          'role': 'member',
          'email': email,
          'teamId': teamId,
          'createdAt': DateTime.now(),
        });
      }
    }

    return true;
  }

  // ── Get current user's teamId ──────────────────────────
  Future<String?> getCurrentTeamId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['teamId']?.toString();
  }

  // ── Get current user's role ───────────────────────────
  Future<String?> getCurrentUserRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role']?.toString();
  }

  // ── Update current user's role (for local user role edits) ──
  Future<void> updateCurrentUserRole(String role) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _users.doc(uid).update({'role': role});
  }

  // ── Leave current team ─────────────────────────────────
  Future<void> leaveTeam() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final userDoc = await _users.doc(uid).get();
    if (!userDoc.exists) return;

    final data = userDoc.data();
    final teamId = data?['teamId']?.toString();
    final role = data?['role']?.toString();

    if (teamId == null || teamId.isEmpty) return;

    // If admin, prevent leaving while members remain (simple policy)
    if (role == 'admin') {
      final memberSnapshot = await _members.where('teamId', isEqualTo: teamId).get();
      if (memberSnapshot.docs.length > 1) {
        throw Exception('Admin cannot leave team while other members exist. Transfer admin first.');
      }

      // Delete the team if admin leaves last (optional)
      await _teams.doc(teamId).delete();
    }

    // Remove member record(s) for this user on this team
    final email = user.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      final memberDocs = await _members
          .where('teamId', isEqualTo: teamId)
          .where('email', isEqualTo: email)
          .get();
      for (final doc in memberDocs.docs) {
        await doc.reference.delete();
      }
    }

    // Clear user's team association
    await _users.doc(uid).update({
      'teamId': null,
      'teamName': null,
      'role': null,
    });
  }

  // ── Get team by id ─────────────────────────────────────
  Future<Team?> getTeam(String teamId) async {
    final doc = await _teams.doc(teamId).get();
    if (!doc.exists) return null;
    return Team.fromFirestore(doc.data()!, doc.id);
  }
}