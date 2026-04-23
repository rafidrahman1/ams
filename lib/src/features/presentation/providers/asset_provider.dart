import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../data/models/asset_checklist_item.dart';
import '../../data/models/volunteer_asset.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/services/asset_service.dart';

final assetServiceProvider = Provider<AssetService>((ref) {
  return AssetService(ref.read(apiClientProvider));
});

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.read(assetServiceProvider), () => ref.read(tokenStorageProvider).getSessionKey(), ref.read(localDatabaseProvider));
});

final myAssetsProvider = FutureProvider<List<VolunteerAsset>>((ref) {
  return ref.read(assetRepositoryProvider).fetchMyAssets();
});

final assetChecklistProvider = FutureProvider.family<List<AssetChecklistItem>, String>((ref, astId) {
  return ref.read(assetRepositoryProvider).fetchChecklistByAssetId(astId);
});

final assetChecklistAllTrueProvider = FutureProvider.family<bool, String>((ref, astId) async {
  final checklist = await ref.watch(assetChecklistProvider(astId).future);
  if (checklist.isEmpty) {
    return false;
  }

  return checklist.every((item) => item.response);
});

final homeBootstrapProvider = FutureProvider<void>((ref) async {
  final assets = await ref.watch(myAssetsProvider.future);

  await Future.wait(assets.map((asset) => ref.watch(assetChecklistAllTrueProvider(asset.astId).future)));
});
