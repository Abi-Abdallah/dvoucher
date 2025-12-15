import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  int? _userId;
  bool _isAdminFeed = false;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;
  bool get isAdminFeed => _isAdminFeed;

  Future<void> setUser(int userId) async {
    _userId = userId;
    _isAdminFeed = false;
    await loadNotifications();
  }

  Future<void> clearUser() async {
    _userId = null;
    _notifications = [];
    _isAdminFeed = false;
    notifyListeners();
  }

  Future<void> loadNotifications({bool onlyUnread = false}) async {
    _isLoading = true;
    notifyListeners();
    _notifications = await _databaseHelper.getNotifications(
      userId: _isAdminFeed ? null : _userId,
      onlyUnread: onlyUnread,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int notificationId) async {
    await _databaseHelper.markNotificationRead(notificationId);
    _notifications = _notifications
        .map((notification) => notification.id == notificationId
            ? notification.copyWith(isRead: true)
            : notification)
        .toList();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (_userId == null) {
      return;
    }
    await _databaseHelper.markAllNotificationsRead(_userId!);
    _notifications =
        _notifications.map((e) => e.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  Future<void> addNotification(AppNotification notification) async {
    await _databaseHelper.insertNotification(
      userId: notification.userId,
      title: notification.title,
      body: notification.body,
      type: notification.type,
    );
    if (_userId == null) {
      return;
    }
    await loadNotifications();
  }

  Future<void> loadAllNotificationsForAdmin() async {
    _isAdminFeed = true;
    await loadNotifications();
  }

  Future<String?> sendNotificationToAll({
    required String title,
    required String body,
    String? type,
  }) async {
    try {
      await _databaseHelper.insertNotificationForAllUsers(
        title: title,
        body: body,
        type: type,
      );
      await NotificationService.instance
          .showCustomNotification(title: title, body: body);
      await loadAllNotificationsForAdmin();
      return null;
    } catch (_) {
      return 'Unable to send notification.';
    }
  }
}
