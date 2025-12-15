import 'package:flutter/material.dart';

import '../models/shop.dart';
import '../services/database_helper.dart';

class ShopProvider extends ChangeNotifier {
  ShopProvider();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Shop> _shops = [];
  bool _isLoading = false;

  List<Shop> get shops => List.unmodifiable(_shops);
  bool get isLoading => _isLoading;

  Future<void> loadShops(int adminId) async {
    _isLoading = true;
    notifyListeners();
    _shops = await _databaseHelper.getShops(adminId);
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> addShop(Shop shop) async {
    try {
      await _databaseHelper.insertShop(shop);
      await loadShops(shop.adminId);
      return null;
    } catch (_) {
      return 'Unable to create shop. Please try again.';
    }
  }

  Future<String?> updateShop(Shop shop) async {
    try {
      await _databaseHelper.updateShop(shop);
      await loadShops(shop.adminId);
      return null;
    } catch (_) {
      return 'Unable to update shop details.';
    }
  }

  Future<void> deleteShop({required int shopId, required int adminId}) async {
    await _databaseHelper.deleteShop(shopId: shopId, adminId: adminId);
    await loadShops(adminId);
  }

  Shop? getShopById(int shopId) {
    try {
      return _shops.firstWhere((shop) => shop.id == shopId);
    } catch (_) {
      return null;
    }
  }
}

