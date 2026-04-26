import 'package:asset_management_system/src/core/storage/local_database.dart';
import 'dart:convert';

import '../models/asset_checklist_item.dart';
import '../models/volunteer_asset.dart';
import '../services/asset_service.dart';

class AssetRepository {
  final AssetService service;
  final Future<String?> Function() getUserKey;
  final LocalDatabase db;

  AssetRepository(this.service, this.getUserKey, this.db);

  Future<String?> _resolvedUserKey() async {
    final key = (await getUserKey())?.trim();
    return key == null || key.isEmpty ? null : key;
  }

  Future<List<VolunteerAsset>> fetchMyAssets() async {
    final userKey = await _resolvedUserKey();

    try {
      final assets = await service.fetchMyAssets();
      if (userKey != null) {
        await db.saveAssets(userKey, assets);
      }
      return assets;
    } catch (_) {
      if (userKey != null) {
        final cachedAssets = await db.loadAssets(userKey);
        if (cachedAssets.isNotEmpty) {
          return cachedAssets;
        }
      }

      rethrow;
    }
  }

  Future<List<AssetChecklistItem>> fetchChecklistByAssetId(String astId) async {
    final userKey = await _resolvedUserKey();

    try {
      final checklist = await service.fetchChecklistByAssetId(astId);
      if (userKey != null) {
        await db.saveChecklist(userKey, astId, checklist);
      }

      return userKey != null ? await _applyPendingSubmission(userKey, astId, checklist) : checklist;
    } catch (_) {
      if (userKey != null) {
        final cachedChecklist = await db.loadChecklist(userKey, astId);
        if (cachedChecklist.isNotEmpty) {
          return _applyPendingSubmission(userKey, astId, cachedChecklist);
        }
      }

      rethrow;
    }
  }

  Future<List<AssetChecklistItem>> _applyPendingSubmission(String userKey, String astId, List<AssetChecklistItem> checklist) async {
    final payloadJson = await db.loadLatestChecklistSubmissionPayload(userKey, astId);
    if (payloadJson == null || payloadJson.trim().isEmpty || checklist.isEmpty) {
      return checklist;
    }

    try {
      final payload = jsonDecode(payloadJson);
      if (payload is! Map<String, dynamic>) return checklist;
      final items = payload['items'] as List<dynamic>? ?? const <dynamic>[];

      final latestStates = <int, bool>{};
      for (final it in items.whereType<Map<String, dynamic>>()) {
        final featureId = _asInt(it['feature_id'] ?? it['featureId']);
        if (featureId != 0) {
          latestStates[featureId] = _asBool(it['response']);
        }
      }

      if (latestStates.isEmpty) return checklist;

      return checklist
          .map((item) => latestStates.containsKey(item.featureId) ? AssetChecklistItem(featureId: item.featureId, title: item.title, response: latestStates[item.featureId]!) : item)
          .toList(growable: false);
    } catch (_) {
      return checklist;
    }
  }

  Future<void> prefetchOfflineData(String userKey) async {
    final trimmedUserKey = userKey.trim();
    if (trimmedUserKey.isEmpty) {
      return;
    }

    try {
      final assets = await service.fetchMyAssets();
      await db.saveAssets(trimmedUserKey, assets);

      for (final asset in assets) {
        final astId = asset.astId.trim();
        if (astId.isEmpty) {
          continue;
        }

        try {
          final checklist = await service.fetchChecklistByAssetId(astId);
          await db.saveChecklist(trimmedUserKey, astId, checklist);
        } catch (_) {
          final cachedChecklist = await db.loadChecklist(trimmedUserKey, astId);
          if (cachedChecklist.isNotEmpty) {
            await db.saveChecklist(trimmedUserKey, astId, cachedChecklist);
          }
        }
      }
    } catch (_) {
      // Best effort: login should still succeed even if the prefetch fails.
    }
  }

