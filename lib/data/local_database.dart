import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class LocalDatabase {
  LocalDatabase._();
  static final instance = LocalDatabase._();
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final root = await getDatabasesPath();
    return openDatabase(
      p.join(root, 'ahanchi.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE materials(id TEXT PRIMARY KEY, code TEXT NOT NULL, nameFa TEXT NOT NULL, color TEXT NOT NULL)');
        await db.execute('''CREATE TABLE sellers(
          localId TEXT PRIMARY KEY, serverId TEXT, fullName TEXT NOT NULL, phone TEXT,
          city TEXT, village TEXT, address TEXT, synced INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL, lastError TEXT)''');
        await db.execute('''CREATE TABLE purchases(
          localId TEXT PRIMARY KEY, serverId TEXT, sellerLocalId TEXT NOT NULL,
          materialId TEXT NOT NULL, weightGrams INTEGER NOT NULL,
          pricePerKgToman INTEGER NOT NULL, totalAmountToman INTEGER NOT NULL,
          purchasedAt TEXT NOT NULL, note TEXT, synced INTEGER NOT NULL DEFAULT 0,
          lastError TEXT, FOREIGN KEY(sellerLocalId) REFERENCES sellers(localId))''');
        await db.execute('''CREATE TABLE ledger_entries(
          localId TEXT PRIMARY KEY, serverId TEXT, sellerLocalId TEXT NOT NULL,
          type TEXT NOT NULL, amountToman INTEGER NOT NULL, occurredAt TEXT NOT NULL,
          note TEXT, synced INTEGER NOT NULL DEFAULT 0, lastError TEXT,
          FOREIGN KEY(sellerLocalId) REFERENCES sellers(localId))''');
        await db.execute('CREATE INDEX idx_sellers_sync ON sellers(synced, createdAt)');
        await db.execute('CREATE INDEX idx_purchases_sync ON purchases(synced, purchasedAt)');
        await db.execute('CREATE INDEX idx_ledger_sync ON ledger_entries(synced, occurredAt)');
      },
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> replaceMaterials(List<MaterialItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('materials');
      for (final item in items) {
        await txn.insert('materials', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<MaterialItem>> materials() async =>
      (await (await database).query('materials', orderBy: 'nameFa')).map(MaterialItem.fromMap).toList();

  Future<void> addSeller(SellerItem item) async {
    await (await database).insert('sellers', {
      'localId': item.localId, 'serverId': item.serverId, 'fullName': item.fullName,
      'phone': item.phone, 'city': item.city, 'village': item.village, 'address': item.address,
      'synced': item.synced ? 1 : 0, 'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<SellerItem>> sellers({bool onlyUnsynced = false}) async {
    final rows = await (await database).query('sellers', where: onlyUnsynced ? 'synced = 0' : null, orderBy: 'createdAt DESC');
    return rows.map(_sellerFromMap).toList();
  }

  Future<SellerItem?> seller(String localId) async {
    final rows = await (await database).query('sellers', where: 'localId = ?', whereArgs: [localId], limit: 1);
    return rows.isEmpty ? null : _sellerFromMap(rows.first);
  }

  SellerItem _sellerFromMap(Map<String, Object?> row) => SellerItem(
    localId: row['localId']! as String, serverId: row['serverId'] as String?,
    fullName: row['fullName']! as String, phone: row['phone'] as String?,
    city: row['city'] as String?, village: row['village'] as String?,
    address: row['address'] as String?, synced: row['synced'] == 1,
  );

  Future<void> markSellerSynced(String localId, String serverId) async => (await database).update(
    'sellers', {'serverId': serverId, 'synced': 1, 'lastError': null}, where: 'localId = ?', whereArgs: [localId]);

  Future<void> addPurchase(LocalPurchase item) async {
    await (await database).insert('purchases', {
      'localId': item.localId, 'sellerLocalId': item.sellerLocalId, 'materialId': item.materialId,
      'weightGrams': item.weightGrams, 'pricePerKgToman': item.pricePerKgToman,
      'totalAmountToman': item.totalAmountToman,
      'purchasedAt': item.purchasedAt.toUtc().toIso8601String(), 'note': item.note,
      'synced': item.synced ? 1 : 0,
    });
  }

  Future<List<LocalPurchase>> purchases({bool onlyUnsynced = false, int limit = 200}) async {
    final rows = await (await database).query('purchases', where: onlyUnsynced ? 'synced = 0' : null, orderBy: 'purchasedAt DESC', limit: limit);
    return rows.map((row) => LocalPurchase(
      localId: row['localId']! as String, sellerLocalId: row['sellerLocalId']! as String,
      materialId: row['materialId']! as String, weightGrams: row['weightGrams']! as int,
      pricePerKgToman: row['pricePerKgToman']! as int, totalAmountToman: row['totalAmountToman']! as int,
      purchasedAt: DateTime.parse(row['purchasedAt']! as String), note: row['note'] as String?,
      synced: row['synced'] == 1,
    )).toList();
  }

  Future<void> markPurchaseSynced(String localId, String serverId) async => (await database).update(
    'purchases', {'serverId': serverId, 'synced': 1, 'lastError': null}, where: 'localId = ?', whereArgs: [localId]);

  Future<void> addLedger(LocalLedgerEntry item) async {
    await (await database).insert('ledger_entries', {
      'localId': item.localId, 'sellerLocalId': item.sellerLocalId, 'type': item.type,
      'amountToman': item.amountToman, 'occurredAt': item.occurredAt.toUtc().toIso8601String(),
      'note': item.note, 'synced': item.synced ? 1 : 0,
    });
  }

  Future<List<LocalLedgerEntry>> ledger({bool onlyUnsynced = false}) async {
    final rows = await (await database).query('ledger_entries', where: onlyUnsynced ? 'synced = 0' : null, orderBy: 'occurredAt DESC');
    return rows.map((row) => LocalLedgerEntry(
      localId: row['localId']! as String, sellerLocalId: row['sellerLocalId']! as String,
      type: row['type']! as String, amountToman: row['amountToman']! as int,
      occurredAt: DateTime.parse(row['occurredAt']! as String), note: row['note'] as String?,
      synced: row['synced'] == 1,
    )).toList();
  }

  Future<void> markLedgerSynced(String localId, String serverId) async => (await database).update(
    'ledger_entries', {'serverId': serverId, 'synced': 1, 'lastError': null}, where: 'localId = ?', whereArgs: [localId]);

  Future<void> markError(String table, String localId, Object error) async {
    const allowed = {'sellers', 'purchases', 'ledger_entries'};
    if (allowed.contains(table)) {
      await (await database).update(table, {'lastError': error.toString()}, where: 'localId = ?', whereArgs: [localId]);
    }
  }

  Future<int> pendingCount() async {
    final db = await database;
    var total = 0;
    for (final table in ['sellers', 'purchases', 'ledger_entries']) {
      total += Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table WHERE synced = 0')) ?? 0;
    }
    return total;
  }
}
