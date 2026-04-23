import 'package:asset_management_system/src/features/presentation/screens/qr_nfc_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/asset_provider.dart';
import '../../../widgets/asset_card_builder.dart';
import '../../../widgets/asset_list_skeleton.dart';

class HomeAssetsListSection extends ConsumerWidget {
  const HomeAssetsListSection({
    super.key,
    required this.assetsLabel,
    required this.noFullyCheckedAssetsFoundLabel,
    required this.noPartiallyCheckedAssetsFoundLabel,
    required this.assetsAsync,
    required this.forceLoading,
    required this.showAllTrueAssets,
    required this.visibleAssetCount,
    required this.skeletonItemCount,
    required this.isSyncing,
    required this.scrollController,
    required this.onRefresh,
    required this.onFilteredCountChanged,
    required this.ensureScrollablePage,
  });

  final String assetsLabel;
  final String noFullyCheckedAssetsFoundLabel;
  final String noPartiallyCheckedAssetsFoundLabel;
  final AsyncValue<List<dynamic>> assetsAsync;
  final bool forceLoading;
  final bool showAllTrueAssets;
  final int visibleAssetCount;
  final int skeletonItemCount;
  final bool isSyncing;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onFilteredCountChanged;
  final ValueChanged<bool> ensureScrollablePage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (forceLoading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: AssetListSkeleton(itemCount: skeletonItemCount),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: assetsAsync.when(
        loading: () => AssetListSkeleton(itemCount: skeletonItemCount),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (assets) {
          if (assets.isEmpty) {
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [SizedBox(height: 240, child: Center(child: Text(assetsLabel)))],
              ),
            );
          }

          final filteredAssets = assets
              .where((apiAsset) {
                final isAllTrueAsync = ref.watch(assetChecklistAllTrueProvider(apiAsset.astId));
                return isAllTrueAsync.maybeWhen(data: (isAllTrue) => showAllTrueAssets ? isAllTrue : !isAllTrue, orElse: () => false);
              })
              .toList(growable: false);

          onFilteredCountChanged(filteredAssets.length);

          final visibleAssets = filteredAssets.take(visibleAssetCount).toList(growable: false);
          final hasMoreAssets = visibleAssets.length < filteredAssets.length;
          ensureScrollablePage(hasMoreAssets);

          final hasLoadingStatuses = assets.any((apiAsset) => ref.watch(assetChecklistAllTrueProvider(apiAsset.astId)).isLoading);

          if (filteredAssets.isEmpty && hasLoadingStatuses) {
            return AssetListSkeleton(itemCount: skeletonItemCount);
          }

          if (filteredAssets.isEmpty) {
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [SizedBox(height: 240, child: Center(child: Text(showAllTrueAssets ? noFullyCheckedAssetsFoundLabel : noPartiallyCheckedAssetsFoundLabel)))],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ...visibleAssets.map((apiAsset) {
                  final asset = AssetCardData(title: apiAsset.name, description: apiAsset.details, astId: apiAsset.astId);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: AssetCardBuilder(
                      asset: asset,
                      onSync: isSyncing
                          ? null
                          : () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => QrNfcScreen(asset: asset)));
                            },
                    ),
                  );
                }),
                if (hasMoreAssets)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
