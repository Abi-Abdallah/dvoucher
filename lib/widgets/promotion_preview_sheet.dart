import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/promotion.dart';
import '../models/voucher.dart';

class PromotionPreviewSheet extends StatelessWidget {
  const PromotionPreviewSheet({super.key, required this.promotion, required this.voucherLookup});

  final Promotion promotion;
  final Map<int, Voucher> voucherLookup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final linkedVouchers = promotion.voucherIds
        .map((id) => voucherLookup[id])
        .whereType<Voucher>()
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promotion preview',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          PromotionPreviewHeroCard(promotion: promotion),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Schedule'),
            subtitle: Text(
              '${MaterialLocalizations.of(context).formatFullDate(promotion.startDate)} → ${MaterialLocalizations.of(context).formatFullDate(promotion.endDate)}',
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined),
            title: Text(promotion.shopName),
            subtitle: Text(promotion.shopAddress),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.visibility_outlined),
            title: const Text('Placement'),
            subtitle: Text([
              if (promotion.showOnHome) 'Home dashboard',
              if (promotion.showOnVoucher) 'Voucher browser',
            ].join(' • ')),
          ),
          if (linkedVouchers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Linked vouchers', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: linkedVouchers
                  .map(
                    (voucher) => Chip(
                      avatar: const Icon(Icons.local_offer_outlined, size: 16),
                      label: Text(voucher.name),
                    ),
                  )
                  .toList(),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No vouchers linked yet. Link vouchers to measure campaign engagement.',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 16),
          if (promotion.contactName != null || promotion.contactPhone != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.support_agent_outlined),
              title: Text(promotion.contactName ?? 'Contact'),
              subtitle: Text(promotion.contactPhone ?? 'No phone provided'),
            ),
        ],
      ),
    );
  }
}

class PromotionPreviewHeroCard extends StatelessWidget {
  const PromotionPreviewHeroCard({super.key, required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imagePath = promotion.gallery.isNotEmpty
        ? promotion.gallery.first
        : promotion.imagePath;
    final heroImage = imagePath != null && imagePath.isNotEmpty
        ? File(imagePath)
        : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: heroImage != null && heroImage.existsSync()
            ? DecorationImage(
                image: FileImage(heroImage),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  colorScheme.surface.withValues(alpha: 0.35),
                  BlendMode.srcOver,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              promotion.shopName,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            promotion.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            promotion.description,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_month_outlined,
                  color: colorScheme.onSurfaceVariant, size: 16),
              const SizedBox(width: 6),
              Text(
                '${DateFormat('dd MMM').format(promotion.startDate)} · ${DateFormat('dd MMM').format(promotion.endDate)}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
