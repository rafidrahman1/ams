import 'package:asset_management_system/src/theme/colors.dart';
import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../widgets/asset_card_builder.dart';
import '../widgets/square_action_button.dart';
import 'asset_checklist_screen.dart';

class QrNfcScreen extends StatelessWidget {
  const QrNfcScreen({super.key, required this.asset});

  final AssetCardData asset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AssetChecklistScreen(asset: asset)));
                },
                backgroundColor: ThemeColor.primary,
                foregroundColor: ThemeColor.backGroundColor,
              ),
              SquareActionButton(
                label: l10n.nfc,
                icon: Icons.nfc,
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AssetChecklistScreen(asset: asset)));
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
}
