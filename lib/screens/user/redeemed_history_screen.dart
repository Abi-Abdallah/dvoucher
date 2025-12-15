import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/voucher_provider.dart';
import 'feedback_screen.dart';

class RedeemedHistoryScreen extends StatefulWidget {
  const RedeemedHistoryScreen({super.key, required this.userId});

  final int userId;

  @override
  State<RedeemedHistoryScreen> createState() => _RedeemedHistoryScreenState();
}

class _RedeemedHistoryScreenState extends State<RedeemedHistoryScreen> {
  final _dateFormat = DateFormat('dd MMM yyyy – HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<VoucherProvider>()
          .loadRedeemedHistory(userId: widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redemption history')),
      body: Consumer<VoucherProvider>(
        builder: (context, provider, _) {
          final history = provider.redeemedHistory;

          if (history.isEmpty) {
            return const Center(
              child: Text('You have not redeemed any vouchers yet.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final entry = history[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.card_giftcard_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.voucherName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Chip(label: Text(entry.status)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Code: ${entry.voucherCode}'),
                      Text('Shop: ${entry.shopName}'),
                      Text('Address: ${entry.shopAddress}'),
                      Text('Redeemed on: ${_dateFormat.format(entry.dateRedeemed)}'),
                      Text(
                        'Price: ${entry.originalPrice.toStringAsFixed(2)} ➜ ${entry.discountedPrice.toStringAsFixed(2)}',
                      ),
                      if (entry.redeemedBy != null)
                        Text('Confirmed by: ${entry.redeemedBy}'),
                      if (entry.note != null && entry.note!.isNotEmpty)
                        Text('Note: ${entry.note}'),
                      const SizedBox(height: 12),
                      if (entry.status == 'Confirmed')
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              final result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => FeedbackScreen(
                                    voucherId: entry.voucherId,
                                    voucherName: entry.voucherName,
                                  ),
                                ),
                              );
                              if (result == true && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Feedback sent.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.feedback_outlined),
                            label: const Text('Leave feedback'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: history.length,
          );
        },
      ),
    );
  }
}

