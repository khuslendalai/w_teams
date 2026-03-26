class Member {
  final String id;
  final String name;
  final String role;
  final String email;

  Member({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
  });

  factory Member.fromFirestore(Map<String, dynamic> data, String id) {
    return Member(
      id: id,
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'email': email,
      'createdAt': DateTime.now(),
    };
  }
}


