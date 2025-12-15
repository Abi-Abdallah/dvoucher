import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/voucher.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/item_provider.dart';
import '../../../providers/voucher_provider.dart';
import '../../login_screen.dart';
import '../voucher_form_screen.dart';

class VoucherManagementScreen extends StatefulWidget {
  const VoucherManagementScreen({super.key});

  @override
  State<VoucherManagementScreen> createState() => _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final voucherProvider = context.read<VoucherProvider>();
    _searchController.text = voucherProvider.searchQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final admin = auth.currentAdmin;
      if (admin == null || admin.id == null) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginScreen.routeName,
          (route) => false,
        );
        return;
      }
      await voucherProvider.refreshVouchers();
      await context.read<ItemProvider>().setAdmin(admin.id!);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<VoucherProvider>().setSearchQuery(value);
    });
  }

  Future<void> _pickDateRange(VoucherProvider provider) async {
    final now = DateTime.now();
    final initial = provider.expiryRange ??
        DateTimeRange(
          start: now,
          end: now.add(const Duration(days: 30)),
        );
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      await provider.setAdminExpiryRange(picked);
    }
  }

  Future<void> _openVoucherForm({Voucher? voucher}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VoucherFormScreen(
          adminId: context.read<AuthProvider>().currentAdmin!.id!,
          voucher: voucher,
        ),
      ),
    );
    if (result == true && mounted) {
      await context.read<VoucherProvider>().refreshVouchers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final voucherProvider = context.watch<VoucherProvider>();
    final itemProvider = context.watch<ItemProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final headerFooterColor = const Color(0xFF212121);

    final sortOptions = const [
      {'value': 'newest', 'label': 'Recently added'},
      {'value': 'highest_discount', 'label': 'Highest discount'},
      {'value': 'expiring_soon', 'label': 'Expiring soon'},
      {'value': 'price_low_high', 'label': 'Price: low to high'},
      {'value': 'price_high_low', 'label': 'Price: high to low'},
    ];

    final categories = itemProvider.items
        .map((item) => item.category?.trim())
        .whereType<String>()
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final vouchers = voucherProvider.vouchers;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: headerFooterColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Voucher Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'New voucher',
            icon: const Icon(Icons.add_card_outlined, color: Colors.white),
            onPressed: () => _openVoucherForm(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openVoucherForm(),
        icon: const Icon(Icons.add_outlined),
        label: const Text('Create voucher'),
      ),
      body: RefreshIndicator(
        onRefresh: voucherProvider.refreshVouchers,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Search vouchers, shops or codes',
                labelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in const ['all', 'active', 'redeemed', 'expired'])
                  ChoiceChip(
                    label: Text(status.toUpperCase()),
                    selected: voucherProvider.statusFilter == status,
                    onSelected: (_) => voucherProvider.setFilter(status),
                    selectedColor: colorScheme.primary,
                    labelStyle: TextStyle(
                      color: voucherProvider.statusFilter == status
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: voucherProvider.adminSort,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Sort vouchers by',
                labelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
                prefixIcon: Icon(Icons.sort_outlined, color: colorScheme.primary),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: sortOptions
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option['value'] as String,
                      child: Text(option['label'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  voucherProvider.setAdminSortOption(value);
                }
              },
            ),
            const SizedBox(height: 16),
            if (categories.isNotEmpty) ...[
              Text(
                'Filter by category',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
                  final lowered = category.toLowerCase();
                  final selected = voucherProvider.categoryFilters.contains(lowered);
                  return FilterChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) => voucherProvider.toggleCategoryFilter(category),
                    selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDateRange(voucherProvider),
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(
                      voucherProvider.expiryRange == null
                          ? 'Expiry window'
                          : '${DateFormat('dd MMM').format(voucherProvider.expiryRange!.start)} → ${DateFormat('dd MMM').format(voucherProvider.expiryRange!.end)}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () async {
                    _searchController.clear();
                    await voucherProvider.clearAdminFilters();
                  },
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Reset filters'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (voucherProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (vouchers.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.local_offer_outlined, size: 64, color: colorScheme.outline),
                    const SizedBox(height: 12),
                    const Text('No vouchers yet.'),
                    const SizedBox(height: 4),
                    const Text('Tap “Create voucher” to add your first offer.'),
                  ],
                ),
              )
            else
              ...vouchers.map((voucher) => _VoucherAdminCard(
                    voucher: voucher,
                    onEdit: () => _openVoucherForm(voucher: voucher),
                  )),
          ],
        ),
      ),
    );
  }
}

class _VoucherAdminCard extends StatelessWidget {
  const _VoucherAdminCard({required this.voucher, required this.onEdit});

  final Voucher voucher;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isExpired = voucher.expiryDate.isBefore(now);
    final status = voucher.status.toUpperCase();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    voucher.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? colorScheme.error.withValues(alpha: 0.15)
                        : colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isExpired ? colorScheme.error : colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(voucher.shopName, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '${voucher.code} • Expires ${DateFormat('dd MMM yyyy').format(voucher.expiryDate)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PriceBadge(
                  label: 'Original',
                  value: voucher.originalPrice,
                  color: colorScheme.outlineVariant,
                ),
                const SizedBox(width: 8),
                _PriceBadge(
                  label: 'Now',
                  value: voucher.discountedPrice,
                  color: colorScheme.primary,
                  highlight: true,
                ),
              ],
            ),
            if (voucher.category != null && voucher.category!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Chip(
                  avatar: const Icon(Icons.category_outlined, size: 16),
                  label: Text(voucher.category!),
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final double value;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatted = NumberFormat.simpleCurrency().format(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: highlight ? color : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            formatted,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: highlight ? color : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
