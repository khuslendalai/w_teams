import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/song_service.dart';
import '../services/team_service.dart';

class AddSongScreen extends StatefulWidget {
  const AddSongScreen({super.key});

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  static const appColor = Color.fromARGB(255, 1, 4, 104);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _bpmController = TextEditingController();
  final _notesController = TextEditingController();
  final _songService = SongService();
  final _teamService = TeamService();

  String _selectedKey = 'C';
  bool _isSaving = false;

  final List<String> _keys = const [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B',
    'Cm', 'C#m', 'Dm', 'D#m', 'Em', 'Fm',
    'F#m', 'Gm', 'G#m', 'Am', 'A#m', 'Bm',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _bpmController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Save Song ─────────────────────────────────────────
  Future<void> _saveSong() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final teamId = await _teamService.getCurrentTeamId();
      if (teamId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are not part of a team yet.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final nextOrder = await _songService.getNextOrder();

      final song = Song(
        id: '',
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        key: _selectedKey,
        bpm: int.tryParse(_bpmController.text.trim()) ?? 0,
        order: nextOrder,
        notes: _notesController.text.trim(),
        teamId: teamId,
      );

      await _songService.addSong(song);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Song added to setlist!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: appColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Add Song',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Icon ──────────────────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: appColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_note_outlined,
                    color: appColor,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Section Label ──────────────────────────
              const Text(
                'SONG DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),

              // ── Form Card ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [

                    // ── Title ────────────────────────────
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        label: 'Song Title',
                        icon: Icons.music_note_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a song title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Artist ───────────────────────────
                    TextFormField(
                      controller: _artistController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        label: 'Artist / Band',
                        icon: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an artist name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Key + BPM Row ─────────────────────
                    Row(
                      children: [

                        // Key dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedKey,
                            decoration: _inputDecoration(
                              label: 'Key',
                              icon: Icons.piano_outlined,
                            ),
                            items: _keys
                                .map((k) => DropdownMenuItem(
                                      value: k,
                                      child: Text(k),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedKey = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // BPM field
                        Expanded(
                          child: TextFormField(
                            controller: _bpmController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                              label: 'BPM',
                              icon: Icons.speed_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter BPM';
                              }
                              final bpm = int.tryParse(value.trim());
                              if (bpm == null || bpm <= 0 || bpm > 300) {
                                return 'Invalid BPM';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Notes ────────────────────────────
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        label: 'Notes (optional)',
                        icon: Icons.notes_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Save Button ────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSong,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: appColor.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_outlined, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Add to Setlist',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Input Decoration Helper ───────────────────────────
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: appColor, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: appColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      labelStyle: const TextStyle(fontSize: 14),
    );
  }
}