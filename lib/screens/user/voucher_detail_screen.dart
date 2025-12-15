import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/voucher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/voucher_provider.dart';

class VoucherDetailScreen extends StatefulWidget {
  const VoucherDetailScreen({super.key, required this.voucher});

  final Voucher voucher;

  @override
  State<VoucherDetailScreen> createState() => _VoucherDetailScreenState();
}

class _VoucherDetailScreenState extends State<VoucherDetailScreen> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  bool _isRedeeming = false;

  Future<void> _handleRedeem(BuildContext context, Voucher voucher) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      return;
    }
    setState(() => _isRedeeming = true);
    final voucherProvider = context.read<VoucherProvider>();
    final error = await voucherProvider.redeemVoucher(
          userId: user.id!,
          voucher: voucher,
        );
    setState(() => _isRedeeming = false);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voucher ${voucher.code} marked for redemption.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final voucherProvider = context.watch<VoucherProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final voucher = widget.voucher;
    final gallery = voucher.gallery.isNotEmpty
        ? voucher.gallery
        : voucher.imagePath != null
            ? [voucher.imagePath!]
            : <String>[];
    final isFavorite = voucherProvider.favoriteVoucherIds.contains(voucher.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(voucher.name),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: user == null || voucher.id == null
                ? null
                : () => context.read<VoucherProvider>().toggleFavorite(
                      userId: user.id!,
                      voucher: voucher,
                    ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (gallery.isNotEmpty)
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: gallery.length,
                itemBuilder: (context, index) {
                  final path = gallery[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(path),
                      width: 280,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 280,
                        height: 220,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Text('No images available'),
            ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(voucher.shopName),
                        Text(voucher.shopAddress),
                        if ((voucher.contactName?.isNotEmpty ?? false) ||
                            (voucher.contactPhone?.isNotEmpty ?? false))
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              [
                                if (voucher.contactName != null &&
                                    voucher.contactName!.isNotEmpty)
                                  voucher.contactName!,
                                if (voucher.contactPhone != null &&
                                    voucher.contactPhone!.isNotEmpty)
                                  voucher.contactPhone!,
                              ].join(' • '),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  QrImageView(
                    data: voucher.code,
                    size: 120,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pricing', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        voucher.originalPrice.toStringAsFixed(2),
                        style: const TextStyle(decoration: TextDecoration.lineThrough),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        voucher.discountedPrice.toStringAsFixed(2),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Discount: ${voucher.discountValue.toStringAsFixed(0)}${voucher.discountType == 'percentage' ? '%' : ''}',
                  ),
                  const SizedBox(height: 6),
                  Text('Usage limit: ${voucher.usageLimit}'),
                  const SizedBox(height: 6),
                  Text('Valid until ${_dateFormat.format(voucher.expiryDate)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Terms & conditions', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  const Text(
                    'Redeem this voucher at the counter before it expires. Offer not combinable with other promotions unless stated otherwise.',
                  ),
                  const SizedBox(height: 12),
                  Text('Voucher code: ${voucher.code}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isRedeeming
                ? null
                : () => _handleRedeem(context, voucher),
            icon: _isRedeeming
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.redeem_outlined),
            label: const Text('Redeem at store'),
          ),
        ],
      ),
    );
  }
}
