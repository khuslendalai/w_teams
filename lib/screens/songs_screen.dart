import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../screens/setlist_screen.dart';
import '../services/song_service.dart';
import '../services/team_service.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final TeamService _teamService = TeamService();
  final SongService _songService = SongService();
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

  Stream<List<Song>> _setlistSongsStream() {
    return _songService.getSongs();
  }

  Future<void> _showSongDialog({Song? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final artistController = TextEditingController(
      text: existing?.artist ?? '',
    );
    final keyController = TextEditingController(text: existing?.key ?? '');
    final bpmController = TextEditingController(
      text: existing?.bpm.toString() ?? '',
    );
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
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: artistController,
                  decoration: const InputDecoration(labelText: 'Artist'),
                ),
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(labelText: 'Key'),
                ),
                TextField(
                  controller: bpmController,
                  decoration: const InputDecoration(labelText: 'BPM'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and artist are required')),
      );
      return;
    }

    if (existing == null) {
      final nextOrder = await _songService.getNextOrder();
      final song = Song(
        id: '',
        title: title,
        artist: artist,
        key: key,
        bpm: bpm,
        order: nextOrder,
        notes: notes,
        teamId: _teamId,
      );
      await _songService.addSong(song);
    } else {
      await _songService.updateSong(
        existing.id,
        title: title,
        artist: artist,
        key: key,
        bpm: bpm,
        notes: notes,
      );
    }
  }

  Future<void> _deleteSong(Song song) async {
    await FirebaseFirestore.instance.collection('songs').doc(song.id).delete();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Song deleted')));
    }
  }

  Future<void> _createSetlist() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SetlistScreen()),
    );
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
      appBar: AppBar(
        title: const Text(
          'Songs & Setlists',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: appColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: _createSetlist,
            tooltip: 'Create a setlist',
          ),
        ],
      ),
      body: StreamBuilder<List<Song>>(
        stream: _setlistSongsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading songs: ${snapshot.error}'),
            );
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
                  const Text(
                    'No setlist of songs available for now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add songs and create a setlist to start your song planning.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColor,
                        ),
                        icon: const Icon(Icons.playlist_add),
                        label: const Text(
                          'Create Setlist',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _createSetlist,
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColor,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Add Song',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _showSongDialog(),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          final setlistByEvent = <String, List<Song>>{};
          for (final song in songs) {
            final groupKey = song.eventName.isNotEmpty
                ? song.eventName
                : 'General Setlist';
            setlistByEvent.putIfAbsent(groupKey, () => []).add(song);
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Setlist',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...setlistByEvent.entries.expand((entry) {
                final eventName = entry.key;
                final eventSongs = entry.value;
                return [
                  Text(
                    eventName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...eventSongs.map(
                    (song) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(song.title),
                      subtitle: Text(
                        '${song.artist} • ${song.key}${song.bpm > 0 ? ' • ${song.bpm} BPM' : ''}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ];
              }).toList(),

              const Divider(height: 36),
              const Text(
                'All songs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...songs.map((song) {
                final index = songs.indexOf(song);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
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
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: appColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${song.artist} • ${song.key}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                            if (song.bpm > 0)
                              Text(
                                'BPM: ${song.bpm}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            if (song.notes.isNotEmpty)
                              Text(
                                song.notes,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: appColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showSongDialog(),
      ),
    );
  }
}
