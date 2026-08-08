class AuthSession {
  const AuthSession({required this.accessToken, required this.id, required this.fullName, required this.phone, required this.role});
  final String accessToken;
  final String id;
  final String fullName;
  final String phone;
  final String role;

  bool get isManager => role == 'SUPER_ADMIN' || role == 'MANAGER';

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthSession(
      accessToken: json['accessToken'] as String,
      id: user['id'] as String,
      fullName: user['fullName'] as String,
      phone: user['phone'] as String,
      role: user['role'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'accessToken': accessToken, 'id': id, 'fullName': fullName, 'phone': phone, 'role': role};
  factory AuthSession.fromStoredJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken'] as String,
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    phone: json['phone'] as String,
    role: json['role'] as String,
  );
}

class MaterialItem {
  const MaterialItem({required this.id, required this.code, required this.nameFa, required this.color});
  final String id;
  final String code;
  final String nameFa;
  final String color;
  factory MaterialItem.fromJson(Map<String, dynamic> json) => MaterialItem(
    id: (json['_id'] ?? json['id']) as String,
    code: json['code'] as String,
    nameFa: json['nameFa'] as String,
    color: (json['color'] ?? '#607D8B') as String,
  );
  Map<String, dynamic> toMap() => {'id': id, 'code': code, 'nameFa': nameFa, 'color': color};
  factory MaterialItem.fromMap(Map<String, Object?> map) => MaterialItem(id: map['id']! as String, code: map['code']! as String, nameFa: map['nameFa']! as String, color: map['color']! as String);
}

class SellerItem {
  const SellerItem({required this.localId, this.serverId, required this.fullName, this.phone, this.city, this.village, this.address, this.synced = false});
  final String localId;
  final String? serverId;
  final String fullName;
  final String? phone;
  final String? city;
  final String? village;
  final String? address;
  final bool synced;
}

class LocalPurchase {
  const LocalPurchase({
    required this.localId,
    required this.sellerLocalId,
    required this.materialId,
    required this.weightGrams,
    required this.pricePerKgToman,
    required this.totalAmountToman,
    required this.purchasedAt,
    this.note,
    this.synced = false,
  });
  final String localId;
  final String sellerLocalId;
  final String materialId;
  final int weightGrams;
  final int pricePerKgToman;
  final int totalAmountToman;
  final DateTime purchasedAt;
  final String? note;
  final bool synced;
}

class LocalLedgerEntry {
  const LocalLedgerEntry({required this.localId, required this.sellerLocalId, required this.type, required this.amountToman, required this.occurredAt, this.note, this.synced = false});
  final String localId;
  final String sellerLocalId;
  final String type;
  final int amountToman;
  final DateTime occurredAt;
  final String? note;
  final bool synced;
}
