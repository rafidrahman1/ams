import 'package:asset_management_system/core/storage/local_database.dart';
import 'package:asset_management_system/model/volunteer_asset.dart';
import 'package:asset_management_system/pages/qr_nfc_screen.dart';
import 'package:asset_management_system/provider/asset_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/asset_card_builder.dart';
import '../../components/asset_list_skeleton.dart';
import '../../pages/register_device_screen.dart';

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
    this.failedDeviceIds = const <int>{},
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
  final Set<int> failedDeviceIds;

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
            onFilteredCountChanged(combinedCount);
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
                          color: failedDeviceIds.contains(device.id) ? Colors.red.shade50 : Colors.orange.shade50,
                          child: ListTile(
                            title: Text(device.name),
                            subtitle: Text('${device.details}\n(Pending Sync)'),
                            isThreeLine: true,
                            trailing: failedDeviceIds.contains(device.id) ? const Icon(Icons.error, color: Colors.red) : const Icon(Icons.sync_problem, color: Colors.orange),
                            onTap: device.id == null ? null : () => _showRegisteredDeviceDetails(context, device.id!),
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

extension on HomeAssetsListSection {
  Future<void> _showRegisteredDeviceDetails(BuildContext context, int deviceId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final deviceAsync = sheetRef.watch(registeredDeviceProvider(deviceId));

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                child: deviceAsync.when(
                  loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
                  error: (error, _) => SizedBox(height: 220, child: Center(child: Text(error.toString()))),
                  data: (device) {
                    if (device == null) {
                      return const SizedBox(height: 220, child: Center(child: Text('Device not found')));
                    }

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Device Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              ),
                              IconButton(onPressed: () => Navigator.of(sheetContext).pop(), icon: const Icon(Icons.close)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('Record ID', device.id?.toString() ?? '-'),
                          _buildDetailRow('Asset ID', device.astId ?? '-'),
                          _buildDetailRow('Name', device.name),
                          _buildDetailRow('Details', device.details),
                          _buildDetailRow('Address Line', device.addressLine),
                          _buildDetailRow('Status', device.status),
                          _buildDetailRow('Asset Type', device.assetType),
                          _buildDetailRow('Location', device.location),
                          _buildDetailRow('Block', device.block),
                          _buildDetailRow('Amount', device.amount),
                          _buildDetailRow('Purchase Date', device.purchaseDate),
                          _buildDetailRow('Manufacture Date', device.manufactureDate),
                          _buildDetailRow('Warranty End', device.warrantyEnd),
                          _buildDetailRow('Image Path', device.imagePath),
                          _buildDetailRow('Attachment Path', device.assetAttachment),
                          _buildDetailRow('Specification', device.specification),
                          _buildDetailRow('Created At', device.createdAt.toIso8601String()),
                          _buildDetailRow('Synced', device.synced ? 'Yes' : 'No'),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(onPressed: () => Navigator.of(sheetContext).pop(), child: const Text('Close')),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    final displayValue = (value == null || value.trim().isEmpty) ? '-' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          SelectableText(displayValue),
        ],
      ),
    );
  }
}
