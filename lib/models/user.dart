class AppUser {
  String id;
  String name;
  String role; // 'admin' or 'normal'

  AppUser({required this.id, required this.name, required this.role});

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role,
      };

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        id: id,
        name: map['name'],
        role: map['role'],
      );
}
