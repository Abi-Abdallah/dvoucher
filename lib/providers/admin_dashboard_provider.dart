import 'package:flutter/material.dart';

import '../services/database_helper.dart';
import '../models/app_notification.dart';
import '../models/redeemed_voucher.dart';

class AdminDashboardProvider extends ChangeNotifier {
  AdminDashboardProvider();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Map<String, dynamic> _summary = const {};
  List<Map<String, dynamic>> _topItems = [];
  List<Map<String, dynamic>> _topVouchers = [];
  List<RedeemedVoucherDetail> _recentRedemptions = [];
  List<AppNotification> _latestNotifications = [];
  List<Map<String, dynamic>> _recentFeedback = [];
  Map<String, dynamic> _homeOverview = const {};
  List<Map<String, dynamic>> _activityTrend = [];
  List<Map<String, dynamic>> _activityTrendWeekly = [];
  List<Map<String, dynamic>> _activityTrendMonthly = [];
  List<Map<String, dynamic>> _topShops = [];
  List<Map<String, dynamic>> _topCategories = [];
  bool _isLoading = false;

  Map<String, dynamic> get summary => _summary;
  List<Map<String, dynamic>> get topItems => List.unmodifiable(_topItems);
  List<Map<String, dynamic>> get topVouchers => List.unmodifiable(_topVouchers);
  List<RedeemedVoucherDetail> get recentRedemptions =>
      List.unmodifiable(_recentRedemptions);
  List<AppNotification> get latestNotifications =>
      List.unmodifiable(_latestNotifications);
  List<Map<String, dynamic>> get recentFeedback =>
      List.unmodifiable(_recentFeedback);
  Map<String, dynamic> get homeOverview => _homeOverview;
  List<Map<String, dynamic>> get activityTrend =>
      List.unmodifiable(_activityTrend);
  List<Map<String, dynamic>> get activityTrendWeekly =>
      List.unmodifiable(_activityTrendWeekly);
  List<Map<String, dynamic>> get activityTrendMonthly =>
      List.unmodifiable(_activityTrendMonthly);
  List<Map<String, dynamic>> get topShops => List.unmodifiable(_topShops);
  List<Map<String, dynamic>> get topCategories =>
      List.unmodifiable(_topCategories);
  bool get isLoading => _isLoading;

  Future<void> loadDashboard(int adminId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final adminAnalytics = await _databaseHelper.getAdminAnalytics(adminId);
      final promoAnalytics = await _databaseHelper.getPromotionAnalytics(adminId);
      final totalUsers = await _databaseHelper.getTotalUsers();
      final activeUsers = await _databaseHelper.getTotalUsers(onlyActive: true);
      final totalItems = await _databaseHelper.getItemCount(adminId);
      final activeItems = await _databaseHelper.getActiveItemCount(adminId);
      final topItems = await _databaseHelper.getTopItemsByRedemption(adminId);
      final topVouchers = adminAnalytics['topRedeemed'] as List<dynamic>? ?? [];
      final recentRedemptions = await _databaseHelper.getRedeemedVouchers(
        adminId: adminId,
      );
      final notifications =
          await _databaseHelper.getNotifications(userId: null, onlyUnread: false);
      final feedback = await _databaseHelper.getAllFeedback(adminId: adminId);
      final overview = await _databaseHelper.getAdminHomeOverview(adminId);

      _summary = {
        'totalVouchers': adminAnalytics['totalVouchers'] ?? 0,
        'totalRedeemed': adminAnalytics['totalRedeemed'] ?? 0,
        'averageRating': (adminAnalytics['averageRating'] as num?)?.toDouble() ?? 0,
        'totalPromotions': promoAnalytics['total'] ?? 0,
        'activePromotions': promoAnalytics['active'] ?? 0,
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'totalItems': totalItems,
        'activeItems': activeItems,
      };
      _topItems = topItems;
      _topVouchers = topVouchers
          .map((entry) => {
                'name': (entry['name'] as String?) ?? 'Unknown voucher',
                'total': (entry['total'] as num?)?.toInt() ?? 0,
              })
          .toList();
      _recentRedemptions = recentRedemptions.take(10).toList();
      _latestNotifications = notifications.take(5).toList();
      _recentFeedback = feedback.take(5).toList();
      _homeOverview = overview;
      _activityTrend = (overview['trendDaily'] as List<dynamic>? ?? [])
          .map((entry) => {
                'label': entry['label'] ?? entry['day'],
                'total': (entry['total'] as num?)?.toInt() ?? 0,
              })
          .toList();
      _activityTrendWeekly = (overview['trendWeekly'] as List<dynamic>? ?? [])
          .map((entry) => {
                'label': entry['label'] ?? entry['week'] ?? '',
                'total': (entry['total'] as num?)?.toInt() ?? 0,
              })
          .toList();
      _activityTrendMonthly = (overview['trendMonthly'] as List<dynamic>? ?? [])
          .map((entry) => {
                'label': entry['label'] ?? entry['month'] ?? '',
                'total': (entry['total'] as num?)?.toInt() ?? 0,
              })
          .toList();
      _topShops = (overview['topShops'] as List<dynamic>? ?? [])
          .map((entry) => {
                'name': entry['name'] ?? 'Unknown shop',
                'total': (entry['total'] as num?)?.toInt() ?? 0,
              })
          .toList();
      _topCategories = (overview['topCategories'] as List<dynamic>? ?? [])
          .map((entry) => {
                'name': entry['name'] ?? 'Uncategorized',
                'total': (entry['total'] as num?)?.toInt() ?? 0,
              })
          .toList();
      _summary = {
        ..._summary,
        'revenueSaved': (overview['revenueSaved'] as num?)?.toDouble() ?? 0,
        'redemptionCount': overview['redemptionCount'] ?? 0,
        'activeVouchers': overview['activeVouchers'] ?? 0,
        'userCount': overview['userCount'] ?? 0,
      };
    } catch (error) {
      debugPrint('Failed to load admin dashboard: $error');
      _summary = const {};
      _topItems = [];
      _topVouchers = [];
      _recentRedemptions = [];
      _latestNotifications = [];
      _recentFeedback = [];
      _homeOverview = const {};
      _activityTrend = [];
      _activityTrendWeekly = [];
      _activityTrendMonthly = [];
      _topShops = [];
      _topCategories = [];
    }
    _isLoading = false;
    notifyListeners();
  }
}
