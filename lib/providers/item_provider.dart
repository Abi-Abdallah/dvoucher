import 'package:flutter/material.dart';

import '../models/item.dart';
import '../services/database_helper.dart';

class ItemProvider extends ChangeNotifier {
  ItemProvider();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Item> _items = [];
  bool _isLoading = false;
  int? _adminId;

  List<Item> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  Future<void> setAdmin(int adminId) async {
    _adminId = adminId;
    await loadItems(includeInactive: true);
  }

  Future<void> loadItems({bool includeInactive = true}) async {
    if (_adminId == null) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    _items = await _databaseHelper.getItems(
      adminId: _adminId!,
      includeInactive: includeInactive,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> addItem(Item item) async {
    if (_adminId == null) {
      return 'Admin context missing. Please log in again.';
    }
    try {
      await _databaseHelper.insertItem(item.copyWith(adminId: _adminId));
      await loadItems();
      return null;
    } catch (_) {
      return 'Unable to create item. Please try again.';
    }
  }

  Future<String?> updateItem(Item item) async {
    try {
      await _databaseHelper.updateItem(item);
      await loadItems();
      return null;
    } catch (_) {
      return 'Unable to update item.';
    }
  }

  Future<void> deleteItem(int itemId) async {
    if (_adminId == null) {
      return;
    }
    await _databaseHelper.deleteItem(itemId: itemId, adminId: _adminId!);
    await loadItems();
  }

  Future<void> toggleItemActive({required int itemId, required bool isActive}) async {
    if (_adminId == null) {
      return;
    }
    await _databaseHelper.toggleItemActive(
      itemId: itemId,
      adminId: _adminId!,
      isActive: isActive,
    );
    await loadItems();
  }
}
