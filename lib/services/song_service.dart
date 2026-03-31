import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song_model.dart';

class SongService {
  final _collection = FirebaseFirestore.instance.collection('setlists');
  final _users = FirebaseFirestore.instance.collection('users');

  // ── Get current user's teamId ────────────────────────
  Future<String?> _getTeamId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['teamId'];
  }

  // ── Real-time stream ordered by song order ───────────
  Stream<List<Song>> getSongs() async* {
    final teamId = await _getTeamId();
    if (teamId == null) {
      yield [];
      return;
    }
    yield* _collection
        .where('teamId', isEqualTo: teamId)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Song.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ── Add song ─────────────────────────────────────────
  Future<void> addSong(Song song) async {
    await _collection.add(song.toMap());
  }

  // ── Update song ──────────────────────────────────────
  Future<void> updateSong(String id, {
    required String title,
    required String artist,
    required String key,
    required int bpm,
    required String notes,
  }) async {
    await _collection.doc(id).update({
      'title': title,
      'artist': artist,
      'key': key,
      'bpm': bpm,
      'notes': notes,
    });
  }

  // ── Update order after drag and drop ─────────────────
  Future<void> updateOrder(List<Song> songs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < songs.length; i++) {
      batch.update(
        _collection.doc(songs[i].id),
        {'order': i},
      );
    }
    await batch.commit();
  }

  // ── Delete song ──────────────────────────────────────
  Future<void> deleteSong(String id) async {
    await _collection.doc(id).delete();
  }

  // ── Get next order number ────────────────────────────
  Future<int> getNextOrder() async {
    final teamId = await _getTeamId();
    if (teamId == null) return 0;
    final snapshot = await _collection
        .where('teamId', isEqualTo: teamId)
        .get();
    return snapshot.docs.length;
  }
}