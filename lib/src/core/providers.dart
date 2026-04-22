import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/api_client.dart';
import 'storage/asset_cache_store.dart';
import 'storage/toggle_response_queue_store.dart';
import 'storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(tokenStorageProvider));
});

final assetCacheStoreProvider = Provider<AssetCacheStore>((ref) {
  return AssetCacheStore();
});

final toggleResponseQueueStoreProvider = Provider<ToggleResponseQueueStore>((ref) {
  return ToggleResponseQueueStore();
});
