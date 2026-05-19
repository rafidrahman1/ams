import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/asset_card_builder.dart';
import '../components/square_action_button.dart';
import '../core/utils/ast_id_parser.dart';
import '../pages/asset_checklist_screen.dart';
import '../providers/qr_scanner_provider.dart';

class QrScannerScreen extends ConsumerWidget {
  const QrScannerScreen({super.key, required this.asset});

  final AssetCardData asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    Future<void> openChecklistAfterScan({required Future<String?> Function(BuildContext context) scanLauncher, required String mismatchMessage}) async {
      final scannedValue = await scanLauncher(context);
      final scannedAstId = normalizeAstId(scannedValue);
      final expectedAstId = normalizeAstId(asset.astId);

      if (!context.mounted || scannedAstId == null) return;

      if (scannedAstId == expectedAstId) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AssetChecklistScreen(asset: asset)));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mismatchMessage)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanOptionsTitle)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SquareActionButton(
                label: l10n.qrCode,
                icon: Icons.qr_code,
                size: 132,
                onPressed: () => openChecklistAfterScan(scanLauncher: ref.read(qrScannerLauncherProvider), mismatchMessage: l10n.qrScanMismatch),
                backgroundColor: ThemeColor.primary,
                foregroundColor: ThemeColor.backGroundColor,
              ),
              SquareActionButton(
                label: l10n.rfid,
                icon: Icons.contactless,
                size: 132,
                onPressed: () => openChecklistAfterScan(scanLauncher: ref.read(rfidScannerLauncherProvider), mismatchMessage: l10n.rfidScanMismatch),
                backgroundColor: ThemeColor.primary,
                foregroundColor: ThemeColor.backGroundColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
