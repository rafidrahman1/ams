import 'package:asset_management_system/core/storage/local_database.dart';
import 'package:asset_management_system/data/models/volunteer_asset.dart';
import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/pages/qr_nfc_screen.dart';
import 'package:asset_management_system/providers/asset_provider.dart';
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
    final l10n = AppLocalizations.of(context)!;

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
                            await _confirmAndDeleteDevice(context, ref, device.id!);
                          }
                        },
                        child: Card(
                          color: failedDeviceIds.contains(device.id) ? Colors.red.shade50 : Colors.orange.shade50,
                          child: ListTile(
                            title: Text(device.name),
                            subtitle: Text('${device.details}\n${l10n.pendingSync}'),
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
                          await _confirmAndDeleteAsset(context, ref, apiAsset.astId);
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
                              child: Text(l10n.registerDevice),
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

extension on HomeAssetsListSection {
  Future<void> _confirmAndDeleteDevice(BuildContext context, WidgetRef ref, int deviceId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this device?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(assetRepositoryProvider).deleteRegisteredDevice(deviceId);
      ref.invalidate(unsyncedRegisteredDevicesProvider);
    }
  }

  Future<void> _confirmAndDeleteAsset(BuildContext context, WidgetRef ref, String astId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this asset?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(assetRepositoryProvider).deleteAsset(astId);
      ref.invalidate(adminAssetsProvider);
    }
  }

  Future<void> _showRegisteredDeviceDetails(BuildContext context, int deviceId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final l10n = AppLocalizations.of(context)!;
            final deviceAsync = sheetRef.watch(registeredDeviceProvider(deviceId));

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                child: deviceAsync.when(
                  loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
                  error: (error, _) => SizedBox(height: 220, child: Center(child: Text(error.toString()))),
                  data: (device) {
                    if (device == null) {
                      return SizedBox(height: 220, child: Center(child: Text(l10n.deviceNotFound)));
                    }

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(l10n.deviceDetailsTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              ),
                              IconButton(onPressed: () => Navigator.of(sheetContext).pop(), icon: const Icon(Icons.close)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(l10n.recordIdLabel, device.id?.toString() ?? '-'),
                          _buildDetailRow(l10n.assetIdLabel, device.astId ?? '-'),
                          _buildDetailRow(l10n.nameLabel, device.name),
                          _buildDetailRow(l10n.detailsLabel, device.details),
                          _buildDetailRow(l10n.addressLineLabel, device.addressLine),
                          _buildDetailRow(l10n.statusLabel, device.status),
                          _buildDetailRow(l10n.typeLabel, device.assetType),
                          _buildDetailRow(l10n.locationLabel, device.location),
                          _buildDetailRow(l10n.blockLabel, device.block),
                          _buildDetailRow(l10n.amountLabel, device.amount),
                          _buildDetailRow(l10n.purchaseDateLabel, device.purchaseDate),
                          _buildDetailRow(l10n.manufactureDateLabel, device.manufactureDate),
                          _buildDetailRow(l10n.warrantyEndLabel, device.warrantyEnd),
                          _buildDetailRow(l10n.imagePathLabel, device.imagePath),
                          _buildDetailRow(l10n.attachmentPathLabel, device.assetAttachment),
                          _buildDetailRow(l10n.specificationLabel, device.specification),
                          _buildDetailRow(l10n.createdAtLabel, device.createdAt.toIso8601String()),
                          _buildDetailRow(l10n.syncedLabel, device.synced ? l10n.yesLabel : l10n.noLabel),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(onPressed: () => Navigator.of(sheetContext).pop(), child: Text(l10n.closeLabel)),
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
