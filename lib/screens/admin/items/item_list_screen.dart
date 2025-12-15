import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/item.dart';
import '../../../providers/item_provider.dart';
import 'item_form_screen.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key, required this.adminId});

  static const routeName = '/admin/items';
  final int adminId;

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  bool _showInactive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ItemProvider>();
      await provider.setAdmin(widget.adminId);
      await provider.loadItems(includeInactive: _showInactive);
    });
  }

  Future<void> _openForm({Item? item}) async {
    final provider = context.read<ItemProvider>();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(adminId: widget.adminId, item: item),
      ),
    );
    if (changed == true && mounted) {
      await provider.loadItems(includeInactive: _showInactive);
    }
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
          'Items Catalog',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final provider = context.read<ItemProvider>();
              setState(() => _showInactive = !_showInactive);
              await provider.loadItems(includeInactive: _showInactive);
            },
            icon: Icon(
              _showInactive ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            label: Text(
              _showInactive ? 'Hide inactive' : 'Show inactive',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: Consumer<ItemProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.items.isEmpty) {
            return const Center(
              child: Text('No items available. Tap + to create one.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadItems(includeInactive: _showInactive),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = provider.items[index];
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
                      leading: item.imagePath == null
                          ? CircleAvatar(
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                              child: Text(
                                item.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(item.imagePath!),
                                height: 52,
                                width: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                              ),
                            ),
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.category != null && item.category!.isNotEmpty)
                          Text('Category: ${item.category}'),
                        Text(
                          '${item.discountedPrice.toStringAsFixed(2)} • saved ${(item.originalPrice - item.discountedPrice).toStringAsFixed(2)}',
                        ),
                        Text(item.isActive ? 'Active' : 'Inactive'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _openForm(item: item);
                        } else if (value == 'toggle') {
                          await provider.toggleItemActive(
                            itemId: item.id!,
                            isActive: !item.isActive,
                          );
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete item'),
                              content: Text('Remove ${item.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await provider.deleteItem(item.id!);
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(item.isActive ? 'Deactivate' : 'Activate'),
                        ),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: provider.items.length,
            ),
          );
        },
      ),
    );
  }
}
