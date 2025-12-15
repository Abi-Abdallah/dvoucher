import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/voucher.dart';
import '../../providers/voucher_provider.dart';

class VoucherFormScreen extends StatefulWidget {
  const VoucherFormScreen({super.key, required this.adminId, this.voucher});

  final int adminId;
  final Voucher? voucher;

  static const routeName = '/admin/voucher-form';

  @override
  State<VoucherFormScreen> createState() => _VoucherFormScreenState();
}

class _VoucherFormScreenState extends State<VoucherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _usageLimitController = TextEditingController(text: '1');
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _imagePaths = [];

  late String _status;
  late String _discountType;
  double _discountedPrice = 0;
  DateTime? _expiryDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final voucher = widget.voucher;
    if (voucher != null) {
      _nameController.text = voucher.name;
      _codeController.text = voucher.code;
      _originalPriceController.text = voucher.originalPrice.toStringAsFixed(2);
      _discountController.text = voucher.discountValue.toStringAsFixed(2);
      _usageLimitController.text = voucher.usageLimit.toString();
      _shopNameController.text = voucher.shopName;
      _shopAddressController.text = voucher.shopAddress;
      _contactNameController.text = voucher.contactName ?? '';
      _contactPhoneController.text = voucher.contactPhone ?? '';
      if (voucher.gallery.isNotEmpty) {
        _imagePaths.addAll(voucher.gallery);
      } else if (voucher.imagePath != null && voucher.imagePath!.isNotEmpty) {
        _imagePaths.add(voucher.imagePath!);
      }
      _status = voucher.status;
      _discountType = voucher.discountType;
      _discountedPrice = voucher.discountedPrice;
      _expiryDate = voucher.expiryDate;
    } else {
      _status = 'active';
      _discountType = 'percentage';
      _expiryDate = DateTime.now().add(const Duration(days: 30));
    }

    _originalPriceController.addListener(_recalculateDiscountedPrice);
    _discountController.addListener(_recalculateDiscountedPrice);
    _recalculateDiscountedPrice();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _originalPriceController.dispose();
    _discountController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _usageLimitController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final initialDate = _expiryDate?.isAfter(now) == true ? _expiryDate! : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _pickImages() async {
    final results = await _imagePicker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (results.isEmpty) {
      return;
    }
    setState(() {
      final newPaths = results
          .map((file) => file.path)
          .where((path) => !_imagePaths.contains(path))
          .toList();
      _imagePaths.addAll(newPaths);
    });
  }

  void _removeImageAt(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_expiryDate == null) {
      _showSnackBar('Please choose an expiry date.');
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<VoucherProvider>();

    final originalPrice =
        double.tryParse(_originalPriceController.text.replaceAll(',', '.'));
    final discount =
        double.tryParse(_discountController.text.replaceAll(',', '.'));
    final usageLimit = int.tryParse(_usageLimitController.text.trim());

    if (originalPrice == null || originalPrice <= 0) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Enter a valid original price.');
      return;
    }
    if (discount == null || discount < 0) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Enter a valid discount amount.');
      return;
    }
    if (usageLimit == null || usageLimit <= 0) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Usage limit must be a positive number.');
      return;
    }
    final shopName = _shopNameController.text.trim();
    final shopAddress = _shopAddressController.text.trim();
    if (shopName.isEmpty || shopAddress.isEmpty) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Please provide shop name and address.');
      return;
    }

    final discountedPrice = _calculateDiscountedPrice(
      originalPrice,
      discount,
      _discountType,
    );

    final voucher = Voucher(
      id: widget.voucher?.id,
      adminId: widget.voucher?.adminId ?? widget.adminId,
      shopId: widget.voucher?.shopId ?? 0,
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      originalPrice: originalPrice,
      discountValue: discount,
      discountType: _discountType,
      discountedPrice: discountedPrice,
      expiryDate: _expiryDate!,
      usageLimit: usageLimit,
      status: _status,
      shopName: shopName,
      shopAddress: shopAddress,
      imagePath: _imagePaths.isEmpty ? null : _imagePaths.first,
      gallery: List.unmodifiable(_imagePaths),
      contactName: _contactNameController.text.trim().isEmpty
          ? null
          : _contactNameController.text.trim(),
      contactPhone: _contactPhoneController.text.trim().isEmpty
          ? null
          : _contactPhoneController.text.trim(),
    );

    String? error;
    if (widget.voucher == null) {
      error = await provider.createVoucher(voucher);
    } else {
      error = await provider.updateVoucher(voucher);
    }

    setState(() => _isSubmitting = false);

    if (error != null) {
      _showSnackBar(error);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _recalculateDiscountedPrice() {
    final original =
        double.tryParse(_originalPriceController.text.replaceAll(',', '.'));
    final discount =
        double.tryParse(_discountController.text.replaceAll(',', '.'));
    final result = _calculateDiscountedPrice(original, discount, _discountType);
    setState(() => _discountedPrice = result);
  }

  double _calculateDiscountedPrice(
    double? original,
    double? discount,
    String discountType,
  ) {
    if (original == null || original <= 0 || discount == null || discount < 0) {
      return 0;
    }
    double discounted = original;
    if (discountType == 'percentage') {
      discounted = original - (original * (discount / 100));
    } else {
      discounted = original - discount;
    }
    if (discounted < 0) {
      discounted = 0;
    }
    return double.parse(discounted.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.voucher != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sectionPalette = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      colorScheme.surfaceTint.withValues(alpha: 0.55),
      colorScheme.outlineVariant.withValues(alpha: 0.45),
    ];

    final headerFooterColor = const Color(0xFF212121);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: headerFooterColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? 'Update Voucher' : 'Create New Voucher',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fill in the details below',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Complete all required fields to create your voucher',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    children: [
                      _SectionCard(
                        color: sectionPalette[0],
                        title: 'Voucher details',
                        description:
                            'Give your voucher an eye-catching name and unique code.',
                        children: [
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Voucher name',
                              labelStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              prefixIcon: Icon(Icons.card_giftcard_outlined, color: colorScheme.primary),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              letterSpacing: 1.2,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Voucher code',
                              labelStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              prefixIcon: Icon(Icons.confirmation_number_outlined, color: colorScheme.primary),
                              helperText: 'Tip: keep it short yet memorable (e.g. SAVE20).',
                              helperStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Code is required';
                              }
                              if (value.trim().length < 4) {
                                return 'Code should be at least 4 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        color: sectionPalette[1],
                        title: 'Pricing',
                        description:
                            'Set original price and specify the discount type you want to offer.',
                        children: [
                          TextFormField(
                            controller: _originalPriceController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Original price',
                              labelStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              prefixIcon: Icon(Icons.attach_money_outlined, color: colorScheme.primary),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _discountController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Discount value',
                                    labelStyle: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                    prefixIcon: Icon(Icons.percent_outlined, color: colorScheme.primary),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _discountType,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Discount type',
                                    labelStyle: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'percentage',
                                      child: Text('Percentage %'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'amount',
                                      child: Text('Fixed amount'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _discountType = value);
                                    _recalculateDiscountedPrice();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _AnalyticsRow(
                            items: [
                              _AnalyticsChip(
                                color: colorScheme.onPrimaryContainer,
                                background: colorScheme.primary.withValues(alpha: 0.25),
                                icon: Icons.monetization_on_outlined,
                                label: 'Discounted price',
                                value: _discountedPrice.toStringAsFixed(2),
                              ),
                              _AnalyticsChip(
                                color: colorScheme.onSecondaryContainer,
                                background:
                                    colorScheme.secondary.withValues(alpha: 0.25),
                                icon: Icons.percent_outlined,
                                label: _discountType == 'percentage'
                                    ? 'Discount %'
                                    : 'Discount amount',
                                value: _discountController.text.isEmpty
                                    ? '0'
                                    : _discountController.text,
                              ),
                              _AnalyticsChip(
                                color: colorScheme.onTertiaryContainer,
                                background:
                                    colorScheme.tertiary.withValues(alpha: 0.25),
                                icon: Icons.repeat_on_outlined,
                                label: 'Usage limit',
                                value: _usageLimitController.text,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        color: sectionPalette[2],
                        title: 'Shop information',
                        description:
                            'Tell customers where they can redeem this voucher.',
                        children: [
                          TextFormField(
                            controller: _shopNameController,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Shop name',
                              labelStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              prefixIcon: Icon(Icons.storefront_outlined, color: colorScheme.primary),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                            controller: _shopAddressController,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Shop address',
                              labelStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              prefixIcon: Icon(Icons.location_on_outlined, color: colorScheme.primary),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Shop address is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        color: sectionPalette[1],
                        title: 'Point of contact',
                        description:
                            'Share a name and phone number so shop staff or customers can reach the right person.',
                        children: [
                          TextFormField(
                            controller: _contactNameController,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Contact person (optional)',
                              labelStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contactPhoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Contact phone (optional)',
                              labelStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              prefixIcon: Icon(Icons.phone_outlined, color: colorScheme.primary),
                              helperText: 'Include country code if needed e.g. +1 555 123 4567',
                              helperStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        color: sectionPalette[3],
                        title: 'Schedule & status',
                        description:
                            'Specify when the voucher expires and how it should appear to customers.',
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.calendar_month_outlined,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Expiry date',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: Colors.black54,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _expiryDate == null
                                            ? 'Tap to choose'
                                            : MaterialLocalizations.of(context)
                                                .formatMediumDate(_expiryDate!),
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: _selectExpiryDate,
                                  icon: const Icon(Icons.edit_calendar_outlined),
                                  label: const Text('Select'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _status,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Voucher status',
                              labelStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              prefixIcon: Icon(Icons.flag_outlined, color: colorScheme.primary),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'active', child: Text('Active')),
                              DropdownMenuItem(
                                  value: 'redeemed', child: Text('Redeemed')),
                              DropdownMenuItem(value: 'expired', child: Text('Expired')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _status = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usageLimitController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Usage limit',
                              labelStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              prefixIcon: Icon(Icons.countertops_outlined, color: colorScheme.primary),
                              helperText: 'How many times can this voucher be redeemed?',
                              helperStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        color: sectionPalette[4],
                        title: 'Media',
                        description:
                            'Add multiple images to showcase the voucher from different angles.',
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (var i = 0; i < _imagePaths.length; i++)
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        File(_imagePaths[i]),
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          height: 120,
                                          width: 120,
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainerHigh
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: InkWell(
                                        onTap: () => _removeImageAt(i),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceTint,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              OutlinedButton.icon(
                                onPressed: _pickImages,
                                icon: const Icon(Icons.add_photo_alternate_outlined),
                                label: const Text('Add images'),
                              ),
                            ],
                          ),
                          if (_imagePaths.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Tip: the first image becomes the primary cover shown to users.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        color: colorScheme.primaryContainer
                            .withValues(alpha: 0.55),
                        title: 'Summary',
                        description: 'A quick glance at what customers will see.',
                        children: [
                          _AnalyticsRow(
                            items: [
                              _AnalyticsChip(
                                color: colorScheme.onPrimaryContainer,
                                background: colorScheme.primary
                                    .withValues(alpha: 0.25),
                                icon: Icons.price_change_outlined,
                                label: 'Original',
                                value: _originalPriceController.text.isEmpty
                                    ? '0'
                                    : _originalPriceController.text,
                              ),
                              _AnalyticsChip(
                                color: colorScheme.onSecondaryContainer,
                                background: colorScheme.secondary
                                    .withValues(alpha: 0.25),
                                icon: Icons.percent_outlined,
                                label: 'Discount type',
                                value: _discountType == 'percentage'
                                    ? 'Percent'
                                    : 'Fixed',
                              ),
                              _AnalyticsChip(
                                color: colorScheme.onTertiaryContainer,
                                background: colorScheme.tertiary
                                    .withValues(alpha: 0.25),
                                icon: Icons.timer_outlined,
                                label: 'Expires',
                                value: _expiryDate == null
                                    ? '--'
                                    : MaterialLocalizations.of(context)
                                        .formatMediumDate(_expiryDate!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_shopNameController.text.isEmpty ? 'Shop name' : _shopNameController.text} • ${_shopAddressController.text.isEmpty ? 'Address' : _shopAddressController.text}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _saveVoucher,
                        icon: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isEditing ? 'Save changes' : 'Create voucher',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.description,
    required this.children,
    required this.color,
  });

  final String title;
  final String? description;
  final List<Widget> children;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Extract icon color based on container color
    final iconColor = color == colorScheme.primaryContainer
        ? colorScheme.primary
        : (color == colorScheme.secondaryContainer
            ? colorScheme.secondary
            : (color == colorScheme.tertiaryContainer
                ? colorScheme.tertiary
                : colorScheme.primary));
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            color.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getIconForTitle(title),
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 20,
                            ),
                          ),
                          if (description != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              description!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    if (title.toLowerCase().contains('voucher') || title.toLowerCase().contains('details')) {
      return Icons.card_giftcard_outlined;
    } else if (title.toLowerCase().contains('pricing')) {
      return Icons.attach_money_outlined;
    } else if (title.toLowerCase().contains('shop')) {
      return Icons.storefront_outlined;
    } else if (title.toLowerCase().contains('contact')) {
      return Icons.person_outline;
    } else if (title.toLowerCase().contains('schedule') || title.toLowerCase().contains('status')) {
      return Icons.calendar_month_outlined;
    } else if (title.toLowerCase().contains('media')) {
      return Icons.image_outlined;
    }
    return Icons.info_outline;
  }
}

class _AnalyticsRow extends StatelessWidget {
  const _AnalyticsRow({required this.items});

  final List<_AnalyticsChip> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items,
    );
  }
}

class _AnalyticsChip extends StatelessWidget {
  const _AnalyticsChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: 0.7),
                ),
              ),
              Text(
                value.isEmpty ? '--' : value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

