import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/promotion.dart';
import '../../../models/voucher.dart';
import '../../../providers/promotion_provider.dart';
import '../../../providers/voucher_provider.dart';
import '../../../widgets/promotion_preview_sheet.dart';
import 'promotion_form_screen.dart';

class PromotionsListScreen extends StatefulWidget {
  const PromotionsListScreen({super.key});

  static const routeName = '/admin/promotions';

  @override
  State<PromotionsListScreen> createState() => _PromotionsListScreenState();
}

class _PromotionsListScreenState extends State<PromotionsListScreen> {
  String _statusFilter = 'all';
  bool _filterHome = false;
  bool _filterVoucher = false;

  Future<void> _openPromotionForm({Promotion? promotion}) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => PromotionFormScreen(
          promotion: promotion,
        ),
      ),
    );
    if (!mounted || result != true) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          promotion == null
              ? 'Promotion created successfully.'
              : 'Promotion updated successfully.',
        ),
      ),
    );
  }

  Future<void> _showPreview(Promotion promotion) async {
    final voucherProvider = context.read<VoucherProvider>();
    if (voucherProvider.vouchers.isEmpty) {
      await voucherProvider.refreshVouchers();
    }
    if (!mounted) return;
    final voucherLookup = <int, Voucher>{
      for (final voucher in voucherProvider.vouchers)
        if (voucher.id != null) voucher.id!: voucher,
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => PromotionPreviewSheet(
        promotion: promotion,
        voucherLookup: voucherLookup,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromotionProvider>().refreshPromotions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final headerFooterColor = const Color(0xFF212121);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: headerFooterColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Promotions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'New promotion',
            icon: const Icon(Icons.campaign_outlined, color: Colors.white),
            onPressed: () => _openPromotionForm(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPromotionForm(),
        icon: const Icon(Icons.add_outlined),
        label: const Text('Create promotion'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PromotionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final promotions = provider.promotions;
          final analytics = provider.analytics;
          final performance = provider.performance;
          final now = DateTime.now();
          final filteredPromotions = promotions.where((promotion) {
            final isActive = !promotion.startDate.isAfter(now) && !promotion.endDate.isBefore(now);
            final isUpcoming = promotion.startDate.isAfter(now);
            final isExpired = promotion.endDate.isBefore(now);

            final statusMatch = switch (_statusFilter) {
              'active' => isActive,
              'upcoming' => isUpcoming,
              'expired' => isExpired,
              _ => true,
            };

            final placementMatch = (!_filterHome || promotion.showOnHome) &&
                (!_filterVoucher || promotion.showOnVoucher);

            return statusMatch && placementMatch;
          }).toList();

          return RefreshIndicator(
            onRefresh: provider.refreshPromotions,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AnalyticsTile(
                  color: colorScheme.primaryContainer,
                  icon: Icons.campaign_outlined,
                  title: 'Total promotions',
                  value: analytics['total']?.toString() ?? '0',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _AnalyticsTile(
                        color: colorScheme.secondaryContainer,
                        icon: Icons.flash_on_outlined,
                        title: 'Active',
                        value: analytics['active']?.toString() ?? '0',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AnalyticsTile(
                        color: colorScheme.tertiaryContainer,
                        icon: Icons.schedule_outlined,
                        title: 'Upcoming',
                        value: analytics['upcoming']?.toString() ?? '0',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AnalyticsTile(
                        color: colorScheme.errorContainer,
                        icon: Icons.history_outlined,
                        title: 'Expired',
                        value: analytics['expired']?.toString() ?? '0',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final status in ['all', 'active', 'upcoming', 'expired'])
                      FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_statusFilter == status) ...[
                              const Icon(Icons.check, size: 18, color: Colors.white),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              status[0].toUpperCase() + status.substring(1),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _statusFilter == status ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        selected: _statusFilter == status,
                        onSelected: (_) => setState(() => _statusFilter = status),
                        selectedColor: colorScheme.primary,
                        checkmarkColor: Colors.transparent,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: _statusFilter == status 
                              ? colorScheme.primary 
                              : colorScheme.outline.withValues(alpha: 0.3),
                          width: _statusFilter == status ? 2 : 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        elevation: _statusFilter == status ? 4 : 0,
                        pressElevation: 2,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_filterHome) ...[
                            const Icon(Icons.check, size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                          ],
                          const Text(
                            'Home spotlight',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      selected: _filterHome,
                      onSelected: (value) => setState(() => _filterHome = value),
                      selectedColor: colorScheme.primary,
                      checkmarkColor: Colors.transparent,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _filterHome ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide(
                        color: _filterHome 
                            ? colorScheme.primary 
                            : colorScheme.outline.withValues(alpha: 0.3),
                        width: _filterHome ? 2 : 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      elevation: _filterHome ? 4 : 0,
                      pressElevation: 2,
                    ),
                    FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_filterVoucher) ...[
                            const Icon(Icons.check, size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                          ],
                          const Text(
                            'Voucher pages',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      selected: _filterVoucher,
                      onSelected: (value) => setState(() => _filterVoucher = value),
                      selectedColor: colorScheme.primary,
                      checkmarkColor: Colors.transparent,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _filterVoucher ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide(
                        color: _filterVoucher 
                            ? colorScheme.primary 
                            : colorScheme.outline.withValues(alpha: 0.3),
                        width: _filterVoucher ? 2 : 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      elevation: _filterVoucher ? 4 : 0,
                      pressElevation: 2,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (promotions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.campaign_outlined,
                              size: 72,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'No promotions yet.',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap the megaphone icon to create one.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (filteredPromotions.isEmpty)
                  Center(
                    child: Column(
                      children: const [
                        Icon(Icons.filter_alt_off_outlined, size: 48),
                        SizedBox(height: 8),
                        Text('No promotions match your filters.'),
                      ],
                    ),
                  )
                else
                  ...filteredPromotions.map((promotion) => _PromotionCard(
                        promotion: promotion,
                        metrics: performance[promotion.id ?? -1],
                        onPreview: () => _showPreview(promotion),
                        onEdit: () => _openPromotionForm(promotion: promotion),
                        onDelete: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete promotion'),
                              content: Text(
                                'Remove promotion "${promotion.title}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            if (promotion.id != null) {
                              await provider.deletePromotion(promotion.id!);
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Promotion deleted.'),
                              ),
                            );
                          }
                        },
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnalyticsTile extends StatelessWidget {
  const _AnalyticsTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Extract icon color based on container color
    final iconColor = color == colorScheme.primaryContainer
        ? colorScheme.primary
        : (color == colorScheme.secondaryContainer
            ? colorScheme.secondary
            : (color == colorScheme.tertiaryContainer
                ? colorScheme.tertiary
                : colorScheme.error));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.promotion,
    required this.onPreview,
    required this.onEdit,
    required this.onDelete,
    this.metrics,
  });

  final Promotion promotion;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Map<String, dynamic>? metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final status = now.isBefore(promotion.startDate)
        ? 'Upcoming'
        : now.isAfter(promotion.endDate)
            ? 'Expired'
            : 'Active';
    final statusColor = {
      'Active': colorScheme.primary,
      'Upcoming': colorScheme.secondary,
      'Expired': colorScheme.error,
    }[status]!
        .withValues(alpha: 0.15);
    final impressions = (metrics?['impressions'] as num?)?.toInt() ?? promotion.impressions;
    final clicks = (metrics?['clicks'] as num?)?.toInt() ?? promotion.clicks;
    final linked = (metrics?['linkedVouchers'] as num?)?.toInt() ?? promotion.voucherIds.length;
    final redemptions = (metrics?['confirmedRedemptions'] as num?)?.toInt() ?? 0;
    final engagementRate = (metrics?['engagementRate'] as num?)?.toDouble() ??
        promotion.engagementRate;
    final engagementLabel = engagementsLabel(engagementRate);

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
                    promotion.title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              promotion.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (promotion.showOnHome)
                  Chip(
                    avatar: const Icon(Icons.home_outlined, size: 16),
                    label: const Text('Home spotlight'),
                  ),
                if (promotion.showOnVoucher)
                  Chip(
                    avatar: const Icon(Icons.view_compact_outlined, size: 16),
                    label: const Text('Voucher pages'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.date_range_outlined, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${MaterialLocalizations.of(context).formatShortDate(promotion.startDate)} → ${MaterialLocalizations.of(context).formatShortDate(promotion.endDate)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricPill(
                  icon: Icons.remove_red_eye_outlined,
                  label: 'Impressions',
                  value: impressions.toString(),
                ),
                _MetricPill(
                  icon: Icons.touch_app_outlined,
                  label: 'Clicks',
                  value: clicks.toString(),
                ),
                _MetricPill(
                  icon: Icons.percent_outlined,
                  label: 'Engagement',
                  value: engagementLabel,
                ),
                _MetricPill(
                  icon: Icons.link_outlined,
                  label: 'Linked',
                  value: linked.toString(),
                ),
                if (redemptions > 0)
                  _MetricPill(
                    icon: Icons.verified_outlined,
                    label: 'Redemptions',
                    value: redemptions.toString(),
                  ),
              ],
            ),
            if ((promotion.contactName?.isNotEmpty ?? false) ||
                (promotion.contactPhone?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        [
                          if (promotion.contactName != null &&
                              promotion.contactName!.isNotEmpty)
                            promotion.contactName!,
                          if (promotion.contactPhone != null &&
                              promotion.contactPhone!.isNotEmpty)
                            promotion.contactPhone!,
                        ].join(' • '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            if (promotion.imagePath != null && promotion.imagePath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(promotion.imagePath!),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Preview'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String engagementsLabel(double rate) {
  if (rate.isNaN || rate.isInfinite) {
    return '0%';
  }
  return '${(rate * 100).clamp(0, 9999).toStringAsFixed(1)}%';
}
