import 'package:asset_management_system/components/asset_card_builder.dart';
import 'package:asset_management_system/components/square_action_button.dart';
import 'package:asset_management_system/core/utils/ast_id_parser.dart';
import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/qr_scanner_provider.dart';
import 'asset_create_screen.dart';

class RegisterDeviceScreen extends ConsumerWidget {
  const RegisterDeviceScreen({super.key, this.asset});

  final AssetCardData? asset;

  Future<void> _scanAndRegister({
    required BuildContext context,
    required Future<String?> Function(BuildContext context) scanLauncher,
    required String mismatchMessage,
    required String? Function(String?) normalizeScan,
  }) async {
    final scannedValue = await scanLauncher(context);
    if (!context.mounted || scannedValue == null) {
      return;
    }

    final normalizedScannedAstId = normalizeScan(scannedValue);
    if (normalizedScannedAstId == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidScanData)));
      return;
    }

    if (asset != null) {
      final expectedAstId = normalizeAstId(asset!.astId);
      if (expectedAstId != null && normalizedScannedAstId != expectedAstId) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mismatchMessage)));
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deviceRegisteredFor(asset!.title))));
      Navigator.of(context).pop(normalizedScannedAstId);
    } else {
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => AssetCreateScreen(scannedId: normalizedScannedAstId)),
      );
      if (!context.mounted) return;
      if (created == true) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.registerDevice)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (asset != null) ...[
              Card(
                color: ThemeColor.white,
                child: ListTile(title: Text(asset!.title), subtitle: Text(asset!.description.isNotEmpty ? asset!.description : asset!.astId)),
              ),
              const SizedBox(height: 16),
            ],
            SquareActionButton(
              label: l10n.qrCode,
              icon: Icons.qr_code,
              size: 132,
              onPressed: () => _scanAndRegister(
                context: context,
                scanLauncher: ref.read(qrScannerLauncherProvider),
                mismatchMessage: l10n.qrScanMismatch,
                normalizeScan: normalizeAstId,
              ),
              backgroundColor: ThemeColor.primary,
              foregroundColor: ThemeColor.backGroundColor,
            ),
          ],
        ),
      ),
    );
  }
}
