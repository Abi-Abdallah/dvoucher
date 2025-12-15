import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shop.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import 'shop_form_screen.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({super.key});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AuthProvider>().currentAdmin;
      if (admin != null && admin.id != null) {
        context.read<ShopProvider>().loadShops(admin.id!);
      }
    });
  }

  Future<void> _openForm({Shop? shop}) async {
    final admin = context.read<AuthProvider>().currentAdmin;
    if (admin == null || admin.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShopFormScreen(adminId: admin.id!, shop: shop),
      ),
    );
  }

  Future<void> _deleteShop(int shopId) async {
    final admin = context.read<AuthProvider>().currentAdmin;
    if (admin == null || admin.id == null) {
      return;
    }
    await context
        .read<ShopProvider>()
        .deleteShop(shopId: shopId, adminId: admin.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shop removed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = context.watch<ShopProvider>();
    final shops = shopProvider.shops;
    final headerFooterColor = const Color(0xFF212121);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: headerFooterColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Shops',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_business),
        label: const Text('Add shop'),
      ),
      body: shopProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shops.isEmpty
              ? const Center(
                  child: Text('No shops yet. Tap + to create your first shop.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final shop = shops[index];
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
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.storefront_outlined,
                              color: colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            shop.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: Colors.black54),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      shop.address,
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined, size: 14, color: Colors.black54),
                                  const SizedBox(width: 4),
                                  Text(
                                    shop.contactNumber,
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openForm(shop: shop);
                            } else if (value == 'delete') {
                              _deleteShop(shop.id!);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: shops.length,
              ),
    );
  }
}

