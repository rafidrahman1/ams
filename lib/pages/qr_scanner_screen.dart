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

    Future<void> openChecklistAfterScan() async {
      final scannedValue = await ref.read(qrScannerLauncherProvider)(context);
      final scannedAstId = normalizeAstId(scannedValue);
      final expectedAstId = normalizeAstId(asset.astId);

      if (!context.mounted || scannedAstId == null) return;

      if (scannedAstId == expectedAstId) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AssetChecklistScreen(asset: asset)));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.qrScanMismatch)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrScannerTitle)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SquareActionButton(
            label: l10n.qrCode,
            icon: Icons.qr_code,
            size: 132,
            onPressed: openChecklistAfterScan,
            backgroundColor: ThemeColor.primary,
            foregroundColor: ThemeColor.backGroundColor,
          ),
        ],
      ),
    );
  }
}
