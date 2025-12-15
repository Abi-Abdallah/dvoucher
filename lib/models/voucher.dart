import 'package:intl/intl.dart';

class Voucher {
  final int? id;
  final int adminId;
  final int shopId;
  final String name;
  final String code;
  final double originalPrice;
  final double discountValue;
  final String discountType;
  final double discountedPrice;
  final DateTime expiryDate;
  final int usageLimit;
  final String status;
  final String shopName;
  final String shopAddress;
  final String? imagePath;
  final List<String> gallery;
  final String? contactName;
  final String? contactPhone;
  final int? itemId;
  final String? category;
  final String? itemName;

  const Voucher({
    this.id,
    required this.adminId,
    required this.shopId,
    required this.name,
    required this.code,
    required this.originalPrice,
    required this.discountValue,
    this.discountType = 'percentage',
    required this.discountedPrice,
    required this.expiryDate,
    required this.usageLimit,
    required this.status,
    required this.shopName,
    required this.shopAddress,
    this.imagePath,
    this.gallery = const [],
    this.contactName,
    this.contactPhone,
    this.itemId,
    this.category,
    this.itemName,
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  Voucher copyWith({
    int? id,
    int? adminId,
    int? shopId,
    String? name,
    String? code,
    double? originalPrice,
    double? discountValue,
    String? discountType,
    double? discountedPrice,
    DateTime? expiryDate,
    int? usageLimit,
    String? status,
    String? shopName,
    String? shopAddress,
    String? imagePath,
    List<String>? gallery,
    String? contactName,
    String? contactPhone,
    int? itemId,
    String? category,
    String? itemName,
  }) {
    return Voucher(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      code: code ?? this.code,
      originalPrice: originalPrice ?? this.originalPrice,
      discountValue: discountValue ?? this.discountValue,
      discountType: discountType ?? this.discountType,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      expiryDate: expiryDate ?? this.expiryDate,
      usageLimit: usageLimit ?? this.usageLimit,
      status: status ?? this.status,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      imagePath: imagePath ?? this.imagePath,
      gallery: gallery ?? this.gallery,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      itemId: itemId ?? this.itemId,
      category: category ?? this.category,
      itemName: itemName ?? this.itemName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'voucher_id': id,
      'admin_id': adminId,
      'shop_id': shopId,
      'name': name,
      'code': code,
      'original_price': originalPrice,
      'discount_value': discountValue,
      'discount_type': discountType,
      'discounted_price': discountedPrice,
      'expiry_date': expiryDate.toIso8601String(),
      'usage_limit': usageLimit,
      'status': status,
      'shop_name': shopName,
      'shop_address': shopAddress,
      'image_path': imagePath,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'item_id': itemId,
    };
  }

  factory Voucher.fromMap(Map<String, dynamic> map) {
    return Voucher(
      id: map['voucher_id'] as int?,
      adminId: (map['admin_id'] as num).toInt(),
      shopId: (map['shop_id'] as num).toInt(),
      name: map['name'] as String,
      code: map['code'] as String,
      originalPrice: (map['original_price'] as num).toDouble(),
      discountValue: (map['discount_value'] as num).toDouble(),
      discountType: map['discount_type'] as String? ?? 'percentage',
      discountedPrice: (map['discounted_price'] as num).toDouble(),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      usageLimit: (map['usage_limit'] as num).toInt(),
      status: map['status'] as String,
      shopName: map['shop_name'] as String,
      shopAddress: map['shop_address'] as String,
      imagePath: map['image_path'] as String?,
      gallery: const [],
      contactName: map['contact_name'] as String?,
      contactPhone: map['contact_phone'] as String?,
      itemId: map['item_id'] as int?,
      category: map['category'] as String?,
      itemName: map['item_name'] as String?,
    );
  }

  String get formattedExpiry {
    return DateFormat('dd MMM yyyy').format(expiryDate);
  }
}

