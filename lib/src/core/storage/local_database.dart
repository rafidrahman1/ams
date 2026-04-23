import 'package:asset_management_system/src/features/data/models/asset_checklist_item.dart';
import 'package:asset_management_system/src/features/data/models/volunteer_asset.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ToggleResponseQueueItem {
  final int queueId;
  final String astId;
  final int featureId;
  final bool targetState;

  const ToggleResponseQueueItem({required this.queueId, required this.astId, required this.featureId, required this.targetState});
}

class LocalDatabase {
  static const _databaseName = 'asset_management_system.db';
  static const _togglesTable = 'pending_response_toggles';
  static const _assetsTable = 'cached_assets';
  static const _checklistTable = 'cached_checklist_items';

  Future<Database>? _dbFuture;

  Future<Database> _getDatabase() {
    _dbFuture ??= _openDatabase();
    return _dbFuture!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, _databaseName),
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS $_togglesTable');
          await _createTables(db);
        } else if (oldVersion < 3) {
          // Add ast_id and target_state to toggles table
          await db.execute('ALTER TABLE $_togglesTable ADD COLUMN ast_id TEXT NOT NULL DEFAULT ""');
          await db.execute('ALTER TABLE $_togglesTable ADD COLUMN target_state INTEGER NOT NULL DEFAULT 0');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_togglesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_key TEXT NOT NULL,
        ast_id TEXT NOT NULL,
        feature_id INTEGER NOT NULL,
        target_state INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_assetsTable (
        user_key TEXT NOT NULL,
        ast_id TEXT NOT NULL,
        name TEXT NOT NULL,
        details TEXT NOT NULL,
        PRIMARY KEY (user_key, ast_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE $_checklistTable (
        user_key TEXT NOT NULL,
        ast_id TEXT NOT NULL,
        feature_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        response INTEGER NOT NULL,
        PRIMARY KEY (user_key, ast_id, feature_id)
      )
    ''');
  }

  // Assets Cache
  Future<void> saveAssets(String userKey, List<VolunteerAsset> assets) async {
    final db = await _getDatabase();
    await db.transaction((txn) async {
      await txn.delete(_assetsTable, where: 'user_key = ?', whereArgs: [userKey]);
      final batch = txn.batch();
      for (final asset in assets) {
        batch.insert(_assetsTable, {'user_key': userKey, 'ast_id': asset.astId, 'name': asset.name, 'details': asset.details});
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<VolunteerAsset>> loadAssets(String userKey) async {
    final db = await _getDatabase();
    final rows = await db.query(_assetsTable, where: 'user_key = ?', whereArgs: [userKey]);
    return rows.map((row) => VolunteerAsset(name: row['name'] as String, details: row['details'] as String, astId: row['ast_id'] as String)).toList();
  }

  // Checklist Cache
  Future<void> saveChecklist(String userKey, String astId, List<AssetChecklistItem> items) async {
    final db = await _getDatabase();
    await db.transaction((txn) async {
      await txn.delete(_checklistTable, where: 'user_key = ? AND ast_id = ?', whereArgs: [userKey, astId]);
      final batch = txn.batch();
      for (final item in items) {
        batch.insert(_checklistTable, {'user_key': userKey, 'ast_id': astId, 'feature_id': item.featureId, 'title': item.title, 'response': item.response ? 1 : 0});
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<AssetChecklistItem>> loadChecklist(String userKey, String astId) async {
    final db = await _getDatabase();
    final rows = await db.query(_checklistTable, where: 'user_key = ? AND ast_id = ?', whereArgs: [userKey, astId]);
    return rows.map((row) => AssetChecklistItem(featureId: row['feature_id'] as int, title: row['title'] as String, response: (row['response'] as int) == 1)).toList();
  }

  // Pending Toggles
  Future<int> enqueueToggles(String userKey, String astId, List<({int featureId, bool targetState})> toggles) async {
    if (toggles.isEmpty) return 0;

    final db = await _getDatabase();
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final toggle in toggles) {
      batch.insert(_togglesTable, {'user_key': userKey, 'ast_id': astId, 'feature_id': toggle.featureId, 'target_state': toggle.targetState ? 1 : 0, 'created_at': now});
    }

    await batch.commit(noResult: true);
    return toggles.length;
  }

  Future<List<ToggleResponseQueueItem>> loadPendingToggles(String userKey) async {
    final db = await _getDatabase();
    final rows = await db.query(_togglesTable, where: 'user_key = ?', whereArgs: [userKey], orderBy: 'id ASC');

    return rows
        .map(
          (row) => ToggleResponseQueueItem(
            queueId: row['id'] as int,
            astId: row['ast_id'] as String,
            featureId: row['feature_id'] as int,
            targetState: (row['target_state'] as int) == 1,
          ),
        )
        .toList(growable: false);
  }

  Future<void> removeQueuedToggles(Iterable<int> queueIds) async {
    final ids = queueIds.toList(growable: false);
    if (ids.isEmpty) return;

    final db = await _getDatabase();
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.delete(_togglesTable, where: 'id IN ($placeholders)', whereArgs: ids);
  }

  Future<void> clearUserData(String userKey) async {
    final db = await _getDatabase();
    await db.transaction((txn) async {
      // Clear cache but keep pending toggles so they can sync on next login
      await txn.delete(_assetsTable, where: 'user_key = ?', whereArgs: [userKey]);
      await txn.delete(_checklistTable, where: 'user_key = ?', whereArgs: [userKey]);
    });
  }

  Future<void> clearAll() async {
    final db = await _getDatabase();
    await db.delete(_assetsTable);
    await db.delete(_checklistTable);
    await db.delete(_togglesTable);
  }
}
