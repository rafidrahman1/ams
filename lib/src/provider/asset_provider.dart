import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/storage/local_database.dart';
import '../model/asset_checklist_item.dart';
import '../model/location_models.dart';
import '../model/volunteer_asset.dart';
import '../core/repositories/asset_repository.dart';
import '../services/asset_service.dart';

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
  final checklist = await ref.watch(assetChecklistProvider(astId).future);
  if (checklist.items.isEmpty) {
    return false;
  }

  return checklist.items.every((item) => item.response);
});

final homeBootstrapProvider = FutureProvider<void>((ref) async {
  final assets = await ref.watch(myAssetsProvider.future);

  await Future.wait(assets.map((asset) => ref.watch(assetChecklistAllTrueProvider(asset.astId).future)));
});

final adminHomeBootstrapProvider = FutureProvider<void>((ref) async {
  await Future.wait([ref.watch(adminAssetsProvider.future), ref.watch(unsyncedRegisteredDevicesProvider.future)]);
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

  return assetsAsync.whenData((assets) {
    final filtered = <VolunteerAsset>[];
    for (final asset in assets) {
      final isAllTrue = ref.watch(assetChecklistAllTrueProvider(asset.astId)).maybeWhen(data: (d) => d, orElse: () => false);
      if (showAllTrue == isAllTrue) {
        filtered.add(asset);
      }
    }
    return filtered;
  });
});
