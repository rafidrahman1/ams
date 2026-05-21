import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/asset_card_builder.dart';
import '../../core/utils/ast_id_parser.dart';
import '../../core/utils/network_error_utils.dart';
import '../../pages/asset_checklist_screen.dart';
import '../../pages/register_device_screen.dart';
import '../../providers/asset_provider.dart';
import '../../providers/qr_scanner_provider.dart';

typedef ScanLauncher = Future<String?> Function(BuildContext context);

class HomeScreenActions {
  const HomeScreenActions._();

  static Future<void> openRegisterDevice({required BuildContext context, AssetCardData? asset}) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterDeviceScreen(asset: asset)));
  }

  static Future<void> showScanOptions({required BuildContext context, required WidgetRef ref}) async {
    final l10n = AppLocalizations.of(context)!;
    await _openChecklistFromScan(
      context: context,
      ref: ref,
      scanLauncher: ref.read(qrScannerLauncherProvider),
      mismatchMessage: l10n.qrScanMismatch,
    );
  }

  /// Opens the QR/hardware scanner and navigates to the checklist when the scan matches [asset].
  static Future<void> scanAndOpenAssetChecklist({required BuildContext context, required WidgetRef ref, required AssetCardData asset}) async {
    final l10n = AppLocalizations.of(context)!;
    final scannedValue = await ref.read(qrScannerLauncherProvider)(context);
    final scannedAstId = normalizeAstId(scannedValue);
    final expectedAstId = normalizeAstId(asset.astId);

    if (!context.mounted || scannedAstId == null) {
      return;
    }

    if (scannedAstId == expectedAstId) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AssetChecklistScreen(asset: asset)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.qrScanMismatch)));
  }

  static Future<void> openAssetChecklist({required BuildContext context, required WidgetRef ref, required String scannedValue, required String mismatchMessage}) async {
    final scannedAstId = normalizeAstId(scannedValue);
    if (scannedAstId == null) {
      return;
    }

    try {
      final assetsAsync = ref.watch(myAssetsProvider);

      final assets = await assetsAsync.maybeWhen(data: (data) => Future.value(data), orElse: () => ref.read(myAssetsProvider.future));

      if (!context.mounted) {
        return;
      }

      final matchedAssets = assets.where((asset) => normalizeAstId(asset.astId) == scannedAstId);
      final matchedAsset = matchedAssets.isEmpty ? null : matchedAssets.first;

      if (matchedAsset == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mismatchMessage)));
        return;
      }

      final selectedAsset = AssetCardData(title: matchedAsset.name, description: matchedAsset.details, astId: matchedAsset.astId);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AssetChecklistScreen(asset: selectedAsset)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(offlineAwareErrorMessage(l10n.noInternetConnection, error))));
    }
  }

  static Future<void> _openChecklistFromScan({
    required BuildContext context,
    required WidgetRef ref,
    required Future<String?> Function(BuildContext context) scanLauncher,
    required String mismatchMessage,
  }) async {
    final scannedValue = await scanLauncher(context);

    if (!context.mounted || scannedValue == null) {
      return;
    }

    await openAssetChecklist(context: context, ref: ref, scannedValue: scannedValue, mismatchMessage: mismatchMessage);
  }
}
