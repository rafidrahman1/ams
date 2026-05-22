import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/storage/local_database.dart';
import '../data/models/asset_checklist_item.dart';
import '../data/models/location_models.dart';
import '../data/models/volunteer_asset.dart';
import '../data/repositories/asset_repository.dart';
import '../data/services/asset_service.dart';

final assetServiceProvider = Provider<AssetService>((ref) {
  return AssetService(ref.read(apiClientProvider));
});

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository.withCache(
    ref.read(assetServiceProvider),
    () => ref.read(tokenStorageProvider).getSessionKey(),
    ref.read(localDatabaseProvider),
    ref.read(assetCacheStoreProvider),
  );
});

final myAssetsProvider = FutureProvider<List<VolunteerAsset>>((ref) {
  return ref.read(assetRepositoryProvider).fetchMyAssets();
});

final adminAssetsProvider = FutureProvider<List<VolunteerAsset>>((ref) {
  return ref.read(assetRepositoryProvider).fetchAdminAssets();
});

final assetChecklistProvider = FutureProvider.family<AssetChecklist, String>((ref, astId) {
  return ref.read(assetRepositoryProvider).fetchChecklistByAssetId(astId);
});

final campLocationsProvider = FutureProvider<List<IdNamePair>>((ref) {
  return ref.read(assetRepositoryProvider).fetchCampLocations();
});

final blocksProvider = FutureProvider.family<List<IdNamePair>, int>((ref, campId) {
  return ref.read(assetRepositoryProvider).fetchBlocks(campId);
});

final assetTypesProvider = FutureProvider<List<IdNamePair>>((ref) {
  return ref.read(assetRepositoryProvider).fetchAssetTypes();
});

final assetChecklistAllTrueProvider = FutureProvider.family<bool, String>((ref, astId) async {
  // Use `read` here to await the other FutureProvider without creating an
  // additional active subscription. Using `watch(... .future)` inside a
  // FutureProvider can create overlapping subscriptions that lead to
  // pausedActiveSubscriptionCount assertion errors when providers are
  // invalidated/refreshed from the UI. Reading the future avoids that.
  final checklist = await ref.read(assetChecklistProvider(astId).future);
  if (checklist.items.isEmpty) {
    return false;
  }

  return checklist.items.every((item) => item.response);
});

/// Caps parallel checklist fetches so home load does not flood the network/UI thread.
const _checklistPrefetchConcurrency = 4;

Future<Map<String, bool>> _loadAllTrueStatesForAssets(Ref ref, List<VolunteerAsset> assets) async {
  final states = <String, bool>{};
  if (assets.isEmpty) {
    return states;
  }

  for (var start = 0; start < assets.length; start += _checklistPrefetchConcurrency) {
    final end = (start + _checklistPrefetchConcurrency).clamp(0, assets.length);
    final batch = assets.sublist(start, end);
    final batchResults = await Future.wait(
      batch.map((asset) async {
        final isAllTrue = await ref.read(assetChecklistAllTrueProvider(asset.astId).future);
        return MapEntry(asset.astId, isAllTrue);
      }),
    );
    states.addEntries(batchResults);
  }

  return states;
}

final assetAllTrueStatesProvider = FutureProvider<Map<String, bool>>((ref) async {
  final assets = await ref.watch(myAssetsProvider.future);
  return _loadAllTrueStatesForAssets(ref, assets);
});

final homeBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.watch(assetAllTrueStatesProvider.future);
});

final adminHomeBootstrapProvider = FutureProvider<void>((ref) async {
  // Read both futures instead of watching them to avoid nested active
  // subscriptions that can cause Riverpod pause-count assertion failures
  // when the UI invalidates or refreshes providers.
  await Future.wait([ref.read(adminAssetsProvider.future), ref.read(unsyncedRegisteredDevicesProvider.future)]);
});

final unsyncedRegisteredDevicesProvider = FutureProvider<List<RegisteredDeviceData>>((ref) {
  return ref.read(assetRepositoryProvider).getUnsyncedRegisteredDevices();
});

final registeredDeviceProvider = FutureProvider.family<RegisteredDeviceData?, int>((ref, id) {
  return ref.read(assetRepositoryProvider).getRegisteredDeviceById(id);
});

class ShowAllTrueAssets extends Notifier<bool> {
  @override
  bool build() => false;

  void update(bool value) => state = value;
}

final showAllTrueAssetsProvider = NotifierProvider<ShowAllTrueAssets, bool>(ShowAllTrueAssets.new);

final filteredAssetsProvider = Provider<AsyncValue<List<VolunteerAsset>>>((ref) {
  final assetsAsync = ref.watch(myAssetsProvider);
  final showAllTrue = ref.watch(showAllTrueAssetsProvider);
  final allTrueStatesAsync = ref.watch(assetAllTrueStatesProvider);

  return assetsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
    data: (assets) {
      // While checklist states load, treat unknown assets as not fully checked so the
      // list can render immediately without N provider subscriptions in a loop.
      final allTrueByAstId = allTrueStatesAsync.value ?? const <String, bool>{};
      final filtered = assets.where((asset) {
        final isAllTrue = allTrueByAstId[asset.astId] ?? false;
        return showAllTrue == isAllTrue;
      }).toList(growable: false);
      return AsyncValue.data(filtered);
    },
  );
});
