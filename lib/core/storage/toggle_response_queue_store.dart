import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ToggleResponseQueueItem {
  final int queueId;
  final int featureId;

  const ToggleResponseQueueItem({required this.queueId, required this.featureId});
}

class ToggleResponseQueueStore {
  static const _databaseName = 'asset_management_system.db';
  static const _tableName = 'pending_response_toggles';

  Future<Database>? _dbFuture;

  Future<Database> _database() {
    _dbFuture ??= _openDatabase();
    return _dbFuture!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, _databaseName),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            feature_id INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> enqueueAll(Iterable<int> featureIds) async {
    final cleaned = featureIds.where((id) => id > 0).toList(growable: false);
    if (cleaned.isEmpty) {
      return 0;
    }

    final db = await _database();
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final featureId in cleaned) {
      batch.insert(_tableName, {'feature_id': featureId, 'created_at': now});
    }

    await batch.commit(noResult: true);
    return cleaned.length;
  }

  Future<List<ToggleResponseQueueItem>> loadPending() async {
    final db = await _database();
    final rows = await db.query(_tableName, columns: ['id', 'feature_id'], orderBy: 'id ASC');

    return rows.map((row) => ToggleResponseQueueItem(queueId: row['id'] as int, featureId: row['feature_id'] as int)).toList(growable: false);
  }

  Future<void> removeQueuedIds(Iterable<int> queueIds) async {
    final ids = queueIds.toList(growable: false);
    if (ids.isEmpty) {
      return;
    }

    final db = await _database();
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.delete(_tableName, where: 'id IN ($placeholders)', whereArgs: ids);
  }

  Future<void> clear() async {
    final db = await _database();
    await db.delete(_tableName);
  }
}
