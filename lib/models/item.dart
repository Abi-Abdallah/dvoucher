class Item {
  final int? id;
  final int adminId;
  final String name;
  final String? description;
  final String? category;
  final double originalPrice;
  final double discountedPrice;
  final String? imagePath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Item({
    this.id,
    required this.adminId,
    required this.name,
    this.description,
    this.category,
    required this.originalPrice,
    required this.discountedPrice,
    this.imagePath,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Item copyWith({
    int? id,
    int? adminId,
    String? name,
    String? description,
    String? category,
    double? originalPrice,
    double? discountedPrice,
    String? imagePath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': id,
      'admin_id': adminId,
      'name': name,
      'description': description,
      'category': category,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'image_path': imagePath,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['item_id'] as int?,
      adminId: (map['admin_id'] as num).toInt(),
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      originalPrice: (map['original_price'] as num).toDouble(),
      discountedPrice: (map['discounted_price'] as num).toDouble(),
      imagePath: map['image_path'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }
}
