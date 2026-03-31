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
  Stream<List<Member>> getMembers() async* {
    final teamId = await _getTeamId();
    if (teamId == null) {
      yield [];
      return;
    }
    yield* _collection
        .where('teamId', isEqualTo: teamId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Member.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ── Add member with teamId ───────────────────────────
  Future<void> addMember(Member member) async {
    await _collection.add(member.toMap());
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