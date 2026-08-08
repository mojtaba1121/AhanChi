import '../core/api_failure.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'local_database.dart';

class SyncResult {
  const SyncResult({required this.synced, required this.failed, this.lastError});
  final int synced;
  final int failed;
  final String? lastError;
}

class SyncService {
  SyncService(this.db, this.api);
  final LocalDatabase db;
  final ApiClient api;

  Future<SyncResult> syncAll() async {
    var synced = 0;
    var failed = 0;
    String? lastError;
    for (final seller in await db.sellers(onlyUnsynced: true)) {
      try {
        await _syncSeller(seller);
        synced++;
      } catch (error) {
        await db.markError('sellers', seller.localId, error);
        lastError = friendlyErrorMessage(error);
        failed++;
      }
    }
    for (final purchase in await db.purchases(onlyUnsynced: true)) {
      try {
        final seller = await db.seller(purchase.sellerLocalId);
        if (seller?.serverId == null) throw StateError('فروشنده هنوز همگام نشده است');
        var sellerServerId = seller!.serverId!;
        Map<String, dynamic> result;
        try {
          result = await _postPurchase(purchase, sellerServerId);
        } catch (error) {
          if (!_isMissingSeller(error)) rethrow;
          sellerServerId = await _syncSeller(seller, force: true);
          result = await _postPurchase(purchase, sellerServerId);
        }
        await db.markPurchaseSynced(purchase.localId, (result['_id'] ?? result['id']) as String);
        synced++;
      } catch (error) {
        await db.markError('purchases', purchase.localId, error);
        lastError = friendlyErrorMessage(error);
        failed++;
      }
    }
    for (final entry in await db.ledger(onlyUnsynced: true)) {
      try {
        final seller = await db.seller(entry.sellerLocalId);
        if (seller?.serverId == null) throw StateError('فروشنده هنوز همگام نشده است');
        var sellerServerId = seller!.serverId!;
        Map<String, dynamic> result;
        try {
          result = await _postLedger(entry, sellerServerId);
        } catch (error) {
          if (!_isMissingSeller(error)) rethrow;
          sellerServerId = await _syncSeller(seller, force: true);
          result = await _postLedger(entry, sellerServerId);
        }
        await db.markLedgerSynced(entry.localId, (result['_id'] ?? result['id']) as String);
        synced++;
      } catch (error) {
        await db.markError('ledger_entries', entry.localId, error);
        lastError = friendlyErrorMessage(error);
        failed++;
      }
    }
    try {
      await db.replaceMaterials((await api.list('/materials')).map(MaterialItem.fromJson).toList());
    } catch (_) {
      // Cached materials remain available offline.
    }
    return SyncResult(synced: synced, failed: failed, lastError: lastError);
  }

  Future<String> _syncSeller(SellerItem seller, {bool force = false}) async {
    if (!force && seller.serverId != null) return seller.serverId!;
    final result = await api.post('/sellers', {
      'clientId': seller.localId,
      'fullName': seller.fullName,
      if (seller.phone?.isNotEmpty == true) 'phone': seller.phone,
      if (seller.city?.isNotEmpty == true) 'city': seller.city,
      if (seller.village?.isNotEmpty == true) 'village': seller.village,
      if (seller.address?.isNotEmpty == true) 'address': seller.address,
    });
    final serverId = (result['_id'] ?? result['id']) as String;
    await db.markSellerSynced(seller.localId, serverId);
    return serverId;
  }

  Future<Map<String, dynamic>> _postPurchase(LocalPurchase purchase, String sellerServerId) {
    return api.post('/purchases', {
      'sellerId': sellerServerId,
      'materialId': purchase.materialId,
      'weightGrams': purchase.weightGrams,
      'pricePerKgToman': purchase.pricePerKgToman,
      'clientOperationId': purchase.localId,
      'purchasedAt': purchase.purchasedAt.toUtc().toIso8601String(),
      if (purchase.note?.isNotEmpty == true) 'note': purchase.note,
    });
  }

  Future<Map<String, dynamic>> _postLedger(LocalLedgerEntry entry, String sellerServerId) {
    return api.post('/ledger', {
      'sellerId': sellerServerId,
      'type': entry.type,
      'amountToman': entry.amountToman,
      'clientOperationId': entry.localId,
      'occurredAt': entry.occurredAt.toUtc().toIso8601String(),
      if (entry.note?.isNotEmpty == true) 'note': entry.note,
    });
  }

  bool _isMissingSeller(Object error) {
    return error is ApiFailure &&
        error.statusCode == 404 &&
        error.message.contains('فروشنده پیدا نشد');
  }
}
