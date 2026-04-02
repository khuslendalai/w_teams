import 'package:flutter/material.dart';

import '../models/song_model.dart';
import '../screens/setlist_screen.dart';
import '../services/song_service.dart';
import '../services/team_service.dart';

// ─────────────────────────────────────────────────────────────
//  SongsScreen
// ─────────────────────────────────────────────────────────────

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  static const _appColor = Color.fromARGB(255, 1, 4, 104);

  final TeamService _teamService = TeamService();
  final SongService _songService = SongService();

  String? _teamId;
  bool _loading = true;

  // Search
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTeam();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Team ─────────────────────────────────────────────────
  Future<void> _loadTeam() async {
    final teamId = await _teamService.getCurrentTeamId();
    if (mounted) {
      setState(() {
        _teamId = teamId;
        _loading = false;
      });
    }
  }

  // ── Stream ───────────────────────────────────────────────
  Stream<List<Song>> _songsStream() => _songService.getSongs();

  // ── Filter ───────────────────────────────────────────────
  List<Song> _filter(List<Song> songs) {
    if (_searchQuery.isEmpty) return songs;
    return songs.where((s) {
      return s.title.toLowerCase().contains(_searchQuery) ||
          s.artist.toLowerCase().contains(_searchQuery) ||
          s.key.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // ── Add / Edit Dialog ────────────────────────────────────
  Future<void> _showSongDialog({Song? existing}) async {
    final titleC     = TextEditingController(text: existing?.title ?? '');
    final artistC    = TextEditingController(text: existing?.artist ?? '');
    final keyC       = TextEditingController(text: existing?.key ?? '');
    final bpmC       = TextEditingController(
        text: (existing?.bpm ?? 0) > 0 ? existing!.bpm.toString() : '');
    final notesC     = TextEditingController(text: existing?.notes ?? '');

    String? errorMsg;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDlg) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(
              existing == null ? 'Add Song' : 'Edit Song',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _appColor),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMsg != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(errorMsg!,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 13)),
                    ),
                  _dialogField(titleC,  'Title *',  Icons.music_note),
                  const SizedBox(height: 10),
                  _dialogField(artistC, 'Artist *', Icons.person_outline),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _dialogField(keyC, 'Key', Icons.piano)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _dialogField(bpmC, 'BPM',
                              Icons.speed,
                              inputType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _dialogField(notesC, 'Notes', Icons.notes,
                      maxLines: 3),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _appColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (titleC.text.trim().isEmpty ||
                      artistC.text.trim().isEmpty) {
                    setDlg(() => errorMsg =
                        'Title and Artist are required.');
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );

    if (saved != true || _teamId == null) return;

    final title     = titleC.text.trim();
    final artist    = artistC.text.trim();
    final key       = keyC.text.trim();
    final bpm       = int.tryParse(bpmC.text.trim()) ?? 0;
    final notes     = notesC.text.trim();

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
        teamId: _teamId ?? '',
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

  // ── Delete ───────────────────────────────────────────────
  Future<void> _deleteSong(Song song) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Song'),
        content: Text(
            'Remove "${song.title}" from your song library? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _songService.deleteSong(song.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${song.title}" deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Navigate to Setlist ──────────────────────────────────
  void _createSetlist() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SetlistScreen()));
  }

  // ─────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (_teamId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_off, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Join or create a team to manage songs',
                  style: TextStyle(fontSize: 15)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _appColor,
                    foregroundColor: Colors.white),
                onPressed: () {},
                child: const Text('Go to Teams'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Songs & Setlists',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _appColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Create setlist',
            onPressed: _createSetlist,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _appColor,
        foregroundColor: Colors.white,
        tooltip: 'Add song',
        onPressed: () => _showSongDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Song>>(
        stream: _songsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(error: '${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allSongs = snapshot.data ?? [];

          if (allSongs.isEmpty) {
            return _EmptyState(
              onAddSong: () => _showSongDialog(),
              onCreateSetlist: _createSetlist,
            );
          }

          final filtered = _filter(allSongs);

          return Column(
            children: [
              // ── Search bar ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by title or artist…',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // ── Result count hint ─────────────────────
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filtered.length} result${filtered.length == 1 ? '' : 's'} for "$_searchQuery"',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ),

              // ── Song list ─────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text(
                              'No songs match "$_searchQuery"',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _SongCard(
                          song: filtered[i],
                          index: i,
                          onEdit: () => _showSongDialog(existing: filtered[i]),
                          onDelete: () => _deleteSong(filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Dialog field helper ──────────────────────────────────
  static Widget _dialogField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: _appColor),
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _appColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Song Card
// ─────────────────────────────────────────────────────────────

class _SongCard extends StatelessWidget {
  final Song song;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SongCard({
    required this.song,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  static const _appColor = Color.fromARGB(255, 1, 4, 104);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Index badge
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
                      color: _appColor,
                      fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (song.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      song.notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Action chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _ActionChip(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        onTap: onEdit,
                        color: Colors.blueGrey,
                      ),
                      _ActionChip(
                        label: 'Delete',
                        icon: Icons.delete_outline,
                        onTap: onDelete,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final parts = <String>[];
    parts.add(song.artist);
    if (song.key.isNotEmpty) parts.add('Key of ${song.key}');
    if (song.bpm > 0) parts.add('${song.bpm} BPM');
    return parts.join(' • ');
  }
}

// ─────────────────────────────────────────────────────────────
//  Action Chip
// ─────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Empty & Error States
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddSong;
  final VoidCallback onCreateSetlist;

  const _EmptyState(
      {required this.onAddSong, required this.onCreateSetlist});

  static const _appColor = Color.fromARGB(255, 1, 4, 104);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.queue_music, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No songs yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add songs to your library, then create a setlist for your next service.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _appColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Song'),
                  onPressed: onAddSong,
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _appColor,
                      side: const BorderSide(color: _appColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  icon: const Icon(Icons.playlist_add, size: 16),
                  label: const Text('Create Setlist'),
                  onPressed: onCreateSetlist,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Failed to load songs',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(error,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}