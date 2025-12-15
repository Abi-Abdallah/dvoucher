import 'package:flutter/material.dart';

import '../services/database_helper.dart';
import '../models/voucher.dart';

class UserDashboardProvider extends ChangeNotifier {
  UserDashboardProvider();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Map<String, int> _summary = const {
    'activeVouchers': 0,
    'redeemed': 0,
    'expiringSoon': 0,
    'activePromotions': 0,
  };
  bool _isLoadingSummary = false;
  List<String> _shopNames = [];

  Map<String, int> get summary => _summary;
  bool get isLoadingSummary => _isLoadingSummary;
  List<String> get shopNames => List.unmodifiable(_shopNames);

  Future<void> loadSummary(int userId) async {
    _isLoadingSummary = true;
    notifyListeners();
    _summary = await _databaseHelper.getUserDashboardStats(userId);
    _isLoadingSummary = false;
    notifyListeners();
  }

  Future<void> loadShopNames() async {
    _shopNames = await _databaseHelper.getDistinctShops();
    notifyListeners();
  }

  Future<List<Voucher>> fetchTopVouchers({int limit = 5}) async {
    final vouchers = await _databaseHelper.getVouchers(
      status: 'active',
      sortBy: 'highest_discount',
      limit: limit,
    );
    return vouchers;
  }
}
