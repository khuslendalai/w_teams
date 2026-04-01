import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/member_model.dart';

class MemberService {
  final _collection = FirebaseFirestore.instance.collection('members');
  final _users = FirebaseFirestore.instance.collection('users');

  // ── Get current user's teamId ────────────────────────
  Future<String?> _getTeamId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['teamId'];
  }

  // ── Real-time stream filtered by teamId ──────────────
  Stream<List<Member>> getMembers({String? teamId}) async* {
    final resolvedTeamId = teamId ?? await _getTeamId();
    if (resolvedTeamId == null) {
      yield [];
      return;
    }

    // Don't require a composite index (teamId + createdAt) by using where-only.
    // Sorting can be done on the client if needed.
    yield* _collection
        .where('teamId', isEqualTo: resolvedTeamId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Member.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ── Add or merge member with teamId ──────────────────
  Future<void> addMember(Member member) async {
    final query = await _collection
        .where('teamId', isEqualTo: member.teamId)
        .where('email', isEqualTo: member.email.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final existingRole = (doc.data()['role'] ?? '').toString();
      final newRoles = <String>{}
        ..addAll(existingRole
            .split(',')
            .map((r) => r.trim())
            .where((r) => r.isNotEmpty))
        ..addAll(member.role
            .split(',')
            .map((r) => r.trim())
            .where((r) => r.isNotEmpty));
      final mergedRole = newRoles.join(', ');

      await _collection.doc(doc.id).update({
        'name': member.name,
        'role': mergedRole,
        'email': member.email.trim().toLowerCase(),
      });
    } else {
      await _collection.add(member.toMap());
    }
  }

  // ── Update member ────────────────────────────────────
  Future<void> updateMember(
    String id, {
    required String name,
    required String role,
    required String email,
  }) async {
    await _collection.doc(id).update({
      'name': name,
      'role': role,
      'email': email,
    });
  }

  // ── Delete member ────────────────────────────────────
  Future<void> deleteMember(String id) async {
    await _collection.doc(id).delete();
  }
}