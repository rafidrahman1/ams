import 'package:asset_management_system/src/core/storage/local_database.dart';

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

  Future<List<AssetChecklistItem>> _applyPendingToggles(String userKey, List<AssetChecklistItem> checklist) async {
    final pending = await db.loadPendingToggles(userKey);
    if (pending.isEmpty || checklist.isEmpty) {
      return checklist;
    }

    final latestTargetStates = <int, bool>{};
    for (final item in pending) {
      latestTargetStates[item.featureId] = item.targetState;
    }

    return checklist
        .map((item) {
          if (latestTargetStates.containsKey(item.featureId)) {
            return AssetChecklistItem(featureId: item.featureId, title: item.title, response: latestTargetStates[item.featureId]!);
          }
          return item;
        })
        .toList(growable: false);
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

      return userKey != null ? await _applyPendingToggles(userKey, checklist) : checklist;
    } catch (_) {
      if (userKey != null) {
        final cachedChecklist = await db.loadChecklist(userKey, astId);
        if (cachedChecklist.isNotEmpty) {
          return _applyPendingToggles(userKey, cachedChecklist);
        }
      }

      rethrow;
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

  Future<int> queueResponseToggles(String astId, List<({int featureId, bool targetState})> toggles) async {
    final userKey = await _resolvedUserKey();
    if (userKey == null) return 0;

    return db.enqueueToggles(userKey, astId, toggles);
  }

  Future<ToggleSyncResult> syncQueuedResponses() async {
    final userKey = await _resolvedUserKey();
    if (userKey == null) {
      return const ToggleSyncResult(totalPending: 0, synced: 0, failed: 0);
    }

    final pending = await db.loadPendingToggles(userKey);
    if (pending.isEmpty) {
      return const ToggleSyncResult(totalPending: 0, synced: 0, failed: 0);
    }

    final groups = <String, List<ToggleResponseQueueItem>>{};
    for (final item in pending) {
      groups.putIfAbsent(item.astId, () => []).add(item);
    }

    var syncedCount = 0;
    var failedCount = 0;
    final removableQueueIds = <int>[];

    for (final entry in groups.entries) {
      final astId = entry.key;
      final toggles = entry.value;

      try {
        final serverChecklist = await service.fetchChecklistByAssetId(astId);
        final serverStateMap = {for (var item in serverChecklist) item.featureId: item.response};

        final uniqueFeatures = <int, ToggleResponseQueueItem>{};
        for (final t in toggles) {
          uniqueFeatures[t.featureId] = t;
        }

        bool groupSuccess = true;
        for (final featureId in uniqueFeatures.keys) {
          final target = uniqueFeatures[featureId]!;
          final currentOnServer = serverStateMap[featureId] ?? false;

          if (currentOnServer != target.targetState) {
            try {
              await service.toggleChecklistResponse(featureId);
              syncedCount++;
            } catch (_) {
              failedCount++;
              groupSuccess = false;
            }
          } else {
            syncedCount++;
          }
        }

        if (groupSuccess) {
          final verifiedChecklist = await service.fetchChecklistByAssetId(astId);
          final verifiedStateMap = {for (var item in verifiedChecklist) item.featureId: item.response};

          bool allVerified = true;
          for (final featureId in uniqueFeatures.keys) {
            final target = uniqueFeatures[featureId]!;
            if (verifiedStateMap[featureId] != target.targetState) {
              try {
                await service.toggleChecklistResponse(featureId);
              } catch (_) {
                allVerified = false;
              }
            }
          }

          if (allVerified) {
            removableQueueIds.addAll(toggles.map((t) => t.queueId));
          }
        }
      } catch (_) {
        failedCount += toggles.length;
      }
    }

    if (removableQueueIds.isNotEmpty) {
      await db.removeQueuedToggles(removableQueueIds);
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
