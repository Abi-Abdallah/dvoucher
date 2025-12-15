import 'package:flutter/material.dart';

import '../models/promotion.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class PromotionProvider extends ChangeNotifier {
  PromotionProvider();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Promotion> _promotions = [];
  List<Promotion> _activePromotions = [];
  List<Promotion> _userPromotions = [];
  Map<String, int> _analytics = const {
    'total': 0,
    'active': 0,
    'upcoming': 0,
    'expired': 0,
  };
  Map<int, Map<String, dynamic>> _performance = {};
  Map<int, Map<String, dynamic>> _reactions = {}; // promotionId -> {likes, dislikes, userReaction}
  Map<int, List<Map<String, dynamic>>> _comments = {}; // promotionId -> comments list
  Map<int, int> _commentCounts = {}; // promotionId -> comment count
  bool _isLoading = false;
  int? _adminId;
  int? _currentUserId;

  List<Promotion> get promotions => List.unmodifiable(_promotions);
  List<Promotion> get activePromotions => List.unmodifiable(_activePromotions);
  List<Promotion> get userPromotions => List.unmodifiable(_userPromotions);
  Map<String, int> get analytics => _analytics;
  Map<int, Map<String, dynamic>> get performance => Map.unmodifiable(_performance);
  bool get isLoading => _isLoading;

  void setUserId(int? userId) {
    _currentUserId = userId;
  }

  void setAdminContext(int? adminId) {
    _adminId = adminId;
    if (adminId == null) {
      _promotions = [];
      _analytics = const {
        'total': 0,
        'active': 0,
        'upcoming': 0,
        'expired': 0,
      };
      _isLoading = false;
      notifyListeners();
      return;
    }
    refreshPromotions();
  }

  Future<void> refreshPromotions() async {
    if (_adminId == null) {
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      _promotions = await _databaseHelper.getPromotions(adminId: _adminId);
      _analytics = await _databaseHelper.getPromotionAnalytics(_adminId!);
      _performance = await _databaseHelper.getPromotionPerformance(_adminId!);
    } catch (_) {
      _promotions = [];
      _analytics = const {
        'total': 0,
        'active': 0,
        'upcoming': 0,
        'expired': 0,
      };
      _performance = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createPromotion(Promotion promotion) async {
    if (_adminId == null) {
      return 'Admin context missing. Please log in again.';
    }
    try {
      final payload = promotion.copyWith(
        adminId: _adminId,
        createdAt: DateTime.now(),
      );
      await _databaseHelper.insertPromotion(payload);
      await NotificationService.instance.showPromotionNotification(
        title: payload.title,
        description: payload.description,
      );
      await _databaseHelper.insertNotificationForAllUsers(
        title: '🎉 ${payload.title}',
        body: payload.description,
        type: 'promotion',
      );
      await refreshPromotions();
      return null;
    } catch (_) {
      return 'Unable to create promotion. Please try again.';
    }
  }

  Future<String?> updatePromotion(Promotion promotion) async {
    try {
      final payload = promotion.copyWith(adminId: _adminId);
      await _databaseHelper.updatePromotion(payload);
      await refreshPromotions();
      return null;
    } catch (_) {
      return 'Unable to update promotion. Please try again.';
    }
  }

  Future<void> deletePromotion(int promotionId) async {
    if (_adminId == null) {
      return;
    }
    await _databaseHelper.deletePromotion(
      promotionId: promotionId,
      adminId: _adminId!,
    );
    await refreshPromotions();
  }

  Future<void> loadActivePromotionsForUsers() async {
    try {
      _activePromotions = await _databaseHelper.getActivePromotions(
        showOnHome: true,
      );
    } catch (_) {
      _activePromotions = [];
    }
    notifyListeners();
  }

  Future<void> loadPromotionsForUsers({bool includeExpired = false}) async {
    try {
      _userPromotions = await _databaseHelper.getPromotions(
        adminId: null,
        includeExpired: includeExpired,
        sortBy: 'expiring_soon',
        showOnVouchers: true,
      );
    } catch (_) {
      _userPromotions = [];
    }
    notifyListeners();
  }

  Map<String, dynamic>? getPerformanceFor(int promotionId) {
    return _performance[promotionId];
  }

  Future<void> recordImpression(int promotionId) async {
    await _databaseHelper.recordPromotionImpression(promotionId);
    if (_performance.containsKey(promotionId)) {
      final metrics = Map<String, dynamic>.from(_performance[promotionId]!);
      metrics['impressions'] = (metrics['impressions'] as int? ?? 0) + 1;
      final clicks = (metrics['clicks'] as int? ?? 0);
      final impressions = metrics['impressions'] as int;
      metrics['engagementRate'] = impressions == 0
          ? 0.0
          : clicks / impressions;
      _performance[promotionId] = metrics;
    }
    final index = _promotions.indexWhere((promotion) => promotion.id == promotionId);
    if (index != -1) {
      final promotion = _promotions[index];
      _promotions[index] = promotion.copyWith(
        impressions: promotion.impressions + 1,
      );
    }
    notifyListeners();
  }

  Future<void> recordClick(int promotionId) async {
    await _databaseHelper.recordPromotionClick(promotionId);
    if (_performance.containsKey(promotionId)) {
      final metrics = Map<String, dynamic>.from(_performance[promotionId]!);
      final impressions = (metrics['impressions'] as int? ?? 0);
      metrics['clicks'] = (metrics['clicks'] as int? ?? 0) + 1;
      final clicks = metrics['clicks'] as int;
      metrics['engagementRate'] = impressions == 0
          ? 0.0
          : clicks / impressions;
      _performance[promotionId] = metrics;
    }
    final index = _promotions.indexWhere((promotion) => promotion.id == promotionId);
    if (index != -1) {
      final promotion = _promotions[index];
      _promotions[index] = promotion.copyWith(
        clicks: promotion.clicks + 1,
      );
    }
    notifyListeners();
  }

  // Likes and Dislikes methods
  Future<void> togglePromotionLike({
    required int promotionId,
    required int userId,
    required bool isLike,
  }) async {
    try {
      await _databaseHelper.togglePromotionLike(
        promotionId: promotionId,
        userId: userId,
        isLike: isLike,
      );
      await _loadReactionsForPromotion(promotionId, userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling promotion like: $e');
    }
  }

  Future<void> _loadReactionsForPromotion(int promotionId, int? userId) async {
    try {
      final reactions = await _databaseHelper.getPromotionLikesDislikes(promotionId);
      int? userReaction;
      if (userId != null) {
        userReaction = await _databaseHelper.getUserPromotionReaction(
          promotionId: promotionId,
          userId: userId,
        );
      }
      _reactions[promotionId] = {
        'likes': reactions['likes'] ?? 0,
        'dislikes': reactions['dislikes'] ?? 0,
        'userReaction': userReaction, // 1 for like, 0 for dislike, null for none
      };
    } catch (e) {
      debugPrint('Error loading reactions: $e');
      _reactions[promotionId] = {
        'likes': 0,
        'dislikes': 0,
        'userReaction': null,
      };
    }
  }

  Future<Map<String, dynamic>> getPromotionReactions(int promotionId) async {
    if (!_reactions.containsKey(promotionId)) {
      await _loadReactionsForPromotion(promotionId, _currentUserId);
    }
    return _reactions[promotionId] ?? {
      'likes': 0,
      'dislikes': 0,
      'userReaction': null,
    };
  }

  int? getUserReaction(int promotionId) {
    return _reactions[promotionId]?['userReaction'] as int?;
  }

  // Comments methods
  Future<void> addPromotionComment({
    required int promotionId,
    required int userId,
    required String comment,
  }) async {
    try {
      await _databaseHelper.addPromotionComment(
        promotionId: promotionId,
        userId: userId,
        comment: comment,
      );
      await _loadCommentsForPromotion(promotionId);
      _commentCounts[promotionId] = (_commentCounts[promotionId] ?? 0) + 1;
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  Future<void> _loadCommentsForPromotion(int promotionId) async {
    try {
      final comments = await _databaseHelper.getPromotionComments(promotionId);
      _comments[promotionId] = comments;
      _commentCounts[promotionId] = comments.length;
    } catch (e) {
      debugPrint('Error loading comments: $e');
      _comments[promotionId] = [];
      _commentCounts[promotionId] = 0;
    }
  }

  Future<List<Map<String, dynamic>>> getPromotionComments(int promotionId) async {
    if (!_comments.containsKey(promotionId)) {
      await _loadCommentsForPromotion(promotionId);
    }
    return _comments[promotionId] ?? [];
  }

  Future<int> getPromotionCommentCount(int promotionId) async {
    if (!_commentCounts.containsKey(promotionId)) {
      final count = await _databaseHelper.getPromotionCommentCount(promotionId);
      _commentCounts[promotionId] = count;
    }
    return _commentCounts[promotionId] ?? 0;
  }

  // Load all reactions and comments for a list of promotions
  Future<void> loadReactionsAndCommentsForPromotions(
    List<int> promotionIds,
    int? userId,
  ) async {
    _currentUserId = userId;
    await Future.wait([
      ...promotionIds.map((id) => _loadReactionsForPromotion(id, userId)),
      ...promotionIds.map((id) => _loadCommentsForPromotion(id)),
    ]);
    notifyListeners();
  }

  // Clear cached data
  void clearCache() {
    _reactions.clear();
    _comments.clear();
    _commentCounts.clear();
    notifyListeners();
  }
}
