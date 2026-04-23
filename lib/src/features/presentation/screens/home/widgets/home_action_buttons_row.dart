import 'package:asset_management_system/src/features/presentation/widgets/square_action_button.dart';
import 'package:asset_management_system/src/theme/colors.dart';
import 'package:flutter/material.dart';

class HomeActionButtonsRow extends StatelessWidget {
  const HomeActionButtonsRow({
    super.key,
    required this.scanLabel,
    required this.assetsLabel,
    required this.isSyncing,
    required this.onScanPressed,
    required this.onSyncPressed,
  });

  final String scanLabel;
  final String assetsLabel;
  final bool isSyncing;
  final VoidCallback onScanPressed;
  final VoidCallback onSyncPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SquareActionButton(
          size: 180,
          label: scanLabel,
          icon: Icons.document_scanner,
          onPressed: isSyncing ? null : onScanPressed,
          backgroundColor: ThemeColor.primary,
          foregroundColor: ThemeColor.backGroundColor,
        ),
        SquareActionButton(
          size: 180,
          label: assetsLabel,
          icon: Icons.sync,
          onPressed: isSyncing ? null : onSyncPressed,
          backgroundColor: ThemeColor.primary,
          foregroundColor: ThemeColor.backGroundColor,
        ),
      ],
    );
  }
}
