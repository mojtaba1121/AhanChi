import '../models/models.dart';
import 'api_client.dart';
import 'local_database.dart';

class SyncResult {
  const SyncResult({required this.synced, required this.failed});
  final int synced;
  final int failed;
}

class SyncService {
  SyncService(this.db, this.api);
  final LocalDatabase db;
  final ApiClient api;

  Future<SyncResult> syncAll() async {
    var synced = 0;
    var failed = 0;
    for (final seller in await db.sellers(onlyUnsynced: true)) {
      try {
        final result = await api.post('/sellers', {
          'clientId': seller.localId, 'fullName': seller.fullName,
          if (seller.phone?.isNotEmpty == true) 'phone': seller.phone,
          if (seller.city?.isNotEmpty == true) 'city': seller.city,
          if (seller.village?.isNotEmpty == true) 'village': seller.village,
          if (seller.address?.isNotEmpty == true) 'address': seller.address,
        });
        await db.markSellerSynced(seller.localId, (result['_id'] ?? result['id']) as String);
        synced++;
      } catch (error) {
        await db.markError('sellers', seller.localId, error);
        failed++;
      }
    }
    for (final purchase in await db.purchases(onlyUnsynced: true)) {
      try {
        final seller = await db.seller(purchase.sellerLocalId);
        if (seller?.serverId == null) throw StateError('فروشنده هنوز همگام نشده است');
        final result = await api.post('/purchases', {
          'sellerId': seller!.serverId, 'materialId': purchase.materialId,
          'weightGrams': purchase.weightGrams, 'pricePerKgToman': purchase.pricePerKgToman,
          'clientOperationId': purchase.localId, 'purchasedAt': purchase.purchasedAt.toUtc().toIso8601String(),
          if (purchase.note?.isNotEmpty == true) 'note': purchase.note,
        });
        await db.markPurchaseSynced(purchase.localId, (result['_id'] ?? result['id']) as String);
        synced++;
      } catch (error) {
        await db.markError('purchases', purchase.localId, error);
        failed++;
      }
    }
    for (final entry in await db.ledger(onlyUnsynced: true)) {
      try {
        final seller = await db.seller(entry.sellerLocalId);
        if (seller?.serverId == null) throw StateError('فروشنده هنوز همگام نشده است');
        final result = await api.post('/ledger', {
          'sellerId': seller!.serverId, 'type': entry.type, 'amountToman': entry.amountToman,
          'clientOperationId': entry.localId, 'occurredAt': entry.occurredAt.toUtc().toIso8601String(),
          if (entry.note?.isNotEmpty == true) 'note': entry.note,
        });
        await db.markLedgerSynced(entry.localId, (result['_id'] ?? result['id']) as String);
        synced++;
      } catch (error) {
        await db.markError('ledger_entries', entry.localId, error);
        failed++;
      }
    }
    try {
      await db.replaceMaterials((await api.list('/materials')).map(MaterialItem.fromJson).toList());
    } catch (_) {
      // Cached materials remain available offline.
    }
    return SyncResult(synced: synced, failed: failed);
  }
}
