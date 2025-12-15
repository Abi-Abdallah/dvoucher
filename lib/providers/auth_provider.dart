import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../models/admin.dart';
import '../models/user.dart';
import '../services/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  AppUser? _currentUser;
  Admin? _currentAdmin;
  bool _isAdmin = false;

  AppUser? get currentUser => _currentUser;
  Admin? get currentAdmin => _currentAdmin;
  bool get isAdmin => _isAdmin;
  bool get notificationsEnabled => _currentUser?.notificationsEnabled ?? true;

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final existing = await _databaseHelper.getUserByEmail(normalizedEmail);
      if (existing != null) {
        return 'Email already registered. Please log in.';
      }

      final user = AppUser(
        name: name.trim(),
        email: normalizedEmail,
        password: password,
      );

      final id = await _databaseHelper.insertUser(user);
      _currentUser = user.copyWith(id: id);
      _isAdmin = false;
      notifyListeners();
      return null;
    } catch (error) {
      return 'Unable to create account. Please try again.';
    }
  }

  Future<String?> loginUser(String email, String password) async {
    final user = await _databaseHelper.validateUser(
      email.trim().toLowerCase(),
      password.trim(),
    );
    if (user == null) {
      return 'Invalid credentials. Please check and try again.';
    }
    _currentUser = user;
    _currentAdmin = null;
    _isAdmin = false;
    notifyListeners();
    return null;
  }

  /// Sign up a new admin
  Future<String?> signUpAdmin({
    required String name,
    required String email,
    required String password,
   }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final existing = await _databaseHelper.getAdminByEmail(normalizedEmail);
      if (existing != null) {
        return 'Email already registered. Please log in.';
      }

      final admin = Admin(
        name: name.trim(),
        email: normalizedEmail,
        password: password.trim(),
      );

      final id = await _databaseHelper.insertAdmin(admin);
      _currentAdmin = admin.copyWith(id: id);
      _currentUser = null;
      _isAdmin = true;
      notifyListeners();
      return null;
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        return 'Email already registered. Please log in.';
      }
      return 'Database error: ${error.toString()}';
    } catch (error) {
      return 'Unable to create admin account. Please try again.';
    }
  }

  /// Login admin using SQLite credentials
  Future<String?> loginAdmin(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();
    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      return 'Email and password are required.';
    }
    final admin = await _databaseHelper.validateAdmin(normalizedEmail, normalizedPassword);
    if (admin == null) {
      return 'Invalid credentials. Please check and try again.';
    }
    _currentAdmin = admin;
    _currentUser = null;
    _isAdmin = true;
    notifyListeners();
    return null;
  }

  void logout() {
    _currentUser = null;
    _currentAdmin = null;
    _isAdmin = false;
    notifyListeners();
  }

  Future<String?> updateUserProfile({
    String? name,
    String? email,
    String? password,
    bool? notificationsEnabled,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return 'No user logged in.';
    }

    final updated = user.copyWith(
      name: name?.trim().isNotEmpty == true ? name!.trim() : user.name,
      email: email?.trim().isNotEmpty == true
          ? email!.trim().toLowerCase()
          : user.email,
      password: password != null && password.isNotEmpty
          ? password
          : user.password,
      notificationsEnabled: notificationsEnabled ?? user.notificationsEnabled,
    );

    try {
      await _databaseHelper.updateUser(updated);
      _currentUser = updated;
      notifyListeners();
      return null;
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        return 'Email already registered. Please choose another.';
      }
      return 'Database error. Please try again.';
    } catch (error) {
      return 'Unable to update profile at this time.';
    }
  }

  Future<void> setNotificationPreference(bool enabled) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }
    await _databaseHelper.setUserNotificationsEnabled(
      userId: user.id!,
      enabled: enabled,
    );
    _currentUser = user.copyWith(notificationsEnabled: enabled);
    notifyListeners();
  }
}

