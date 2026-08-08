import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/formatters.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'local_database.dart';
import 'sync_service.dart';

class AppRepository {
  AppRepository({required this.preferences, required this.db}) {
    api = ApiClient(preferences);
    sync = SyncService(db, api);
  }
  final SharedPreferences preferences;
  final LocalDatabase db;
  late final ApiClient api;
  late final SyncService sync;
  final _uuid = const Uuid();

  Future<AuthSession?> restoreSession() async {
    final value = preferences.getString('session');
    return value == null ? null : AuthSession.fromStoredJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<AuthSession> login(String phone, String password) async {
    final session = await api.login(phone, password);
    await preferences.setString('session', jsonEncode(session.toJson()));
    if (!session.isManager) await sync.syncAll();
    return session;
  }

  Future<void> logout() async {
    await preferences.remove('session');
    await preferences.remove('access_token');
  }

  Future<SyncResult?> addSeller({required String fullName, required String phone, String? city, String? village, String? address}) async {
    await db.addSeller(SellerItem(localId: _uuid.v4(), fullName: fullName, phone: phone, city: city, village: village, address: address));
    return _trySync();
  }

  Future<SyncResult?> addPurchase({required String sellerLocalId, required String materialId, required int weightGrams, required int pricePerKgToman, String? note}) async {
    await db.addPurchase(LocalPurchase(
      localId: _uuid.v4(), sellerLocalId: sellerLocalId, materialId: materialId,
      weightGrams: weightGrams, pricePerKgToman: pricePerKgToman,
      totalAmountToman: calculateTotal(weightGrams, pricePerKgToman), purchasedAt: DateTime.now(), note: note,
    ));
    return _trySync();
  }

  Future<SyncResult?> addLedger({required String sellerLocalId, required String type, required int amountToman, String? note}) async {
    await db.addLedger(LocalLedgerEntry(localId: _uuid.v4(), sellerLocalId: sellerLocalId, type: type, amountToman: amountToman, occurredAt: DateTime.now(), note: note));
    return _trySync();
  }

  Future<SyncResult?> _trySync() async {
    try { return await sync.syncAll(); } catch (_) { return null; /* local data is intentionally retained */ }
  }
}
