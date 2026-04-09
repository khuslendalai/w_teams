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
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // ── Create a new team ──────────────────────────────────
  Future<Team> createTeam(String name) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final code = _generateCode();

    final docRef = await _teams.add({
      'name': name,
      'inviteCode': code,
      'createdBy': uid,
      'createdAt': DateTime.now(),
    });

    await _users.doc(uid).set({
      'teamId': docRef.id,
      'role': 'admin',
    }, SetOptions(merge: true));

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
    final email =
        FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';

    final query = await _teams
        .where('inviteCode', isEqualTo: code.toUpperCase().trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;

    final teamId = query.docs.first.id;

    // 1 — Link user to team in users collection
    await _users.doc(uid).set({
      'teamId': teamId,
      'role': 'member',
    }, SetOptions(merge: true));

    // 2 — Check if member doc already exists for this email + teamId
    final existingMember = await _members
        .where('teamId', isEqualTo: teamId)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    // 3 — Only create if not already there
    if (existingMember.docs.isEmpty) {
      final displayName =
          FirebaseAuth.instance.currentUser?.displayName;
      final emailPrefix = email.split('@')[0];
      final name =
          (displayName != null && displayName.isNotEmpty)
              ? displayName
              : emailPrefix;

      await _members.add({
        'name': name,
        'email': email,
        'role': 'Member',
        'teamId': teamId,
        'createdAt': DateTime.now(),
      });
    }

    return true;
  }

  // ── Leave current team ─────────────────────────────────
  Future<void> leaveTeam() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final email =
        FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (uid == null) return;

    // 1 — Get the user's current teamId before removing it
    final userDoc = await _users.doc(uid).get();
    final teamId = userDoc.data()?['teamId']?.toString();

    // 2 — Remove teamId and role from users doc
    await _users.doc(uid).update({
      'teamId': FieldValue.delete(),
      'role': FieldValue.delete(),
    });

    // 3 — Delete their member record(s) from members collection
    if (teamId != null && email != null) {
      final memberQuery = await _members
          .where('teamId', isEqualTo: teamId)
          .where('email', isEqualTo: email)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in memberQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // ── Get current user's teamId ──────────────────────────
  Future<String?> getCurrentTeamId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['teamId'];
  }

  // ── Get current user's role ────────────────────────────
  Future<String?> getCurrentUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role'];
  }

  // ── Update current user's role ─────────────────────────
  Future<void> updateCurrentUserRole(String role) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _users.doc(uid).update({'role': role});
  }

  // ── Get team by id ─────────────────────────────────────
  Future<Team?> getTeam(String teamId) async {
    final doc = await _teams.doc(teamId).get();
    if (!doc.exists) return null;
    return Team.fromFirestore(doc.data()!, doc.id);
  }
}