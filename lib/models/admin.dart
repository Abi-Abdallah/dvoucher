/// Admin model for storing admin credentials in SQLite
class Admin {
  final int? id;
  final String name;
  final String email;
  final String password;

  const Admin({
    this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  Admin copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
  }) {
    return Admin(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'admin_id': id,
      'name': name,
      'email': email,
      'password': password,
    };
  }

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['admin_id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
}

