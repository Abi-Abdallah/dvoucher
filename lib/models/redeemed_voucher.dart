class RedeemedVoucher {
  final int? id;
  final int userId;
  final int voucherId;
  final DateTime dateRedeemed;
  final String status;
  final String? note;
  final String? redeemedBy;

  const RedeemedVoucher({
    this.id,
    required this.userId,
    required this.voucherId,
    required this.dateRedeemed,
    this.status = 'Pending',
    this.note,
    this.redeemedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'redeem_id': id,
      'user_id': userId,
      'voucher_id': voucherId,
      'date_redeemed': dateRedeemed.toIso8601String(),
      'redeem_status': status,
      'redeem_note': note,
      'redeemed_by': redeemedBy,
    };
  }

  factory RedeemedVoucher.fromMap(Map<String, dynamic> map) {
    return RedeemedVoucher(
      id: map['redeem_id'] as int?,
      userId: map['user_id'] as int,
      voucherId: map['voucher_id'] as int,
      dateRedeemed: DateTime.parse(map['date_redeemed'] as String),
      status: map['redeem_status'] as String? ?? 'Pending',
      note: map['redeem_note'] as String?,
      redeemedBy: map['redeemed_by'] as String?,
    );
  }
}

class RedeemedVoucherDetail {
  final int? id;
  final int userId;
  final int voucherId;
  final String voucherName;
  final String voucherCode;
  final double originalPrice;
  final double discountValue;
  final double discountedPrice;
  final String userName;
  final String shopName;
  final String shopAddress;
  final DateTime dateRedeemed;
  final String status;
  final String? note;
  final String? redeemedBy;

  const RedeemedVoucherDetail({
    this.id,
    required this.userId,
    required this.voucherId,
    required this.voucherName,
    required this.voucherCode,
    required this.originalPrice,
    required this.discountValue,
    required this.discountedPrice,
    required this.userName,
    required this.shopName,
    required this.shopAddress,
    required this.dateRedeemed,
    required this.status,
    this.note,
    this.redeemedBy,
  });
}

