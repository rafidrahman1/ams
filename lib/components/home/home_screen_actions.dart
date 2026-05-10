import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/asset_card_builder.dart';
import '../../core/utils/ast_id_parser.dart';
import '../../pages/asset_checklist_screen.dart';
import '../../pages/register_device_screen.dart';
import '../../providers/asset_provider.dart';
import '../../providers/nfc_scanner_provider.dart';
import '../../providers/qr_scanner_provider.dart';

class HomeScreenActions {
  const HomeScreenActions._();

  static Future<void> openRegisterDevice({required BuildContext context, AssetCardData? asset}) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterDeviceScreen(asset: asset)));
  }

  static Future<void> showScanOptions({required BuildContext context, required WidgetRef ref}) async {
    final l10n = AppLocalizations.of(context)!;
    final selectedOption = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: const Icon(Icons.qr_code), title: Text(l10n.qrCode), onTap: () => Navigator.of(sheetContext).pop('qr')),
              ListTile(leading: const Icon(Icons.nfc), title: Text(l10n.nfc), onTap: () => Navigator.of(sheetContext).pop('nfc')),
            ],
          ),
        );
      },
    );

    if (!context.mounted || selectedOption == null) {
      return;
    }

    if (selectedOption == 'qr') {
      await _openChecklistFromScan(context: context, ref: ref, scanLauncher: ref.read(qrScannerLauncherProvider), mismatchMessage: l10n.qrScanMismatch);
      return;
    }

    await _openChecklistFromScan(context: context, ref: ref, scanLauncher: ref.read(nfcScannerLauncherProvider), mismatchMessage: l10n.nfcTagMismatch);
  }

  static Future<void> openAssetChecklist({required BuildContext context, required WidgetRef ref, required String scannedValue, required String mismatchMessage}) async {
    final scannedAstId = normalizeAstId(scannedValue);
    if (scannedAstId == null) {
      return;
    }

    try {
      final assets = await ref.read(myAssetsProvider.future);

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
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
