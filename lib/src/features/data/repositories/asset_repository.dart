import 'package:asset_management_system/src/core/storage/asset_cache_store.dart';
import 'package:asset_management_system/src/core/storage/toggle_response_queue_store.dart';

import '../models/asset_checklist_item.dart';
import '../models/volunteer_asset.dart';
import '../services/asset_service.dart';

class AssetRepository {
  final AssetService service;
  final Future<String?> Function() getUserKey;
  final AssetCacheStore cache;
  final ToggleResponseQueueStore toggleQueue;

  AssetRepository(this.service, this.getUserKey, this.cache, this.toggleQueue);

  Future<String?> _resolvedUserKey() async {
    final key = (await getUserKey())?.trim();
    return key == null || key.isEmpty ? null : key;
  }

  Future<List<AssetChecklistItem>> _applyPendingToggles(List<AssetChecklistItem> checklist) async {
    final pending = await toggleQueue.loadPending();
    if (pending.isEmpty || checklist.isEmpty) {
      return checklist;
    }

    final toggleCounts = <int, int>{};
    for (final item in pending) {
      toggleCounts.update(item.featureId, (count) => count + 1, ifAbsent: () => 1);
    }

    return checklist
        .map((item) {
          final pendingToggleCount = toggleCounts[item.featureId] ?? 0;
          if (pendingToggleCount.isOdd) {
            return AssetChecklistItem(featureId: item.featureId, title: item.title, response: !item.response);
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
        await cache.saveAssets(userKey, assets);
      }
      return assets;
    } catch (_) {
      if (userKey != null) {
        final cachedAssets = await cache.loadAssets(userKey);
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
        await cache.saveChecklist(userKey, astId, checklist);
      }
      return _applyPendingToggles(checklist);
    } catch (_) {
      if (userKey != null) {
        final cachedChecklist = await cache.loadChecklist(userKey, astId);
        if (cachedChecklist.isNotEmpty) {
          return _applyPendingToggles(cachedChecklist);
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
      await cache.saveAssets(trimmedUserKey, assets);

      for (final asset in assets) {
        final astId = asset.astId.trim();
        if (astId.isEmpty) {
          continue;
        }

        try {
          final checklist = await service.fetchChecklistByAssetId(astId);
          await cache.saveChecklist(trimmedUserKey, astId, checklist);
        } catch (_) {
          final cachedChecklist = await cache.loadChecklist(trimmedUserKey, astId);
          if (cachedChecklist.isNotEmpty) {
            await cache.saveChecklist(trimmedUserKey, astId, cachedChecklist);
          }
        }
      }
    } catch (_) {
      // Best effort: login should still succeed even if the prefetch fails.
    }
  }

  Future<int> queueResponseToggles(Iterable<int> featureIds) {
    return toggleQueue.enqueueAll(featureIds);
  }

  Future<ToggleSyncResult> syncQueuedResponses() async {
    final pending = await toggleQueue.loadPending();
    if (pending.isEmpty) {
      return const ToggleSyncResult(totalPending: 0, synced: 0, failed: 0);
    }

    final featureQueueIds = <int, List<int>>{};
    for (final item in pending) {
      featureQueueIds.putIfAbsent(item.featureId, () => <int>[]).add(item.queueId);
    }

    final removableQueueIds = <int>[];
    final oddParityFeatureIds = <int>[];

    featureQueueIds.forEach((featureId, queueIds) {
      if (queueIds.length.isEven) {
        // Even toggle counts cancel out and do not need a network sync.
        removableQueueIds.addAll(queueIds);
        return;
      }

      // Keep only the latest pending toggle for this feature as the sync action.
      if (queueIds.length > 1) {
        removableQueueIds.addAll(queueIds.sublist(0, queueIds.length - 1));
      }
      oddParityFeatureIds.add(featureId);
    });

    var syncedCount = 0;
    var failedCount = 0;

    for (final featureId in oddParityFeatureIds) {
      final queueIds = featureQueueIds[featureId]!;
      final latestQueueId = queueIds.last;

      try {
        await service.toggleChecklistResponse(featureId);
        removableQueueIds.add(latestQueueId);
        syncedCount += 1;
      } catch (_) {
        failedCount += 1;
      }
    }

    await toggleQueue.removeQueuedIds(removableQueueIds);

    return ToggleSyncResult(totalPending: oddParityFeatureIds.length, synced: syncedCount, failed: failedCount);
  }
}

class ToggleSyncResult {
  final int totalPending;
  final int synced;
  final int failed;

  const ToggleSyncResult({required this.totalPending, required this.synced, required this.failed});
}
