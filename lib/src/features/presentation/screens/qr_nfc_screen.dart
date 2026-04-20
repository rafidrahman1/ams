import 'package:asset_management_system/src/theme/colors.dart';
import 'package:flutter/material.dart';

import '../widgets/asset_card_builder.dart';
import '../widgets/square_action_button.dart';
import 'asset_checklist_screen.dart';

class QrNfcScreen extends StatelessWidget {
  const QrNfcScreen({super.key, required this.asset});

  final AssetCardData asset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR/NFC Scanner')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SquareActionButton(
                label: 'QR Code',
                icon: Icons.qr_code,
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AssetChecklistScreen(asset: asset)));
                },
                backgroundColor: ThemeColor.primary,
                foregroundColor: ThemeColor.backGroundColor,
              ),
              SquareActionButton(
                label: 'NFC',
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

