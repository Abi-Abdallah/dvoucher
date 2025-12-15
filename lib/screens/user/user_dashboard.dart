import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/promotion.dart';
import '../../models/voucher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/promotion_provider.dart';
import '../../providers/user_dashboard_provider.dart';
import '../../providers/voucher_provider.dart';
import '../../widgets/modern_promotion_card.dart';
import '../login_screen.dart';
import 'redeemed_history_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  static const routeName = '/user/dashboard';

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final PageController _promotionController = PageController(viewportFraction: 0.88);
  Timer? _promotionTimer;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      if (user == null) {
        return;
      }
      final voucherProvider = context.read<VoucherProvider>();
      final promotionProvider = context.read<PromotionProvider>();
      final dashboardProvider = context.read<UserDashboardProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      await voucherProvider.setUserContext(user.id!);
      await voucherProvider.loadRedeemedHistory(userId: user.id!);

      await promotionProvider.loadActivePromotionsForUsers();
      await promotionProvider.loadPromotionsForUsers(includeExpired: true);

      await dashboardProvider.loadSummary(user.id!);
      await dashboardProvider.loadShopNames();

      await notificationProvider.setUser(user.id!);

      _startPromotionAutoScroll();
    });
  }

  @override
  void dispose() {
    _promotionTimer?.cancel();
    _promotionController.dispose();
    super.dispose();
  }

  void _startPromotionAutoScroll() {
    _promotionTimer?.cancel();
    _promotionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final promotions = context.read<PromotionProvider>().activePromotions;
      if (promotions.length <= 1) {
        return;
      }
      final currentPage = _promotionController.hasClients
          ? _promotionController.page?.round() ?? 0
          : 0;
      final nextPage = (currentPage + 1) % promotions.length;
      _promotionController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _handleLogout() {
    context.read<AuthProvider>().logout();
    context.read<VoucherProvider>().resetUserView();
    context.read<NotificationProvider>().clearUser();
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (route) => false,
    );
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => const _NotificationSheet(),
    );
  }

  void _openSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(),
    );
  }

  void _jumpToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tabTitles = ['Home', 'Promotions', 'Vouchers', 'History', 'Profile'];

    final tabs = [
      _HomeTab(
        userName: user.name,
        dateFormat: _dateFormat,
        promoController: _promotionController,
        onViewAllPromotions: () => _jumpToTab(1),
        onViewAllVouchers: () => _jumpToTab(2),
        onOpenNotifications: _openNotifications,
      ),
      const _PromotionsTab(),
      _VouchersTab(dateFormat: _dateFormat),
      _HistoryTab(userId: user.id!),
      _ProfileTab(onLogout: _handleLogout),
    ];

    final headerFooterColor = const Color(0xFF212121); // Dark grey/black color
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: headerFooterColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tabTitles[_currentIndex],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Search',
                        onPressed: () => _openSearch(context),
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                      ),
                      _NotificationBell(
                        onPressed: _openNotifications,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: tabs,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: headerFooterColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          height: 76,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: Colors.transparent,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.celebration_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.celebration, color: Theme.of(context).colorScheme.primary),
              label: 'Promotions',
            ),
            NavigationDestination(
              icon: Icon(Icons.card_giftcard_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.card_giftcard, color: Theme.of(context).colorScheme.primary),
              label: 'Vouchers',
            ),
            NavigationDestination(
              icon: Icon(Icons.history, color: Colors.white70),
              selectedIcon: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.white70),
              selectedIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.userName,
    required this.dateFormat,
    required this.promoController,
    required this.onViewAllPromotions,
    required this.onViewAllVouchers,
    required this.onOpenNotifications,
  });

  final String userName;
  final DateFormat dateFormat;
  final PageController promoController;
  final VoidCallback onViewAllPromotions;
  final VoidCallback onViewAllVouchers;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        final user = auth.currentUser;
        final dashboardProvider = context.read<UserDashboardProvider>();
        final promotionProvider = context.read<PromotionProvider>();
        final voucherProvider = context.read<VoucherProvider>();
        final notificationProvider = context.read<NotificationProvider>();
        if (user != null) {
          await dashboardProvider.loadSummary(user.id!);
          await promotionProvider.loadActivePromotionsForUsers();
          await promotionProvider.loadPromotionsForUsers(includeExpired: true);
          await voucherProvider.refreshVouchers();
          await voucherProvider.loadRedeemedHistory(userId: user.id!);
          await notificationProvider.loadNotifications();
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 8),
          Text(
            'Hi 👋, here are today\'s best deals for you!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 24),
          const _SummaryRow(),
          const SizedBox(height: 24),
          _PromotionsCarousel(
            controller: promoController,
            onViewAll: onViewAllPromotions,
          ),
          const SizedBox(height: 24),
          _TopVoucherSection(
            dateFormat: dateFormat,
            onViewAll: onViewAllVouchers,
          ),
          const SizedBox(height: 24),
          _QuickActionsRow(onOpenNotifications: onOpenNotifications),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserDashboardProvider>();
    final summary = provider.summary;
    final cards = [
      _SummaryCard(
        title: 'Active Vouchers',
        value: summary['activeVouchers'] ?? 0,
        icon: Icons.card_giftcard_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      _SummaryCard(
        title: 'Redeemed',
        value: summary['redeemed'] ?? 0,
        icon: Icons.verified_outlined,
        color: Theme.of(context).colorScheme.tertiary,
      ),
      _SummaryCard(
        title: 'Expiring Soon',
        value: summary['expiringSoon'] ?? 0,
        icon: Icons.hourglass_bottom_outlined,
        color: Theme.of(context).colorScheme.error,
      ),
      _SummaryCard(
        title: 'Active Promotions',
        value: summary['activePromotions'] ?? 0,
        icon: Icons.campaign_outlined,
        color: Theme.of(context).colorScheme.secondary,
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              cards[0],
              const SizedBox(height: 12),
              cards[2],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              cards[1],
              const SizedBox(height: 12),
              cards[3],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Use green for most cards, red for expiring
    final isError = color == colorScheme.error;
    final cardColor = isError ? const Color(0xFFEF5350) : const Color(0xFF66BB6A);
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: cardColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 36,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PromotionsCarousel extends StatelessWidget {
  const _PromotionsCarousel({
    required this.controller,
    required this.onViewAll,
  });

  final PageController controller;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final promotions = context.watch<PromotionProvider>().activePromotions;
    if (promotions.isEmpty) {
      return _SectionHeader(
        title: 'Top Promotions',
        actionLabel: 'View all',
        onAction: onViewAll,
        child: Container(
          height: 200,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('No promotions running right now.'),
        ),
      );
    }

    return _SectionHeader(
      title: 'Top Promotions',
      actionLabel: 'View all',
      onAction: onViewAll,
      child: SizedBox(
        height: 280,
        child: PageView.builder(
          controller: controller,
          itemCount: promotions.length,
          itemBuilder: (context, index) {
            final promotion = promotions[index];
            return Padding(
              padding: EdgeInsets.only(
                right: index == promotions.length - 1 ? 0 : 12,
              ),
              child: _PromotionBanner(promotion: promotion),
            );
          },
        ),
      ),
    );
  }
}

class _PromotionBanner extends StatelessWidget {
  const _PromotionBanner({required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final images = promotion.gallery.isNotEmpty
        ? promotion.gallery
        : (promotion.imagePath != null && promotion.imagePath!.isNotEmpty
            ? [promotion.imagePath!]
            : <String>[]);
    final heroImage = images.isNotEmpty ? images.first : null;
    return GestureDetector(
      onTap: () => _showPromotionDetail(context, promotion),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: heroImage == null
              ? LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                    colorScheme.secondary.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          image: heroImage != null
              ? DecorationImage(
                  image: FileImage(File(heroImage)),
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PROMOTION',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                promotion.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 26,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                promotion.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 17,
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.storefront_outlined,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        promotion.shopName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopVoucherSection extends StatelessWidget {
  const _TopVoucherSection({
    required this.dateFormat,
    required this.onViewAll,
  });

  final DateFormat dateFormat;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return _SectionHeader(
      title: 'Top vouchers',
      actionLabel: 'View all',
      onAction: onViewAll,
      child: FutureBuilder<List<Voucher>>(
        future:
            context.read<UserDashboardProvider>().fetchTopVouchers(limit: 5),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ));
          }
          final vouchers = snapshot.data ?? [];
          if (vouchers.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('No vouchers available at the moment.'),
              ),
            );
          }
          return Column(
            children: vouchers
                .take(3)
                .map(
                  (voucher) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CompactVoucherCard(
                      voucher: voucher,
                      dateFormat: dateFormat,
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _CompactVoucherCard extends StatelessWidget {
  const _CompactVoucherCard({
    required this.voucher,
    required this.dateFormat,
  });

  final Voucher voucher;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpired = voucher.expiryDate.isBefore(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  voucher.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${voucher.discountValue.toStringAsFixed(0)}${voucher.discountType == 'percentage' ? '%' : '\$'} OFF',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  voucher.shopName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${voucher.originalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '\$${voucher.discountedPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: isExpired
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(voucher.expiryDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isExpired
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.onOpenNotifications});

  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onOpenNotifications,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Notification center'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () async {
              await context.read<VoucherProvider>().clearUserFilters();
            },
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Reset filters'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class _PromotionsTab extends StatelessWidget {
  const _PromotionsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PromotionProvider>(
      builder: (context, provider, _) {
        final promotions = provider.userPromotions;
        if (promotions.isEmpty) {
          return const Center(child: Text('No promotions at this time.'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadPromotionsForUsers(includeExpired: true);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: promotions.map((promotion) {
              return ModernPromotionCard(
                promotion: promotion,
                onTap: () => _showPromotionDetail(context, promotion),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}


class _VouchersTab extends StatefulWidget {
  const _VouchersTab({required this.dateFormat});

  final DateFormat dateFormat;

  @override
  State<_VouchersTab> createState() => _VouchersTabState();
}

class _VouchersTabState extends State<_VouchersTab> {
  final TextEditingController _shopController = TextEditingController();
  RangeValues _discountRange = const RangeValues(0, 100);
  RangeValues _priceRange = const RangeValues(0, 500);
  DateTimeRange? _expiryRange;
  bool _favoritesOnly = false;
  String _sortOption = 'newest';

  @override
  void dispose() {
    _shopController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _expiryRange,
    );
    if (picked != null) {
      setState(() => _expiryRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voucherProvider = context.watch<VoucherProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Column(
      children: [
        _FilterPanel(
          shopController: _shopController,
          discountRange: _discountRange,
          priceRange: _priceRange,
          expiryRange: _expiryRange,
          sortOption: _sortOption,
          favoritesOnly: _favoritesOnly,
          onDiscountChanged: (value) => setState(() => _discountRange = value),
          onPriceChanged: (value) => setState(() => _priceRange = value),
          onExpiryPressed: _pickExpiryRange,
          onSortChanged: (value) => setState(() => _sortOption = value),
          onFavoritesChanged: (value) => setState(() => _favoritesOnly = value),
          onApplyFilters: () async {
            await context.read<VoucherProvider>().updateUserFilters(
                  shop: _shopController.text.trim().isEmpty
                      ? null
                      : _shopController.text.trim(),
                  minDiscount: _discountRange.start,
                  maxDiscount: _discountRange.end,
                  minPrice: _priceRange.start,
                  maxPrice: _priceRange.end,
                  expiryRange: _expiryRange,
                  sortOption: _sortOption,
                  favoritesOnly: _favoritesOnly,
                );
          },
          onClearFilters: () async {
            _shopController.clear();
            setState(() {
              _discountRange = const RangeValues(0, 100);
              _priceRange = const RangeValues(0, 500);
              _expiryRange = null;
              _sortOption = 'newest';
              _favoritesOnly = false;
            });
            await context.read<VoucherProvider>().clearUserFilters();
          },
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await context.read<VoucherProvider>().refreshVouchers();
            },
            child: voucherProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : voucherProvider.vouchers.isEmpty
                    ? const Center(child: Text('No vouchers match the current filters.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final voucher = voucherProvider.vouchers[index];
                          final isFavorite = voucherProvider.favoriteVoucherIds
                              .contains(voucher.id);
                          return _VoucherListCard(
                            voucher: voucher,
                            dateFormat: widget.dateFormat,
                            isFavorite: isFavorite,
                            onToggleFavorite: () {
                              if (user == null) return;
                              context.read<VoucherProvider>().toggleFavorite(
                                    userId: user.id!,
                                    voucher: voucher,
                                  );
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: voucherProvider.vouchers.length,
                      ),
          ),
        ),
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.shopController,
    required this.discountRange,
    required this.priceRange,
    required this.expiryRange,
    required this.sortOption,
    required this.favoritesOnly,
    required this.onDiscountChanged,
    required this.onPriceChanged,
    required this.onExpiryPressed,
    required this.onSortChanged,
    required this.onFavoritesChanged,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  final TextEditingController shopController;
  final RangeValues discountRange;
  final RangeValues priceRange;
  final DateTimeRange? expiryRange;
  final String sortOption;
  final bool favoritesOnly;
  final ValueChanged<RangeValues> onDiscountChanged;
  final ValueChanged<RangeValues> onPriceChanged;
  final VoidCallback onExpiryPressed;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<bool> onFavoritesChanged;
  final VoidCallback onApplyFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Filter & sort vouchers'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        TextField(
          controller: shopController,
          decoration: const InputDecoration(
            labelText: 'Shop name',
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
        ),
        const SizedBox(height: 16),
        Text('Discount %: ${discountRange.start.round()} - ${discountRange.end.round()}'),
        RangeSlider(
          values: discountRange,
          min: 0,
          max: 100,
          divisions: 20,
          onChanged: onDiscountChanged,
        ),
        const SizedBox(height: 12),
        Text('Price after discount: ${priceRange.start.toStringAsFixed(0)} - ${priceRange.end.toStringAsFixed(0)}'),
        RangeSlider(
          values: priceRange,
          min: 0,
          max: 1000,
          divisions: 20,
          onChanged: onPriceChanged,
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_outlined),
          title: const Text('Expiry range'),
          subtitle: Text(
            expiryRange == null
                ? 'Any time'
                : '${DateFormat('dd MMM yyyy').format(expiryRange!.start)} - ${DateFormat('dd MMM yyyy').format(expiryRange!.end)}',
          ),
          trailing: TextButton(
            onPressed: onExpiryPressed,
            child: const Text('Select'),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: sortOption,
          items: const [
            DropdownMenuItem(value: 'newest', child: Text('Newest first')),
            DropdownMenuItem(value: 'expiring_soon', child: Text('Expiring soon')),
            DropdownMenuItem(value: 'highest_discount', child: Text('Highest discount')),
            DropdownMenuItem(value: 'price_low_high', child: Text('Lowest price')),
            DropdownMenuItem(value: 'price_high_low', child: Text('Highest price')),
          ],
          onChanged: (value) {
            if (value != null) {
              onSortChanged(value);
            }
          },
          decoration: const InputDecoration(
            labelText: 'Sort vouchers',
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: favoritesOnly,
          onChanged: onFavoritesChanged,
          title: const Text('Show favorites only'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onClearFilters,
                child: const Text('Clear'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onApplyFilters,
                child: const Text('Apply filters'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VoucherListCard extends StatelessWidget {
  const _VoucherListCard({
    required this.voucher,
    required this.dateFormat,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Voucher voucher;
  final DateFormat dateFormat;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final imageFile = voucher.gallery.isNotEmpty
        ? File(voucher.gallery.first)
        : (voucher.imagePath != null ? File(voucher.imagePath!) : null);
    final isExpired = voucher.expiryDate.isBefore(DateTime.now());

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageFile != null && imageFile.existsSync())
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        imageFile,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.card_giftcard_outlined,
                            color: colorScheme.onSurfaceVariant,
                            size: 40,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.2),
                            colorScheme.secondary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.card_giftcard_outlined,
                        color: colorScheme.primary,
                        size: 40,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                voucher.shopName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                voucher.shopAddress,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original Price',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          '\$${voucher.originalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Discounted Price',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          '\$${voucher.discountedPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${voucher.discountValue.toStringAsFixed(0)}${voucher.discountType == 'percentage' ? '%' : '\$'} OFF',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Expires ${dateFormat.format(voucher.expiryDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isExpired
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: user == null ? null : onToggleFavorite,
                      icon: Icon(
                        isFavorite
                            ? Icons.bookmark
                            : Icons.bookmark_border_outlined,
                        size: 18,
                      ),
                      label: Text(isFavorite ? 'Saved' : 'Save'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final user = context.read<AuthProvider>().currentUser;
                        if (user == null) {
                          return;
                        }
                        final error = await context
                            .read<VoucherProvider>()
                            .redeemVoucher(
                              userId: user.id!,
                              voucher: voucher,
                            );
                        if (error != null) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(error)));
                        } else {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Voucher ${voucher.code} marked for redemption.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.redeem_outlined, size: 18),
                      label: const Text('Redeem'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.userId});

  final int userId;

  Color _statusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'confirmed':
        return colorScheme.primary;
      case 'pending':
        return colorScheme.secondary;
      case 'expired':
        return colorScheme.error;
      default:
        return colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoucherProvider>(
      builder: (context, provider, _) {
        final history = provider.redeemedHistory;
        if (history.isEmpty) {
          return const Center(child: Text('No redemption history yet.'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadRedeemedHistory(userId: userId);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final entry = history[index];
              final color = _statusColor(context, entry.status);
              final colorScheme = Theme.of(context).colorScheme;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.surface,
                        color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.card_giftcard_outlined,
                            color: color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.voucherName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.storefront_outlined,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      entry.shopName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy – HH:mm')
                                        .format(entry.dateRedeemed),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              if (entry.note != null && entry.note!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Note: ${entry.note}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                entry.status.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            if (entry.status.toLowerCase() == 'confirmed')
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: FilledButton.tonal(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            RedeemedHistoryScreen(userId: userId),
                                      ),
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text('Feedback'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: history.length,
          ),
        );
      },
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _notificationsEnabled = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController();
    _notificationsEnabled = user?.notificationsEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.updateUserProfile(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text.isEmpty ? null : _passwordController.text,
      notificationsEnabled: _notificationsEnabled,
    );
    setState(() => _isSaving = false);
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated successfully.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final summary = context.watch<UserDashboardProvider>().summary;
    final user = auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header Section
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                  colorScheme.secondary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'User',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.email ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // Content Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Information Card
                  _SectionCard(
                    title: 'Profile Information',
                    icon: Icons.person_outline,
                    iconColor: colorScheme.primary,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Full name',
                          labelStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                          prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                          prefixIcon: Icon(Icons.email_outlined, color: colorScheme.primary),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'New password',
                          labelStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                          prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
                          helperText: 'Leave blank to keep current password',
                          helperStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            'Save Changes',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Settings Card
                  _SectionCard(
                    title: 'Settings',
                    icon: Icons.settings_outlined,
                    iconColor: colorScheme.secondary,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.notifications_active_outlined,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Enable Notifications',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Receive alerts for vouchers and promotions',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _notificationsEnabled,
                              onChanged: (value) {
                                setState(() => _notificationsEnabled = value);
                                auth.setNotificationPreference(value);
                              },
                              activeColor: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout_outlined),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onLogout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 20,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}


class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: onPressed,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.white),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onError,
                            fontSize: 10,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationSheet extends StatelessWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final notifications = provider.notifications;
        if (notifications.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No notifications yet.')),
          );
        }
        final height = MediaQuery.of(context).size.height * 0.6;
        return SizedBox(
          height: height,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: provider.markAllRead,
                      child: const Text('Mark all as read'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return ListTile(
                      leading: Icon(
                        notification.isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                      ),
                      title: Text(notification.title),
                      subtitle: Text(notification.body),
                      trailing: Text(DateFormat('dd MMM HH:mm').format(notification.createdAt)),
                      onTap: () => provider.markAsRead(notification.id!),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(),
                  itemCount: notifications.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet();

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Voucher> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _performSearch();
  }

  Future<void> _performSearch() async {
    if (_searchQuery.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final voucherProvider = context.read<VoucherProvider>();
    await voucherProvider.setSearchQuery(_searchQuery);
    await voucherProvider.refreshVouchers();

    setState(() {
      _searchResults = voucherProvider.vouchers;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final height = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search vouchers, shops, promotions...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchQuery.trim().isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start typing to search',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Search for vouchers, shops, or promotions',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try different keywords',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[500],
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final voucher = _searchResults[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.card_giftcard_outlined,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    title: Text(
                                      voucher.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('${voucher.shopName} • ${voucher.shopAddress}'),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '\$${voucher.originalPrice.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                decoration: TextDecoration.lineThrough,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '\$${voucher.discountedPrice.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                    ),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      // Navigate to voucher detail
                                      // You can add navigation here if needed
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Text(
                  actionLabel!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

void _showPromotionDetail(BuildContext context, Promotion promotion) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PromotionDetailView(promotion: promotion),
  );
}

class _PromotionDetailView extends StatelessWidget {
  const _PromotionDetailView({required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final images = promotion.gallery.isNotEmpty
        ? promotion.gallery
        : (promotion.imagePath != null && promotion.imagePath!.isNotEmpty
            ? [promotion.imagePath!]
            : <String>[]);
    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.9,
      initialChildSize: 0.8,
      minChildSize: 0.6,
      builder: (context, controller) {
        return SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                promotion.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (images.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final path = images[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(path),
                          width: 280,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 280,
                            color: colorScheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child:
                                const Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                  ),
                ),
              const SizedBox(height: 16),
              Text(promotion.description),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.storefront_outlined),
                title: Text(promotion.shopName),
                subtitle: Text(promotion.shopAddress),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Promotion period'),
                subtitle: Text(
                  '${DateFormat('dd MMM yyyy').format(promotion.startDate)} - ${DateFormat('dd MMM yyyy').format(promotion.endDate)}',
                ),
              ),
              if (promotion.contactName != null ||
                  promotion.contactPhone != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.support_agent_outlined),
                  title: Text(promotion.contactName ?? 'Contact'),
                  subtitle: Text(
                    promotion.contactPhone ?? 'Phone not provided',
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}

