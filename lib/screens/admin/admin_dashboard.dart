import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/voucher.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/promotion_provider.dart';
import '../../providers/user_management_provider.dart';
import '../../providers/voucher_provider.dart';
import '../login_screen.dart';
import 'admin_notifications_screen.dart';
import 'items/item_list_screen.dart';
import 'promotions/promotions_list_screen.dart';
import 'redeemed_vouchers_screen.dart';
import 'user_management_screen.dart';
import 'voucher_form_screen.dart';
import 'vouchers/voucher_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  static const routeName = '/admin/dashboard';

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final admin = auth.currentAdmin;
      if (admin != null && admin.id != null) {
        final adminId = admin.id!;
        final voucherProvider = context.read<VoucherProvider>();
        voucherProvider.setAdminContext(adminId);
        voucherProvider.setFilter('all');
        await voucherProvider.loadRedeemedHistory(adminId: adminId);
        context.read<PromotionProvider>().setAdminContext(adminId);
        await context.read<ItemProvider>().setAdmin(adminId);
        await context.read<UserManagementProvider>().loadUsers();
        await context.read<NotificationProvider>().loadAllNotificationsForAdmin();
        await context.read<AdminDashboardProvider>().loadDashboard(adminId);
      }
    });
  }

  Future<void> _openVoucherForm([Voucher? voucher]) async {
    final admin = context.read<AuthProvider>().currentAdmin;
    if (admin == null || admin.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.')),
        );
      }
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VoucherFormScreen(
          adminId: admin.id!,
          voucher: voucher,
        ),
      ),
    );
    if (result == true && mounted) {
      await context.read<VoucherProvider>().refreshVouchers();
      await context.read<AdminDashboardProvider>().loadDashboard(admin.id!);
    }
  }

  Future<void> _confirmDelete(Voucher voucher) async {
    if (voucher.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete this voucher.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete voucher'),
        content: Text('Remove voucher "${voucher.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    final voucherProvider = context.read<VoucherProvider>();
    final adminId = context.read<AuthProvider>().currentAdmin?.id;

    if (confirmed == true) {
      await voucherProvider.deleteVoucher(voucher.id!);
      if (adminId != null) {
        await voucherProvider.loadRedeemedHistory(adminId: adminId);
        await context.read<AdminDashboardProvider>().loadDashboard(adminId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Voucher deleted.')));
    }
  }

  void _handleLogout() {
    context.read<AuthProvider>().logout();
    context.read<VoucherProvider>().setAdminContext(null);
    context.read<PromotionProvider>().setAdminContext(null);
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (route) => false,
    );
  }

  Future<void> _onDestinationSelected(int index, int adminId) async {
    if (_selectedNavIndex == index && index == 0) {
      return;
    }

    setState(() => _selectedNavIndex = index);
    final navigator = Navigator.of(context);

    switch (index) {
      case 0:
        break;
      case 1:
        await navigator.pushNamed(PromotionsListScreen.routeName);
        break;
      case 2:
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => const VoucherManagementScreen(),
          ),
        );
        break;
      case 3:
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => RedeemedVouchersScreen(adminId: adminId),
          ),
        );
        break;
    }

    if (!mounted) return;
    setState(() => _selectedNavIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthProvider>().currentAdmin;
    if (admin == null || admin.id == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final adminId = admin.id!;

    final headerFooterColor = const Color(0xFF212121); // Dark grey/black color
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: headerFooterColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Welcome back, ${admin.name}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Items',
            icon: const Icon(Icons.inventory_2_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ItemListScreen(adminId: adminId),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Users',
            icon: const Icon(Icons.people_alt_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const UserManagementScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminNotificationsScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => _AdminProfileSheet(onLogout: _handleLogout),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<AdminDashboardProvider>().loadDashboard(adminId),
            context.read<VoucherProvider>().refreshVouchers(),
            context.read<VoucherProvider>().loadAdminOverview(adminId),
            context.read<PromotionProvider>().refreshPromotions(),
            context.read<ItemProvider>().loadItems(),
            context.read<UserManagementProvider>().loadUsers(),
            context.read<NotificationProvider>().loadAllNotificationsForAdmin(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SummarySection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: Consumer<VoucherProvider>(
                builder: (context, provider, _) {
                  final vouchers = provider.vouchers;
                  if (provider.isLoading) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (vouchers.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text('No vouchers yet.'),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final voucher = vouchers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _VoucherCard(
                            voucher: voucher,
                            onEdit: () => _openVoucherForm(voucher),
                            onDelete: () => _confirmDelete(voucher),
                          ),
                        );
                      },
                      childCount: vouchers.length,
                    ),
                  );
                },
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
          selectedIndex: _selectedNavIndex,
          onDestinationSelected: (index) => _onDestinationSelected(index, adminId),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.campaign, color: Theme.of(context).colorScheme.primary),
              label: 'Promotions',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.inventory, color: Theme.of(context).colorScheme.primary),
              label: 'Vouchers',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<AdminDashboardProvider>();
    final summary = dashboard.summary;
    final overview = dashboard.homeOverview;
    final colorScheme = Theme.of(context).colorScheme;
    final cards = [
      _SummaryTile(
        icon: Icons.people_alt_outlined,
        label: 'Registered users',
        value: '${overview['userCount'] ?? summary['totalUsers'] ?? 0}',
        subtitle: 'Active ${summary['activeUsers'] ?? 0}',
        background: colorScheme.primaryContainer,
      ),
      _SummaryTile(
        icon: Icons.celebration_outlined,
        label: 'Active promotions',
        value: '${overview['activePromotions'] ?? summary['activePromotions'] ?? 0}',
        subtitle: 'Total ${summary['totalPromotions'] ?? 0}',
        background: colorScheme.secondaryContainer,
      ),
      _SummaryTile(
        icon: Icons.local_offer_outlined,
        label: 'Active vouchers',
        value: '${overview['activeVouchers'] ?? summary['totalVouchers'] ?? 0}',
        subtitle: '${summary['totalRedeemed'] ?? 0} redeemed',
        background: colorScheme.tertiaryContainer,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards,
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.background,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color background;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Use the background color passed in, but ensure good contrast
    final cardColor = background;
    final isError = background == colorScheme.errorContainer;
    final iconColor = isError 
        ? colorScheme.error 
        : (background == colorScheme.primaryContainer 
            ? colorScheme.primary 
            : (background == colorScheme.secondaryContainer 
                ? colorScheme.secondary 
                : colorScheme.tertiary));
    
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontSize: 36,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminProfileSheet extends StatelessWidget {
  const _AdminProfileSheet({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthProvider>().currentAdmin;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.25),
                child: Icon(Icons.person, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              if (admin != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(admin.email, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Appearance'),
            subtitle: const Text('Theme & branding preferences'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appearance settings coming soon.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Security'),
            subtitle: const Text('Update password & enable biometrics'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security settings coming soon.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.of(context).pop();
              onLogout();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.voucher,
    required this.onEdit,
    required this.onDelete,
  });

  final Voucher voucher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = {
      'active': colorScheme.primary,
      'redeemed': colorScheme.tertiary,
      'expired': colorScheme.error,
    }[voucher.status]!;
    final isExpired = voucher.expiryDate.isBefore(DateTime.now());
    final imageFile = voucher.gallery.isNotEmpty
        ? File(voucher.gallery.first)
        : (voucher.imagePath != null ? File(voucher.imagePath!) : null);

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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                voucher.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  onEdit();
                                } else if (value == 'delete') {
                                  onDelete();
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 20),
                                      const SizedBox(width: 8),
                                      const Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                                      const SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: colorScheme.error)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            voucher.code,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                          ),
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
                          'Original',
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
                          'Discounted',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          '\$${voucher.discountedPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: statusColor,
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
                    color: isExpired
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Expires ${voucher.formattedExpiry}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isExpired
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              if ((voucher.contactName ?? voucher.contactPhone) != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [
                            if (voucher.contactName != null &&
                                voucher.contactName!.isNotEmpty)
                              voucher.contactName!,
                            if (voucher.contactPhone != null &&
                                voucher.contactPhone!.isNotEmpty)
                              voucher.contactPhone!,
                          ].join(' • '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