  Future<int> queueChecklistSubmission({
    required String astId,
    required String status,
    required String remark,
    required List<({int featureId, bool response})> items,
  }) async {
    final userKey = await _resolvedUserKey();
    if (userKey == null) return 0;

    final payloadJson = jsonEncode({
      'ast_ID': astId,
      'status': status,
      'remark': remark,
      'items': items.map((i) => {'feature_id': i.featureId, 'response': i.response}).toList(growable: false),
    });
    return db.enqueueChecklistSubmission(userKey, astId, payloadJson);
  }

  Future<void> submitChecklist({
    required String astId,
    required String status,
    required String remark,
    required List<({int featureId, bool response})> items,
  }) async {
    final userKey = await _resolvedUserKey();
    if (userKey == null) {
      throw Exception('Missing session');
    }

    try {
      await service.submitChecklist(astId: astId, status: status, remark: remark, items: items);
      // Keep the local cache aligned with what the user just submitted.
      final updatedChecklist =
          items.map((i) => AssetChecklistItem(featureId: i.featureId, title: '', response: i.response)).toList(growable: false);
      // We don't have titles here; preserve cached titles by merging with last cached checklist if possible.
      final cached = await db.loadChecklist(userKey, astId);
      if (cached.isNotEmpty) {
        final titleMap = {for (final c in cached) c.featureId: c.title};
        await db.saveChecklist(
          userKey,
          astId,
          updatedChecklist.map((i) => AssetChecklistItem(featureId: i.featureId, title: titleMap[i.featureId] ?? '', response: i.response)).toList(growable: false),
        );
      } else {
        await db.saveChecklist(userKey, astId, updatedChecklist);
      }
    } catch (_) {
      // Offline / failure: queue for later sync instead of failing the UI.
      await queueChecklistSubmission(astId: astId, status: status, remark: remark, items: items);
    }
  }

  Future<ToggleSyncResult> syncQueuedResponses() async {
    final userKey = await _resolvedUserKey();
    if (userKey == null) {
      return const ToggleSyncResult(totalPending: 0, synced: 0, failed: 0);
    }

    final pending = await db.loadPendingChecklistSubmissions(userKey);
    if (pending.isEmpty) {
      return const ToggleSyncResult(totalPending: 0, synced: 0, failed: 0);
    }

    var syncedCount = 0;
    var failedCount = 0;
    final removableQueueIds = <int>[];

    // For each asset, only submit the latest queued payload.
    final latestByAsset = <String, ChecklistSubmissionQueueItem>{};
    for (final item in pending) {
      latestByAsset[item.astId] = item;
    }

    for (final entry in latestByAsset.entries) {
      final queueItem = entry.value;
      try {
        final payload = jsonDecode(queueItem.payloadJson);
        if (payload is! Map<String, dynamic>) {
          failedCount += 1;
          continue;
        }

        final astId = (payload['ast_ID'] ?? queueItem.astId).toString();
        final status = (payload['status'] ?? '').toString();
        final remark = (payload['remark'] ?? '').toString();
        final itemsRaw = payload['items'] as List<dynamic>? ?? const <dynamic>[];
        final items = <({int featureId, bool response})>[];
        for (final it in itemsRaw.whereType<Map<String, dynamic>>()) {
          final featureId = _asInt(it['feature_id'] ?? it['featureId']);
          if (featureId == 0) continue;
          items.add((featureId: featureId, response: _asBool(it['response'])));
        }

        await service.submitChecklist(astId: astId, status: status, remark: remark, items: items);
        syncedCount += 1;
        removableQueueIds.add(queueItem.queueId);
      } catch (_) {
        failedCount += 1;
      }
    }

    if (removableQueueIds.isNotEmpty) {
      await db.markQueuedChecklistSubmissionsSynced(removableQueueIds);
    }

    return ToggleSyncResult(totalPending: pending.length, synced: syncedCount, failed: failedCount);
  }

  Future<void> clearCache() async {
    await db.clearAll();
  }
}

class ToggleSyncResult {
  final int totalPending;
  final int synced;
  final int failed;

  const ToggleSyncResult({required this.totalPending, required this.synced, required this.failed});
}

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}
