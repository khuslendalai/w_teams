class Song {
  final String id;
  final String title;
  final String artist;
  final String key;
  final int bpm;
  final int order;
  final String notes;
  final String teamId;
  final String eventName;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.key,
    required this.bpm,
    required this.order,
    required this.notes,
    required this.teamId,
    this.eventName = '',
  });

  factory Song.fromFirestore(Map<String, dynamic> data, String id) {
    return Song(
      id: id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      key: data['key'] ?? '',
      bpm: data['bpm'] ?? 0,
      order: data['order'] ?? 0,
      notes: data['notes'] ?? '',
      teamId: data['teamId'] ?? '',
      eventName: data['eventName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'key': key,
      'bpm': bpm,
      'order': order,
      'notes': notes,
      'teamId': teamId,
      'eventName': eventName,
      'createdAt': DateTime.now(),
    };
  }

  // For reordering — copy with new order
  Song copyWith({int? order}) {
    return Song(
      id: id,
      title: title,
      artist: artist,
      key: key,
      bpm: bpm,
      order: order ?? this.order,
      notes: notes,
      teamId: teamId,
    );
  }
}