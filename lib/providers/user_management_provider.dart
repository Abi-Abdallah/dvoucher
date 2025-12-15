import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/database_helper.dart';

class UserManagementProvider extends ChangeNotifier {
  UserManagementProvider();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<AppUser> _users = [];
  bool _isLoading = false;
  bool _includeInactive = true;
  Map<int, int> _redeemedCounts = {};

  List<AppUser> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  bool get includeInactive => _includeInactive;
  int redeemedCountFor(int? userId) => userId == null ? 0 : (_redeemedCounts[userId] ?? 0);

  Future<void> loadUsers({bool? includeInactive}) async {
    if (includeInactive != null) {
      _includeInactive = includeInactive;
    }
    _isLoading = true;
    notifyListeners();
    _users = await _databaseHelper.getUsers(includeInactive: _includeInactive);
    _redeemedCounts = await _databaseHelper.getRedeemedCountByUser();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleUserActive({required int userId, required bool isActive}) async {
    await _databaseHelper.setUserActiveStatus(userId: userId, isActive: isActive);
    await loadUsers(includeInactive: _includeInactive);
  }

  int get activeUserCount =>
      _users.where((user) => user.isActive).length;
}
