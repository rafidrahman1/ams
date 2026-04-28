import 'package:asset_management_system/src/core/storage/local_database.dart';
import 'package:asset_management_system/src/features/data/models/volunteer_asset.dart';
import 'package:asset_management_system/src/features/presentation/providers/asset_provider.dart';
import 'package:asset_management_system/src/features/presentation/screens/qr_nfc_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/asset_card_builder.dart';
import '../../../widgets/asset_list_skeleton.dart';
import '../register_device_screen.dart';

class HomeAssetsListSection extends ConsumerWidget {
  const HomeAssetsListSection({
    super.key,
    required this.assetsLabel,
    required this.noFullyCheckedAssetsFoundLabel,
    required this.noPartiallyCheckedAssetsFoundLabel,
    required this.assetsAsync,
    required this.unsyncedDevicesAsync,
    required this.forceLoading,
    required this.isAdmin,
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
  final AsyncValue<List<VolunteerAsset>> assetsAsync;
  final AsyncValue<List<RegisteredDeviceData>> unsyncedDevicesAsync;
  final bool forceLoading;
  final bool isAdmin;
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
          final unsyncedDevices = unsyncedDevicesAsync.maybeWhen(data: (d) => d, orElse: () => <RegisteredDeviceData>[]);

          if (assets.isEmpty && unsyncedDevices.isEmpty) {
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [SizedBox(height: 240, child: Center(child: Text(assetsLabel)))],
              ),
            );
          }

          if (isAdmin) {
            final combinedCount = assets.length + unsyncedDevices.length;
            final visibleUnsyncedCount = unsyncedDevices.length.clamp(0, visibleAssetCount);
            final visibleAssetsCount = (visibleAssetCount - visibleUnsyncedCount).clamp(0, assets.length);

            final visibleUnsynced = unsyncedDevices.take(visibleUnsyncedCount).toList();
            final visibleAssets = assets.take(visibleAssetsCount).toList();

            final hasMore = (visibleUnsynced.length + visibleAssets.length) < combinedCount;
            ensureScrollablePage(hasMore);

            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  ...visibleUnsynced.map(
                    (device) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Dismissible(
                        key: Key('device-${device.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          if (device.id != null) {
                            await ref.read(assetRepositoryProvider).deleteRegisteredDevice(device.id!);
                            ref.invalidate(unsyncedRegisteredDevicesProvider);
                          }
                        },
                        child: Card(
                          color: Colors.orange.shade50,
                          child: ListTile(
                            title: Text(device.name),
                            subtitle: Text('${device.details}\n(Pending Sync)'),
                            isThreeLine: true,
                            trailing: const Icon(Icons.sync_problem, color: Colors.orange),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ...visibleAssets.map((apiAsset) {
                    final asset = AssetCardData(title: apiAsset.name, description: apiAsset.details, astId: apiAsset.astId);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Dismissible(
                        key: Key('asset-${apiAsset.astId}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await ref.read(assetRepositoryProvider).deleteAsset(apiAsset.astId);
                          ref.invalidate(isAdmin ? adminAssetsProvider : myAssetsProvider);
                        },
                        child: Card(
                          color: Colors.white,
                          child: ListTile(
                            title: Text(asset.title),
                            subtitle: Text(asset.description.isNotEmpty ? asset.description : asset.astId),
                            trailing: ElevatedButton(
                              onPressed: isSyncing
                                  ? null
                                  : () {
                                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterDeviceScreen(asset: asset)));
                                    },
                              child: const Text('Register device'),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (hasMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            );
          }

          final filteredAssets = assets;

          onFilteredCountChanged(filteredAssets.length);

          final visibleAssets = filteredAssets.take(visibleAssetCount).toList(growable: false);
          final hasMoreAssets = visibleAssets.length < filteredAssets.length;
          ensureScrollablePage(hasMoreAssets);

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
                    child: Dismissible(
                      key: Key('asset-${apiAsset.astId}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await ref.read(assetRepositoryProvider).deleteAsset(apiAsset.astId);
                        ref.invalidate(isAdmin ? adminAssetsProvider : myAssetsProvider);
                        if (!isAdmin) {
                          ref.invalidate(filteredAssetsProvider);
                        }
                      },
                      child: AssetCardBuilder(
                        asset: asset,
                        onSync: isSyncing
                            ? null
                            : () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => QrNfcScreen(asset: asset)));
                              },
                      ),
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
