import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/item.dart';
import '../../../providers/item_provider.dart';

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, required this.adminId, this.item});

  final int adminId;
  final Item? item;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _imagePath;
  bool _isSaving = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _nameController.text = item.name;
      _descriptionController.text = item.description ?? '';
      _categoryController.text = item.category ?? '';
      _originalPriceController.text = item.originalPrice.toStringAsFixed(2);
      _discountedPriceController.text = item.discountedPrice.toStringAsFixed(2);
      _imagePath = item.imagePath;
      _isActive = item.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _imagePath = image.path);
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    final provider = context.read<ItemProvider>();
    final adminId = widget.item?.adminId ?? widget.adminId;

    final originalPrice = double.tryParse(_originalPriceController.text.replaceAll(',', '.'));
    final discountedPrice =
        double.tryParse(_discountedPriceController.text.replaceAll(',', '.'));
    if (originalPrice == null || discountedPrice == null) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid price values.')),
      );
      return;
    }

    final now = DateTime.now();
    final item = Item(
      id: widget.item?.id,
      adminId: adminId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      originalPrice: originalPrice,
      discountedPrice: discountedPrice,
      imagePath: _imagePath,
      isActive: _isActive,
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
    );

    String? error;
    if (widget.item == null) {
      error = await provider.addItem(item);
    } else {
      error = await provider.updateItem(item);
    }

    setState(() => _isSaving = false);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit item' : 'Create item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                title: const Text('Item active'),
                subtitle: const Text('Inactive items will not be available for new vouchers'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item name',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _originalPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Original price',
                  prefixIcon: Icon(Icons.attach_money_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the original price';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountedPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Discounted price',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the discounted price';
                  }
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null) {
                    return 'Enter a valid number';
                  }
                  final original = double.tryParse(_originalPriceController.text.replaceAll(',', '.'));
                  if (original != null && parsed > original) {
                    return 'Discounted price should be lower than original price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Product image',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                      controller: TextEditingController(text: _imagePath ?? ''),
                      onTap: _pickImage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Upload'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    File(_imagePath!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveItem,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isEditing ? 'Save changes' : 'Create item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
