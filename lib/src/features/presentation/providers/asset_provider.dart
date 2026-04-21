import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/volunteer_asset.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/services/asset_service.dart';
import 'auth_provider.dart';

final assetServiceProvider = Provider<AssetService>((ref) {
  return AssetService(ref.read(apiClientProvider));
});

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.read(assetServiceProvider));
});

final myAssetsProvider = FutureProvider<List<VolunteerAsset>>((ref) {
  return ref.read(assetRepositoryProvider).fetchMyAssets();
});
