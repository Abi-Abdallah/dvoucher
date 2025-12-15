import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/user_management_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  static const routeName = '/admin/users';

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _includeInactive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementProvider>().loadUsers(includeInactive: _includeInactive);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('User management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<UserManagementProvider>()
                .loadUsers(includeInactive: _includeInactive),
          ),
        ],
      ),
      body: Consumer<UserManagementProvider>(
        builder: (context, provider, _) {
          final users = provider.users;
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community overview',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text('${users.length} users • ${provider.activeUserCount} active'),
                        ],
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _includeInactive,
                        title: const Text('Show inactive'),
                        onChanged: (value) {
                          setState(() => _includeInactive = value);
                          provider.loadUsers(includeInactive: value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (users.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No users to display.'),
                    ),
                  ),
                )
              else
                ...users.map((user) {
                  final redeemed = provider.redeemedCountFor(user.id);
                  final subtitle = StringBuffer('Email: ${user.email}\n');
                  subtitle.write('Redeemed vouchers: $redeemed');
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
                      ),
                      title: Text(user.name),
                      subtitle: Text(subtitle.toString()),
                      trailing: Switch(
                        value: user.isActive,
                        onChanged: (value) => provider.toggleUserActive(
                          userId: user.id!,
                          isActive: value,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
