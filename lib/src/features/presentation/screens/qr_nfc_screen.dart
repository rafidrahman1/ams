import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/src/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/qr_scanner_provider.dart';
import '../widgets/asset_card_builder.dart';
import '../widgets/square_action_button.dart';
import 'asset_checklist_screen.dart';

class QrNfcScreen extends ConsumerWidget {
  const QrNfcScreen({super.key, required this.asset});

  final AssetCardData asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    Future<void> openChecklistAfterQrScan() async {
      final scanLauncher = ref.read(qrScannerLauncherProvider);
      final scannedValue = await scanLauncher(context);
      final scannedAstId = _normalizeAstId(scannedValue);
      final expectedAstId = _normalizeAstId(asset.astId);

      if (!context.mounted || scannedAstId == null) return;

      if (scannedAstId == expectedAstId) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AssetChecklistScreen(asset: asset)));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.qrScanMismatch)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrNfcScannerTitle)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SquareActionButton(
                label: l10n.qrCode,
                icon: Icons.qr_code,
                onPressed: openChecklistAfterQrScan,
                backgroundColor: ThemeColor.primary,
                foregroundColor: ThemeColor.backGroundColor,
              ),
              SquareActionButton(
                label: l10n.nfc,
                icon: Icons.nfc,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please use QR code matching to open the checklist')));
                },
                backgroundColor: ThemeColor.primary,
                foregroundColor: ThemeColor.backGroundColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _normalizeAstId(String? value) {
    if (value == null) return null;

    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final jsonMatch = RegExp(r'"ast_ID"\s*:\s*"([^"]+)"').firstMatch(trimmed);
    if (jsonMatch != null) {
      return jsonMatch.group(1)?.trim();
    }

    return trimmed;
  }
}
