class Shop {
  final int? id;
  final int adminId;
  final String name;
  final String address;
  final String contactNumber;
  final String? logoPath;

  const Shop({
    this.id,
    required this.adminId,
    required this.name,
    required this.address,
    required this.contactNumber,
    this.logoPath,
  });

  Shop copyWith({
    int? id,
    int? adminId,
    String? name,
    String? address,
    String? contactNumber,
    String? logoPath,
  }) {
    return Shop(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      name: name ?? this.name,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': id,
      'admin_id': adminId,
      'shop_name': name,
      'shop_address': address,
      'contact_number': contactNumber,
      'logo_path': logoPath,
    };
  }

  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['shop_id'] as int?,
      adminId: (map['admin_id'] as num).toInt(),
      name: map['shop_name'] as String,
      address: map['shop_address'] as String,
      contactNumber: map['contact_number'] as String,
      logoPath: map['logo_path'] as String?,
    );
  }
}

