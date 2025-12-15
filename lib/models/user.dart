class AppUser {
  final int? id;
  final String name;
  final String email;
  final String password;
  final bool notificationsEnabled;
  final bool isActive;

  const AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.notificationsEnabled = true,
    this.isActive = true,
  });

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    bool? notificationsEnabled,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': id,
      'name': name,
      'email': email,
      'password': password,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['user_id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      notificationsEnabled:
          (map['notifications_enabled'] as int? ?? 1) == 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}

