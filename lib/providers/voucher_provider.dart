import 'package:flutter/material.dart';

import '../models/feedback_entry.dart';
import '../models/redeemed_voucher.dart';
import '../models/voucher.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class VoucherProvider extends ChangeNotifier {
  VoucherProvider();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Voucher> _vouchers = [];
  List<RedeemedVoucherDetail> _redeemedHistory = [];

  String _statusFilter = 'active';
  String _searchQuery = '';
  bool _isLoading = false;
  int? _adminContextId;
  int? _userContextId;
  Map<String, dynamic>? _adminAnalytics;
  Map<String, dynamic> _adminOverview = const {};
  List<Map<String, dynamic>> _activityTrend = const [];
  List<Map<String, dynamic>> _topShops = const [];
  List<Map<String, dynamic>> _topItems = const [];
  List<Map<String, dynamic>> _topCategories = const [];
  Set<int> _favoriteVoucherIds = {};
  final Set<String> _categoryFilters = <String>{};
  String _adminSort = 'newest';

  // User filtering state
  String? _shopFilter;
  double? _minDiscount;
  double? _maxDiscount;
  double? _minPrice;
  double? _maxPrice;
  DateTimeRange? _expiryRange;
  String _sortOption = 'newest';
  bool _favoritesOnly = false;

  List<Voucher> get vouchers => List.unmodifiable(_vouchers);
  List<RedeemedVoucherDetail> get redeemedHistory =>
      List.unmodifiable(_redeemedHistory);
  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get adminAnalytics => _adminAnalytics;
  Map<String, dynamic> get adminOverview => _adminOverview;
  List<Map<String, dynamic>> get activityTrend => _activityTrend;
  List<Map<String, dynamic>> get topShops => _topShops;
  List<Map<String, dynamic>> get topItems => _topItems;
  List<Map<String, dynamic>> get topCategories => _topCategories;
  Set<int> get favoriteVoucherIds => _favoriteVoucherIds;
  Set<String> get categoryFilters => _categoryFilters;
  String get adminSort => _adminSort;
  String? get shopFilter => _shopFilter;
  double? get minDiscount => _minDiscount;
  double? get maxDiscount => _maxDiscount;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  DateTimeRange? get expiryRange => _expiryRange;
  String get sortOption => _sortOption;
  bool get favoritesOnly => _favoritesOnly;

  void setAdminContext(int? adminId) {
    _adminContextId = adminId;
    if (adminId != null) {
      if (_statusFilter == 'active') {
        _statusFilter = 'all';
      }
      loadAdminAnalytics(adminId);
      loadAdminOverview(adminId);
    } else {
      _statusFilter = 'active';
      _searchQuery = '';
      _adminAnalytics = null;
      _adminOverview = const {};
      _activityTrend = const [];
      _topShops = const [];
      _topItems = const [];
      _topCategories = const [];
      _categoryFilters.clear();
      _adminSort = 'newest';
    }
    if (adminId != null) {
      _userContextId = null;
    }
    refreshVouchers();
  }

  void resetUserView() {
    _adminContextId = null;
    _userContextId = null;
    _statusFilter = 'active';
    _searchQuery = '';
    _adminAnalytics = null;
    _adminOverview = const {};
    _activityTrend = const [];
    _topShops = const [];
    _topItems = const [];
    _topCategories = const [];
    _favoritesOnly = false;
    _shopFilter = null;
    _minDiscount = null;
    _maxDiscount = null;
    _minPrice = null;
    _maxPrice = null;
    _expiryRange = null;
    _sortOption = 'newest';
    _favoriteVoucherIds.clear();
    _categoryFilters.clear();
    _adminSort = 'newest';
    refreshVouchers();
  }

  Future<void> setUserContext(int userId) async {
    _userContextId = userId;
    _adminContextId = null;
    _statusFilter = 'active';
    _searchQuery = '';
    _favoritesOnly = false;
    _shopFilter = null;
    _minDiscount = null;
    _maxDiscount = null;
    _minPrice = null;
    _maxPrice = null;
    _expiryRange = null;
    _sortOption = 'newest';
    await _loadFavorites();
    await refreshVouchers();
  }

  Future<void> refreshVouchers() async {
    _isLoading = true;
    notifyListeners();

    final status = _statusFilter == 'all' ? null : _statusFilter;
    final isUserView = _adminContextId == null;
    _vouchers = await _databaseHelper.getVouchers(
      status: status,
      query: _searchQuery.isEmpty ? null : _searchQuery,
      adminId: _adminContextId,
      shopName: _shopFilter,
      minDiscount: _minDiscount,
      maxDiscount: _maxDiscount,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      expiryFrom: _expiryRange?.start,
      expiryTo: _expiryRange?.end,
      sortBy: isUserView ? _sortOption : _adminSort,
      userIdForFavorites: _userContextId,
      favoritesOnly: _favoritesOnly && isUserView && _userContextId != null,
      categories: _categoryFilters.isEmpty ? null : _categoryFilters.toList(),
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setFilter(String status) async {
    _statusFilter = status;
    await refreshVouchers();
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    await refreshVouchers();
  }

  Future<void> updateUserFilters({
    String? shop,
    double? minDiscount,
    double? maxDiscount,
    double? minPrice,
    double? maxPrice,
    DateTimeRange? expiryRange,
    String? sortOption,
    bool? favoritesOnly,
  }) async {
    _shopFilter = shop;
    _minDiscount = minDiscount;
    _maxDiscount = maxDiscount;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _expiryRange = expiryRange;
    if (sortOption != null) {
      _sortOption = sortOption;
    }
    if (favoritesOnly != null) {
      _favoritesOnly = favoritesOnly;
    }
    await refreshVouchers();
  }

  Future<void> setAdminExpiryRange(DateTimeRange? range) async {
    _expiryRange = range;
    await refreshVouchers();
  }

  Future<void> setAdminSortOption(String sort) async {
    _adminSort = sort;
    await refreshVouchers();
  }

  Future<void> toggleCategoryFilter(String category) async {
    final lowered = category.toLowerCase();
    if (_categoryFilters.contains(lowered)) {
      _categoryFilters.remove(lowered);
    } else {
      _categoryFilters.add(lowered);
    }
    await refreshVouchers();
  }

  Future<void> clearUserFilters() async {
    _shopFilter = null;
    _minDiscount = null;
    _maxDiscount = null;
    _minPrice = null;
    _maxPrice = null;
    _expiryRange = null;
    _sortOption = 'newest';
    _favoritesOnly = false;
    await refreshVouchers();
  }

  Future<void> clearAdminFilters() async {
    _categoryFilters.clear();
    _shopFilter = null;
    _minDiscount = null;
    _maxDiscount = null;
    _minPrice = null;
    _maxPrice = null;
    _expiryRange = null;
    _adminSort = 'newest';
    _statusFilter = 'all';
    _searchQuery = '';
    await refreshVouchers();
  }

  Future<String?> createVoucher(Voucher voucher) async {
    try {
      if (_adminContextId == null) {
        return 'Admin context not set. Please log in again.';
      }
      if (voucher.adminId != _adminContextId) {
        return 'You can only manage your own vouchers.';
      }
      await _databaseHelper.insertVoucher(voucher);
      await NotificationService.instance.showVoucherNotification();
      await _databaseHelper.insertNotificationForAllUsers(
        title: '🎁 New voucher: ${voucher.name}',
        body: 'Check out the latest offer at ${voucher.shopName}.',
        type: 'voucher',
      );
      await refreshVouchers();
      await loadAdminAnalytics(_adminContextId!);
      await loadRedeemedHistory(adminId: _adminContextId!);
      return null;
    } catch (_) {
      return 'Could not create voucher. Please try again.';
    }
  }

  Future<String?> updateVoucher(Voucher voucher) async {
    try {
      if (_adminContextId != null && voucher.adminId != _adminContextId) {
        return 'You can only edit your own vouchers.';
      }
      await _databaseHelper.updateVoucher(voucher);
      await refreshVouchers();
      if (_adminContextId != null) {
        await loadAdminAnalytics(_adminContextId!);
        await loadRedeemedHistory(adminId: _adminContextId!);
      }
      return null;
    } catch (_) {
      return 'Unable to update voucher.';
    }
  }

  Future<void> deleteVoucher(int voucherId) async {
    if (_adminContextId == null) {
      return;
    }
    await _databaseHelper.deleteVoucher(
      voucherId: voucherId,
      adminId: _adminContextId!,
    );
    await refreshVouchers();
    await loadAdminAnalytics(_adminContextId!);
    await loadRedeemedHistory(adminId: _adminContextId!);
  }

  Future<String?> redeemVoucher({
    required int userId,
    required Voucher voucher,
  }) async {
    if (voucher.status != 'active') {
      return 'This voucher is not active anymore.';
    }

    if (voucher.isExpired) {
      await _databaseHelper.updateVoucher(
        voucher.copyWith(status: 'expired'),
      );
      await refreshVouchers();
      return 'This voucher has already expired.';
    }

    final error = await _databaseHelper.redeemVoucher(
      userId: userId,
      voucher: voucher,
    );
    if (error != null) {
      return error;
    }
    await refreshVouchers();
    await loadRedeemedHistory(userId: userId);
    await _databaseHelper.insertNotification(
      userId: userId,
      title: 'Voucher awaiting confirmation',
      body: 'Your redemption for ${voucher.name} is pending confirmation.',
      type: 'redeem',
    );
    return null;
  }

  Future<void> loadRedeemedHistory({int? userId, int? adminId}) async {
    _redeemedHistory = await _databaseHelper.getRedeemedVouchers(
      userId: userId,
      adminId: adminId ?? _adminContextId,
    );
    notifyListeners();
  }

  Future<void> loadAdminAnalytics(int adminId) async {
    try {
      if (adminId <= 0) {
        _adminAnalytics = null;
      } else {
        _adminAnalytics = await _databaseHelper.getAdminAnalytics(adminId);
      }
    } catch (error) {
      _adminAnalytics = null;
      debugPrint('Failed to load admin analytics: $error');
    }
    notifyListeners();
  }

  Future<void> loadAdminOverview(int adminId) async {
    try {
      final overview = await _databaseHelper.getAdminHomeOverview(adminId);
      _adminOverview = overview;
      _activityTrend = (overview['trendDaily'] as List?)
              ?.map((item) => Map<String, dynamic>.from(item as Map))
              .toList() ??
          const [];
      _topShops = (overview['topShops'] as List?)
              ?.map((item) => Map<String, dynamic>.from(item as Map))
              .toList() ??
          const [];
      _topItems = (overview['topItems'] as List?)
              ?.map((item) => Map<String, dynamic>.from(item as Map))
              .toList() ??
          const [];
      _topCategories = (overview['topCategories'] as List?)
              ?.map((item) => Map<String, dynamic>.from(item as Map))
              .toList() ??
          const [];
    } catch (error) {
      debugPrint('Failed to load admin overview: $error');
      _adminOverview = const {};
      _activityTrend = const [];
      _topShops = const [];
      _topItems = const [];
      _topCategories = const [];
    }
    notifyListeners();
  }

  Future<void> confirmRedemption({
    required int redeemId,
    required String redeemedBy,
    String? note,
    required int adminId,
  }) async {
    await _databaseHelper.confirmRedemption(
      redeemId: redeemId,
      redeemedBy: redeemedBy,
      note: note,
    );
    await loadRedeemedHistory(adminId: adminId);
    await loadAdminAnalytics(adminId);
    await refreshVouchers();
    RedeemedVoucherDetail? entry;
    try {
      entry = _redeemedHistory.firstWhere((item) => item.id == redeemId);
    } catch (_) {
      entry = null;
    }
    final shopName = entry?.shopName;
    await NotificationService.instance
        .showRedemptionNotification(shopName: shopName);
    if (entry != null) {
      await _databaseHelper.insertNotification(
        userId: entry.userId,
        title: '✅ Voucher redeemed',
        body: 'Your voucher ${entry.voucherName} was confirmed at ${entry.shopName}.',
        type: 'redeem',
      );
    }
  }

  Future<String?> submitFeedback({required FeedbackEntry entry}) async {
    final alreadyExists = await _databaseHelper.hasUserSubmittedFeedback(
      userId: entry.userId,
      voucherId: entry.voucherId,
    );
    if (alreadyExists) {
      return 'You have already submitted feedback for this voucher.';
    }
    await _databaseHelper.insertFeedback(entry);
    await loadRedeemedHistory(userId: entry.userId);
    return null;
  }

  Future<void> toggleFavorite({
    required int userId,
    required Voucher voucher,
  }) async {
    if (voucher.id == null) {
      return;
    }
    final isFavorite = _favoriteVoucherIds.contains(voucher.id);
    if (isFavorite) {
      await _databaseHelper.removeFavoriteVoucher(
        userId: userId,
        voucherId: voucher.id!,
      );
      _favoriteVoucherIds.remove(voucher.id);
    } else {
      await _databaseHelper.addFavoriteVoucher(
        userId: userId,
        voucherId: voucher.id!,
      );
      _favoriteVoucherIds.add(voucher.id!);
    }
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    if (_userContextId == null) {
      _favoriteVoucherIds = {};
      return;
    }
    _favoriteVoucherIds =
        await _databaseHelper.getFavoriteVoucherIds(_userContextId!);
    notifyListeners();
  }
}

