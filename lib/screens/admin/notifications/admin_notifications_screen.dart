import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/app_notification.dart';
import '../../../providers/notification_provider.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  static const routeName = '/admin/notifications';

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadAllNotificationsForAdmin();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSending = true);
    final provider = context.read<NotificationProvider>();
    final result = await provider.sendNotificationToAll(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      type: 'admin',
    );
    setState(() => _isSending = false);
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    } else {
      _titleController.clear();
      _bodyController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Notification sent.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final df = DateFormat('dd MMM yyyy • HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications center'),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.mark_email_read_outlined),
            onPressed: () => context.read<NotificationProvider>().markAllRead(),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final notifications = provider.notifications;
          return RefreshIndicator(
            onRefresh: () => provider.loadAllNotificationsForAdmin(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send broadcast notification',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              prefixIcon: Icon(Icons.title_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Title is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _bodyController,
                            decoration: const InputDecoration(
                              labelText: 'Message',
                              prefixIcon: Icon(Icons.message_outlined),
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Message body is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isSending ? null : _sendBroadcast,
                              icon: _isSending
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_outlined),
                              label: const Text('Send notification'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (notifications.isEmpty)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No notifications created yet.'),
                      ),
                    ),
                  )
                else
                  ...notifications.map((notification) => _NotificationTile(
                        notification: notification,
                        dateFormat: df,
                        colorScheme: colorScheme,
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.dateFormat,
    required this.colorScheme,
  });

  final AppNotification notification;
  final DateFormat dateFormat;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(
          notification.isRead ? Icons.notifications_none : Icons.notifications_active,
          color: notification.isRead ? colorScheme.outline : colorScheme.primary,
        ),
        title: Text(notification.title),
        subtitle: Text(notification.body),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(dateFormat.format(notification.createdAt)),
            const SizedBox(height: 4),
            Text(notification.type?.toUpperCase() ?? 'broadcast'),
          ],
        ),
        onTap: () => context.read<NotificationProvider>().markAsRead(notification.id!),
      ),
    );
  }
}

