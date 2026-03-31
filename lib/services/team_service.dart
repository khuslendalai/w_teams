import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/team_model.dart';

class TeamService {
  final _teams = FirebaseFirestore.instance.collection('teams');
  final _users = FirebaseFirestore.instance.collection('users');

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

    // Save teamId to current user's doc
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

    // Find team with matching code
    final query = await _teams
        .where('inviteCode', isEqualTo: code.toUpperCase().trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;

    final teamId = query.docs.first.id;

    // Link user to team
    await _users.doc(uid).set({
      'teamId': teamId,
      'role': 'member',
    }, SetOptions(merge: true));

    return true;
  }

  // ── Get current user's teamId ──────────────────────────
  Future<String?> getCurrentTeamId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['teamId'];
  }

  // ── Get team by id ─────────────────────────────────────
  Future<Team?> getTeam(String teamId) async {
    final doc = await _teams.doc(teamId).get();
    if (!doc.exists) return null;
    return Team.fromFirestore(doc.data()!, doc.id);
  }
}