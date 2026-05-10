import 'package:asset_management_system/src/theme/colors.dart';
import 'package:flutter/material.dart';

class HomeAssetsFilterCard extends StatelessWidget {
  const HomeAssetsFilterCard({super.key, required this.assetsLabel, required this.allCheckedLabel, required this.showAllTrueAssets, required this.onChanged});

  final String assetsLabel;
  final String allCheckedLabel;
  final bool showAllTrueAssets;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ThemeColor.primary,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              assetsLabel,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                Text(allCheckedLabel, style: const TextStyle(color: Colors.white)),
                Switch(
                  value: showAllTrueAssets,
                  onChanged: onChanged,
                  activeThumbColor: ThemeColor.backGroundColor,
                  activeTrackColor: Colors.white54,
                  inactiveThumbColor: ThemeColor.backGroundColor,
                  inactiveTrackColor: Colors.white30,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
