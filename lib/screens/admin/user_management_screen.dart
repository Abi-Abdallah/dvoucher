import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_management_provider.dart';

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
    final headerFooterColor = const Color(0xFF212121);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: headerFooterColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'User Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _includeInactive ? 'Hide inactive users' : 'Show inactive users',
            icon: Icon(
              _includeInactive ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            onPressed: () async {
              setState(() => _includeInactive = !_includeInactive);
              await context
                  .read<UserManagementProvider>()
                  .loadUsers(includeInactive: _includeInactive);
            },
          ),
        ],
      ),
      body: Consumer<UserManagementProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.users.isEmpty) {
            return const Center(child: Text('No users registered yet.'));
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadUsers(includeInactive: _includeInactive),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final user = provider.users[index];
                final colorScheme = Theme.of(context).colorScheme;
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                        child: Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isActive
                                  ? colorScheme.primary.withValues(alpha: 0.15)
                                  : colorScheme.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.isActive ? 'Active' : 'Suspended',
                              style: TextStyle(
                                color: user.isActive ? colorScheme.primary : colorScheme.error,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Switch(
                        value: user.isActive,
                        onChanged: (value) => provider.toggleUserActive(
                          userId: user.id!,
                          isActive: value,
                        ),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: provider.users.length,
            ),
          );
        },
      ),
    );
  }
}
