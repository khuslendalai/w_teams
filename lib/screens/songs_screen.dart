import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/team_service.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final TeamService _teamService = TeamService();
  String? _teamId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    final teamId = await _teamService.getCurrentTeamId();
    if (mounted) {
      setState(() {
        _teamId = teamId;
        _loading = false;
      });
    }
  }

  Stream<List<Song>> _songsStream() {
    if (_teamId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('songs')
        .where('teamId', isEqualTo: _teamId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Song.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> _showSongDialog({Song? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final artistController = TextEditingController(text: existing?.artist ?? '');
    final keyController = TextEditingController(text: existing?.key ?? '');
    final bpmController = TextEditingController(text: existing?.bpm.toString() ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Song' : 'Edit Song'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: artistController, decoration: const InputDecoration(labelText: 'Artist')),
                TextField(controller: keyController, decoration: const InputDecoration(labelText: 'Key')),
                TextField(controller: bpmController, decoration: const InputDecoration(labelText: 'BPM'), keyboardType: TextInputType.number),
                TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        );
      },
    );

    if (saved != true || _teamId == null) return;

    final bpm = int.tryParse(bpmController.text.trim()) ?? 0;
    final title = titleController.text.trim();
    final artist = artistController.text.trim();
    final key = keyController.text.trim();
    final notes = notesController.text.trim();

    if (title.isEmpty || artist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and artist are required')));
      return;
    }

    if (existing == null) {
      final songsSnapshot = await FirebaseFirestore.instance
          .collection('songs')
          .where('teamId', isEqualTo: _teamId)
          .orderBy('order', descending: true)
          .limit(1)
          .get();
      final nextOrder = (songsSnapshot.docs.isEmpty ? 0 : (songsSnapshot.docs.first.data()['order'] as int? ?? 0) + 1);

      await FirebaseFirestore.instance.collection('songs').add({
        'title': title,
        'artist': artist,
        'key': key,
        'bpm': bpm,
        'order': nextOrder,
        'notes': notes,
        'teamId': _teamId,
        'createdAt': DateTime.now(),
      });
    } else {
      await FirebaseFirestore.instance.collection('songs').doc(existing.id).update({
        'title': title,
        'artist': artist,
        'key': key,
        'bpm': bpm,
        'notes': notes,
        'updatedAt': DateTime.now(),
      });
    }
  }

  Future<void> _deleteSong(Song song) async {
    await FirebaseFirestore.instance.collection('songs').doc(song.id).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teamId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Join or create a team to manage songs'),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: appColor),
              onPressed: () {},
              child: const Text('Go to Teams'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<List<Song>>(
        stream: _songsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading songs: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final songs = snapshot.data ?? [];
          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No songs yet. Add your first song.'),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: appColor),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Song'),
                    onPressed: () => _showSongDialog(),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final song = songs[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: appColor))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(song.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                          const SizedBox(height: 3),
                          Text('${song.artist} • ${song.key}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          if (song.bpm > 0) Text('BPM: ${song.bpm}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          if (song.notes.isNotEmpty) Text(song.notes, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black54),
                      onPressed: () => _showSongDialog(existing: song),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteSong(song),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: appColor,
        child: const Icon(Icons.add),
        onPressed: () => _showSongDialog(),
      ),
    );
  }
}
