import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/promotion.dart';
import '../../../models/voucher.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/promotion_provider.dart';
import '../../../providers/voucher_provider.dart';
import '../../../widgets/promotion_preview_sheet.dart';

class PromotionFormScreen extends StatefulWidget {
  const PromotionFormScreen({super.key, this.promotion});

  final Promotion? promotion;

  static const routeName = '/admin/promotions/new';

  @override
  State<PromotionFormScreen> createState() => _PromotionFormScreenState();
}

class _PromotionFormScreenState extends State<PromotionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _imagePaths = [];
  bool _isSubmitting = false;
  bool _showOnHome = true;
  bool _showOnVoucher = false;
  final Set<int> _selectedVoucherIds = <int>{};

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final promotion = widget.promotion;
    if (promotion != null) {
      _titleController.text = promotion.title;
      _descriptionController.text = promotion.description;
      _shopNameController.text = promotion.shopName;
      _shopAddressController.text = promotion.shopAddress;
      _startDate = promotion.startDate;
      _endDate = promotion.endDate;
      if (promotion.gallery.isNotEmpty) {
        _imagePaths.addAll(promotion.gallery);
      } else if (promotion.imagePath != null && promotion.imagePath!.isNotEmpty) {
        _imagePaths.add(promotion.imagePath!);
      }
      _contactNameController.text = promotion.contactName ?? '';
      _contactPhoneController.text = promotion.contactPhone ?? '';
      _showOnHome = promotion.showOnHome;
      _showOnVoucher = promotion.showOnVoucher;
      _selectedVoucherIds.addAll(promotion.voucherIds);
    } else {
      final now = DateTime.now();
      _startDate = now;
      _endDate = now.add(const Duration(days: 7));
      _showOnHome = true;
      _showOnVoucher = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final voucherProvider = context.read<VoucherProvider>();
      if (voucherProvider.vouchers.isEmpty) {
        await voucherProvider.refreshVouchers();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final initial = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final initial = _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
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

  Future<void> _openVoucherPicker() async {
    final voucherProvider = context.read<VoucherProvider>();
    if (voucherProvider.vouchers.isEmpty) {
      await voucherProvider.refreshVouchers();
    }
    if (!mounted) return;
    final vouchers = voucherProvider.vouchers
        .where((voucher) => voucher.id != null)
        .toList();
    if (vouchers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vouchers available. Create a voucher first.')),
      );
      return;
    }

    final tempSelected = Set<int>.from(_selectedVoucherIds);
    String search = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final query = search.toLowerCase();
              final filtered = vouchers.where((voucher) {
                final name = voucher.name.toLowerCase();
                final code = voucher.code.toLowerCase();
                final shop = voucher.shopName.toLowerCase();
                if (query.isEmpty) {
                  return true;
                }
                return name.contains(query) ||
                    code.contains(query) ||
                    shop.contains(query);
              }).toList();

              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Search vouchers',
                        labelStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                        prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onChanged: (value) => setModalState(() => search = value),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('No vouchers match your search.'),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final voucher = filtered[index];
                                final id = voucher.id!;
                                final selected = tempSelected.contains(id);
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: (value) {
                                    setModalState(() {
                                      if (value == true) {
                                        tempSelected.add(id);
                                      } else {
                                        tempSelected.remove(id);
                                      }
                                    });
                                  },
                                  title: Text(voucher.name),
                                  subtitle: Text('${voucher.shopName} • ${voucher.code}'),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => setModalState(() => tempSelected.clear()),
                          child: const Text('Clear all'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _selectedVoucherIds
        ..clear()
        ..addAll(tempSelected);
    });
  }

  Promotion _buildDraftPromotion(int adminId) {
    final base = widget.promotion;
    final now = DateTime.now();
    final images = List<String>.from(_imagePaths);
    final primaryImage = images.isNotEmpty
        ? images.first
        : base?.imagePath;

    return Promotion(
      id: base?.id,
      adminId: base?.adminId ?? adminId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: _startDate ?? now,
      endDate: _endDate ?? now.add(const Duration(days: 7)),
      imagePath: primaryImage,
      createdAt: base?.createdAt ?? DateTime.now(),
      shopName: _shopNameController.text.trim(),
      shopAddress: _shopAddressController.text.trim(),
      contactName: _contactNameController.text.trim().isEmpty
          ? null
          : _contactNameController.text.trim(),
      contactPhone: _contactPhoneController.text.trim().isEmpty
          ? null
          : _contactPhoneController.text.trim(),
      gallery: List.unmodifiable(images),
      showOnHome: _showOnHome,
      showOnVoucher: _showOnVoucher,
      impressions: base?.impressions ?? 0,
      clicks: base?.clicks ?? 0,
      voucherIds: List.unmodifiable(_selectedVoucherIds),
    );
  }

  Future<void> _openPreview() async {
    final auth = context.read<AuthProvider>();
    final admin = auth.currentAdmin;
    if (admin == null || admin.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin context missing. Please log in again.')),
      );
      return;
    }

    final voucherProvider = context.read<VoucherProvider>();
    final voucherLookup = <int, Voucher>{
      for (final voucher in voucherProvider.vouchers)
        if (voucher.id != null) voucher.id!: voucher,
    };

    final draft = _buildDraftPromotion(admin.id!);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return PromotionPreviewSheet(
          promotion: draft,
          voucherLookup: voucherLookup,
        );
      },
    );
  }

  Future<void> _savePromotion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose start and end dates.')),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<PromotionProvider>();
    final admin = context.read<AuthProvider>().currentAdmin;
    if (admin == null || admin.id == null) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin context missing. Please log in again.')),
      );
      return;
    }

    final adminId = admin.id!;
    final promotion = _buildDraftPromotion(adminId);

    String? error;
    if (widget.promotion == null) {
      error = await provider.createPromotion(promotion);
    } else {
      error = await provider.updatePromotion(promotion);
    }

    setState(() => _isSubmitting = false);

    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.promotion != null;
    final voucherProvider = context.watch<VoucherProvider>();
    final voucherLookup = <int, Voucher>{
      for (final voucher in voucherProvider.vouchers)
        if (voucher.id != null) voucher.id!: voucher,
    };
    final selectedVoucherIds = _selectedVoucherIds.toList()
      ..sort((a, b) {
        final aName = voucherLookup[a]?.name ?? 'Voucher #$a';
        final bName = voucherLookup[b]?.name ?? 'Voucher #$b';
        return aName.toLowerCase().compareTo(bName.toLowerCase());
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit promotion' : 'New promotion'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: colorScheme.onPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.campaign_rounded,
                              color: colorScheme.onPrimary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? 'Update campaign' : 'Create a standout campaign',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Craft eye-catching promotions with rich media, precise timing and instant user notifications.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  background: colorScheme.primaryContainer,
                  icon: Icons.description_outlined,
                  iconColor: colorScheme.primary,
                  title: 'Promotion details',
                  description: 'Define the headline and compelling copy that will attract users.',
                  children: [
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                        prefixIcon: Icon(Icons.campaign_outlined, color: colorScheme.primary),
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
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 6,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined, color: colorScheme.primary),
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
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  background: colorScheme.secondaryContainer,
                  icon: Icons.schedule_outlined,
                  iconColor: colorScheme.secondary,
                  title: 'Timing & availability',
                  description: 'Plan the promotion runway to maximise visibility at the right moment.',
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
                              Icons.play_arrow_outlined,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start date',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _startDate == null
                                      ? 'Tap to choose'
                                      : MaterialLocalizations.of(context)
                                          .formatMediumDate(_startDate!),
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
                            onPressed: _pickStartDate,
                            icon: const Icon(Icons.edit_calendar_outlined),
                            label: const Text('Select'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
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
                              color: colorScheme.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.stop_circle_outlined,
                              color: colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End date',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _endDate == null
                                      ? 'Tap to choose'
                                      : MaterialLocalizations.of(context)
                                          .formatMediumDate(_endDate!),
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
                            onPressed: _pickEndDate,
                            icon: const Icon(Icons.edit_calendar_outlined),
                            label: const Text('Select'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  background: colorScheme.primaryContainer,
                  icon: Icons.store_outlined,
                  iconColor: colorScheme.primary,
                  title: 'Shop information',
                  description: 'Tell shoppers which branch is running this promotion.',
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
                  background: colorScheme.surfaceContainerHigh,
                  icon: Icons.support_agent_outlined,
                  iconColor: colorScheme.primary,
                  title: 'Point of contact',
                  description: 'Provide a contact person so partners can coordinate redemptions or clarifications quickly.',
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
                        helperText: 'Include country code if needed e.g. +44 7700 900123',
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
                  background: colorScheme.surfaceContainerHighest,
                  icon: Icons.visibility_outlined,
                  iconColor: colorScheme.primary,
                  title: 'Placement & targeting',
                  description:
                      'Control where this promotion appears across the customer experience.',
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _showOnHome,
                      onChanged: (value) => setState(() => _showOnHome = value),
                      title: const Text('Display on user home dashboard'),
                      subtitle: const Text(
                        'Shows inside the hero carousel and spotlight widgets.',
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _showOnVoucher,
                      onChanged: (value) => setState(() => _showOnVoucher = value),
                      title: const Text('Show alongside voucher listings'),
                      subtitle: const Text(
                        'Highlights the campaign on voucher discovery pages.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  background: colorScheme.surfaceContainerHigh,
                  icon: Icons.link_outlined,
                  iconColor: colorScheme.primary,
                  title: 'Linked vouchers & items',
                  description:
                      'Associate existing vouchers or catalogue items to track performance and conversions automatically.',
                  children: [
                    if (selectedVoucherIds.isEmpty)
                      Text(
                        'No vouchers linked yet. Link one or more vouchers to track impressions, clicks and confirmed redemptions.',
                        style: theme.textTheme.bodySmall,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedVoucherIds.map((id) {
                          final voucher = voucherLookup[id];
                          final label = voucher?.name ?? 'Voucher #$id';
                          return InputChip(
                            label: Text(label),
                            avatar: const Icon(Icons.local_offer_outlined, size: 16),
                            onDeleted: () => setState(() => _selectedVoucherIds.remove(id)),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _openVoucherPicker,
                        icon: const Icon(Icons.add_link),
                        label: const Text('Link vouchers or items'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  background: colorScheme.tertiaryContainer,
                  icon: Icons.photo_filter_outlined,
                  iconColor: colorScheme.tertiary,
                  title: 'Media & visuals',
                  description: 'Drop in an aspirational hero image to enhance the promotion.',
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
                                  height: 130,
                                  width: 130,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 130,
                                    width: 130,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHigh
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
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
                          'Attach multiple visuals to illustrate the offer. The first image is used as the cover.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  background: colorScheme.primaryContainer,
                  icon: Icons.link_outlined,
                  iconColor: colorScheme.primary,
                  title: 'Vouchers',
                  description: 'Link existing vouchers to this promotion for better tracking and redemption.',
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
                              Icons.link_outlined,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vouchers',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedVoucherIds.length} selected',
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
                            onPressed: _openVoucherPicker,
                            icon: const Icon(Icons.add_link_outlined),
                            label: const Text('Select'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _openPreview,
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Preview'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _savePromotion,
                        icon: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(isEditing ? 'Save changes' : 'Create promotion'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.children,
  });

  final Color background;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            background.withValues(alpha: 0.95),
            background.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: background.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
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
}
