import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shop.dart';
import '../../providers/shop_provider.dart';

class ShopFormScreen extends StatefulWidget {
  const ShopFormScreen({super.key, required this.adminId, this.shop});

  final int adminId;
  final Shop? shop;

  @override
  State<ShopFormScreen> createState() => _ShopFormScreenState();
}

class _ShopFormScreenState extends State<ShopFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _logoController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final shop = widget.shop;
    if (shop != null) {
      _nameController.text = shop.name;
      _addressController.text = shop.address;
      _contactController.text = shop.contactNumber;
      _logoController.text = shop.logoPath ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final shop = Shop(
      id: widget.shop?.id,
      adminId: widget.adminId,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      contactNumber: _contactController.text.trim(),
      logoPath: _logoController.text.trim().isEmpty
          ? null
          : _logoController.text.trim(),
    );

    final provider = context.read<ShopProvider>();
    String? error;
    if (widget.shop == null) {
      error = await provider.addShop(shop);
    } else {
      error = await provider.updateShop(shop);
    }

    setState(() => _isSubmitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.shop != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit shop' : 'Add shop'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Shop name',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Shop name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact number',
                  prefixIcon: Icon(Icons.call_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Contact number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _logoController,
                decoration: const InputDecoration(
                  labelText: 'Logo path (optional)',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _save,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Save changes' : 'Create shop'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

