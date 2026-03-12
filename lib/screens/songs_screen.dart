import 'package:flutter/material.dart';

class SongsScreen extends StatelessWidget {
  const SongsScreen({super.key});

  final List<Map<String, String>> songs = const [
    {'title': 'Gratitude', 'artist': 'Brandon Lake', 'key': 'Key of B'},
    {'title': 'Worthy of It All', 'artist': 'CeCe Winans', 'key': 'Key of D'},
    {'title': 'Firm Foundation', 'artist': 'Cody Carnes', 'key': 'Key of Bb'},
    {'title': 'Goodness of God', 'artist': 'Bethel Music', 'key': 'Key of E'},
    {'title': 'Way Maker', 'artist': 'Sinach', 'key': 'Key of G'},
    {'title': 'What a Beautiful Name', 'artist': 'Hillsong', 'key': 'Key of D'},
    {'title': 'Oceans', 'artist': 'Hillsong United', 'key': 'Key of D'},
    {'title': 'Build My Life', 'artist': 'Housefires', 'key': 'Key of E'},
  ];

  @override
  Widget build(BuildContext context) {
    const appColor = Color.fromARGB(255, 1, 4, 104);

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
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Number badge
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

              // Title & Artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song['title']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                      '${song['artist']} • ${song['key']}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Chords badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Chords',
                  style: TextStyle(
                      fontSize: 11,
                      color: appColor,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}