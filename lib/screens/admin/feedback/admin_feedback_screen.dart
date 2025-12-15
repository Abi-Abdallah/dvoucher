import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/database_helper.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  static const routeName = '/admin/feedback';

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _feedback = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final admin = context.read<AuthProvider>().currentAdmin;
      if (admin != null && admin.id != null) {
        await _loadFeedback(admin.id!);
      }
    });
  }

  Future<void> _loadFeedback(int adminId) async {
    setState(() => _isLoading = true);
    final results = await DatabaseHelper.instance.getAllFeedback(adminId: adminId);
    setState(() {
      _feedback = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthProvider>().currentAdmin;
    final colorScheme = Theme.of(context).colorScheme;
    final df = DateFormat('dd MMM yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('User feedback'),
        actions: [
          IconButton(
            onPressed: admin?.id == null
                ? null
                : () => _loadFeedback(admin!.id!),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _feedback.isEmpty
              ? const Center(child: Text('No feedback submitted yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final entry = _feedback[index];
                    final rating = (entry['rating'] as num?)?.toInt() ?? 0;
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry['voucher_name'] as String? ?? 'Voucher',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(df.format(DateTime.parse(entry['date'] as String))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(entry['comment'] as String? ?? '-'),
                            const SizedBox(height: 12),
                            Text('User: ${entry['user_name'] ?? 'Anonymous'}'),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _feedback.length,
                ),
    );
  }
}
