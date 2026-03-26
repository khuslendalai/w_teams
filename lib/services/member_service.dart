import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';

class MemberService {
  final _collection = FirebaseFirestore.instance.collection('members');

  // Real-time stream of all members
  Stream<List<Member>> getMembers() {
    return _collection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Member.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Add a new member
  Future<void> addMember(Member member) async {
    await _collection.add(member.toMap());
  }

  // Delete a member
  Future<void> deleteMember(String id) async {
    await _collection.doc(id).delete();
  }
}