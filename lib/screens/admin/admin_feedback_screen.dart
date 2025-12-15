import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/database_helper.dart';

class AdminFeedbackScreen extends StatelessWidget {
  const AdminFeedbackScreen({super.key, required this.adminId});

  static const routeName = '/admin/feedback';

  final int adminId;

  Future<List<Map<String, dynamic>>> _loadFeedback() {
    return DatabaseHelper.instance.getAllFeedback(adminId: adminId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback & suggestions')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadFeedback(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading feedback: ${snapshot.error}'));
          }
          final feedback = snapshot.data ?? [];
          if (feedback.isEmpty) {
            return const Center(child: Text('No feedback has been submitted yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final entry = feedback[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(entry['rating']?.toString() ?? '-'),
                  ),
                  title: Text(entry['voucher_name'] as String? ?? 'Voucher'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry['comment'] as String? ?? ''),
                      const SizedBox(height: 6),
                      Text('By ${entry['user_name'] ?? 'Unknown'}'),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm')
                            .format(DateTime.parse(entry['date'] as String)),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: feedback.length,
          );
        },
      ),
    );
  }
}
