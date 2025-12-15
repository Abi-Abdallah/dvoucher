import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin_dashboard_provider.dart';
import '../../../providers/auth_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  static const routeName = '/admin/reports';

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AdminDashboardProvider>();
      final admin = context.read<AuthProvider>().currentAdmin;
      if (admin != null && admin.id != null) {
        auth.loadDashboard(admin.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd MMM yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & analytics'),
        actions: [
          IconButton(
            tooltip: 'Export (coming soon)',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export functionality coming soon!')),
            ),
          ),
        ],
      ),
      body: Consumer<AdminDashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final summary = provider.summary;
          final topItems = provider.topItems;
          final topVouchers = provider.topVouchers;
          final redemptions = provider.recentRedemptions;

          return RefreshIndicator(
            onRefresh: () async {
              final admin = context.read<AuthProvider>().currentAdmin;
              if (admin != null && admin.id != null) {
                await provider.loadDashboard(admin.id!);
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ReportCard(
                  title: 'Performance overview',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricTile(
                        icon: Icons.card_giftcard_outlined,
                        label: 'Total vouchers',
                        value: '${summary['totalVouchers'] ?? 0}',
                        color: colorScheme.primary,
                      ),
                      _MetricTile(
                        icon: Icons.verified_outlined,
                        label: 'Confirmed redemptions',
                        value: '${summary['totalRedeemed'] ?? 0}',
                        color: colorScheme.tertiary,
                      ),
                      _MetricTile(
                        icon: Icons.celebration_outlined,
                        label: 'Active promotions',
                        value: '${summary['activePromotions'] ?? 0}',
                        color: colorScheme.secondary,
                      ),
                      _MetricTile(
                        icon: Icons.people_alt_outlined,
                        label: 'Active users',
                        value: '${summary['activeUsers'] ?? 0}',
                        color: colorScheme.surfaceTint,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ReportCard(
                  title: 'Top redeemed vouchers',
                  child: topVouchers.isEmpty
                      ? const Text('No redemption data yet.')
                      : Column(
                          children: topVouchers
                              .map(
                                (entry) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: colorScheme.primaryContainer,
                                    child: Text('${topVouchers.indexOf(entry) + 1}'),
                                  ),
                                  title: Text(entry['name'] as String),
                                  trailing: Text('${entry['total']} confirmations'),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _ReportCard(
                  title: 'Top selling items',
                  child: topItems.isEmpty
                      ? const Text('No item redemptions yet.')
                      : Column(
                          children: topItems
                              .map(
                                (entry) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: colorScheme.secondaryContainer,
                                    child: Text('${topItems.indexOf(entry) + 1}'),
                                  ),
                                  title: Text(entry['item_name'] as String? ?? 'Item'),
                                  trailing: Text('${entry['total']} redemptions'),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _ReportCard(
                  title: 'Recent redemptions',
                  child: redemptions.isEmpty
                      ? const Text('No redemption history yet.')
                      : Column(
                          children: redemptions
                              .take(8)
                              .map(
                                (entry) => ListTile(
                                  leading: const Icon(Icons.receipt_long_outlined),
                                  title: Text(entry.voucherName),
                                  subtitle: Text(
                                    '${entry.shopName} • ${dateFormat.format(entry.dateRedeemed)}',
                                  ),
                                  trailing: Text(entry.status),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(label),
        ],
      ),
    );
  }
}
