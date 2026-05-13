import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/asset_card_builder.dart';
import '../components/square_action_button.dart';
import '../core/utils/ast_id_parser.dart';
import '../pages/asset_checklist_screen.dart';
import '../providers/qr_scanner_provider.dart';

class QrNfcScreen extends ConsumerWidget {
  const QrNfcScreen({super.key, required this.asset});

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
      appBar: AppBar(title: Text(l10n.qrNfcScannerTitle)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 16),
              SquareActionButton(
                label: l10n.qrCode,
                icon: Icons.qr_code,
                onPressed: () => openChecklistAfterScan(scanLauncher: ref.read(qrScannerLauncherProvider), mismatchMessage: l10n.qrScanMismatch),
                backgroundColor: ThemeColor.primary,
                foregroundColor: ThemeColor.backGroundColor,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }
}
