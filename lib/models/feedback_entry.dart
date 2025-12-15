class FeedbackEntry {
  final int? id;
  final int userId;
  final int voucherId;
  final int rating;
  final String comment;
  final DateTime date;
  final String userName;

  const FeedbackEntry({
    this.id,
    required this.userId,
    required this.voucherId,
    required this.rating,
    required this.comment,
    required this.date,
    required this.userName,
  });

  Map<String, dynamic> toMap() {
    return {
      'feedback_id': id,
      'user_id': userId,
      'voucher_id': voucherId,
      'rating': rating,
      'comment': comment,
      'date': date.toIso8601String(),
    };
  }

  factory FeedbackEntry.fromMap(Map<String, dynamic> map) {
    return FeedbackEntry(
      id: map['feedback_id'] as int?,
      userId: map['user_id'] as int,
      voucherId: map['voucher_id'] as int,
      rating: (map['rating'] as num).toInt(),
      comment: map['comment'] as String,
      date: DateTime.parse(map['date'] as String),
      userName: map['user_name'] as String? ?? '',
    );
  }
}

