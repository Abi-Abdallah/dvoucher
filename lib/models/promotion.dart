class Promotion {
  final int? id;
  final int adminId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String? imagePath;
  final DateTime createdAt;
  final String shopName;
  final String shopAddress;
  final String? contactName;
  final String? contactPhone;
  final List<String> gallery;
  final bool showOnHome;
  final bool showOnVoucher;
  final int impressions;
  final int clicks;
  final List<int> voucherIds;

  const Promotion({
    this.id,
    required this.adminId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.imagePath,
    required this.createdAt,
    required this.shopName,
    required this.shopAddress,
    this.contactName,
    this.contactPhone,
    this.gallery = const [],
    this.showOnHome = true,
    this.showOnVoucher = false,
    this.impressions = 0,
    this.clicks = 0,
    this.voucherIds = const [],
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  double get engagementRate {
    if (impressions <= 0 || clicks <= 0) {
      return 0;
    }
    return clicks / impressions;
  }

  Promotion copyWith({
    int? id,
    int? adminId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? imagePath,
    DateTime? createdAt,
    String? shopName,
    String? shopAddress,
    String? contactName,
    String? contactPhone,
    List<String>? gallery,
    bool? showOnHome,
    bool? showOnVoucher,
    int? impressions,
    int? clicks,
    List<int>? voucherIds,
  }) {
    return Promotion(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      gallery: gallery ?? this.gallery,
      showOnHome: showOnHome ?? this.showOnHome,
      showOnVoucher: showOnVoucher ?? this.showOnVoucher,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      voucherIds: voucherIds ?? this.voucherIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'promotion_id': id,
      'admin_id': adminId,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'shop_name': shopName,
      'shop_address': shopAddress,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'show_on_home': showOnHome ? 1 : 0,
      'show_on_vouchers': showOnVoucher ? 1 : 0,
      'impressions': impressions,
      'clicks': clicks,
    };
  }

  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      id: map['promotion_id'] as int?,
      adminId: (map['admin_id'] as num).toInt(),
      title: map['title'] as String,
      description: map['description'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      shopName: map['shop_name'] as String? ?? '',
      shopAddress: map['shop_address'] as String? ?? '',
      contactName: map['contact_name'] as String?,
      contactPhone: map['contact_phone'] as String?,
      gallery: const [],
      showOnHome: (map['show_on_home'] as int? ?? 1) == 1,
      showOnVoucher: (map['show_on_vouchers'] as int? ?? 0) == 1,
      impressions: (map['impressions'] as num?)?.toInt() ?? 0,
      clicks: (map['clicks'] as num?)?.toInt() ?? 0,
      voucherIds: const [],
    );
  }
}
