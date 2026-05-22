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

enum _ScanOption { qr, rfid }

class HomeScreenActions {
  const HomeScreenActions._();

  static Future<void> openRegisterDevice({required BuildContext context, AssetCardData? asset}) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterDeviceScreen(asset: asset)));
  }

  static Future<void> showScanOptions({required BuildContext context, required WidgetRef ref}) async {
    final selected = await _pickScanOption(context: context, ref: ref);
    if (!context.mounted || selected == null) {
      return;
    }

    await _openChecklistFromScan(context: context, ref: ref, scanLauncher: selected.scanLauncher, mismatchMessage: selected.mismatchMessage);
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

  static Future<({ScanLauncher scanLauncher, String mismatchMessage})?> _pickScanOption({required BuildContext context, required WidgetRef ref}) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showDialog<_ScanOption>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.scanOptionsTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: const Icon(Icons.qr_code), title: Text(l10n.qrCode), onTap: () => Navigator.of(dialogContext).pop(_ScanOption.qr)),
              ListTile(leading: const Icon(Icons.contactless), title: Text(l10n.rfid), onTap: () => Navigator.of(dialogContext).pop(_ScanOption.rfid)),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.cancel))],
        );
      },
    );

    if (choice == null) {
      return null;
    }

    return switch (choice) {
      _ScanOption.qr => (scanLauncher: ref.read(qrScannerLauncherProvider), mismatchMessage: l10n.qrScanMismatch),
      _ScanOption.rfid => (scanLauncher: ref.read(rfidScannerLauncherProvider), mismatchMessage: l10n.rfidScanMismatch),
    };
  }
}
