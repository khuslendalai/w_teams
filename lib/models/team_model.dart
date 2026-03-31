class Team {
  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;

  Team({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
  });

  factory Team.fromFirestore(Map<String, dynamic> data, String id) {
    return Team(
      id: id,
      name: data['name'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'createdAt': DateTime.now(),
    };
  }
}