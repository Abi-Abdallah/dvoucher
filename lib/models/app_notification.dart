class AppNotification {
  final int? id;
  final int? userId;
  final String title;
  final String body;
  final String? type;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    this.id,
    this.userId,
    required this.title,
    required this.body,
    this.type,
    required this.createdAt,
    this.isRead = false,
  });

  AppNotification copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    String? type,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notification_id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['notification_id'] as int?,
      userId: map['user_id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isRead: (map['is_read'] as int? ?? 0) == 1,
    );
  }
}
