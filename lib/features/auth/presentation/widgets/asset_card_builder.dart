import 'package:flutter/material.dart';

import '../../../../theme/border_radius.dart';
import '../../../../theme/colors.dart';

class AssetCardData {
  const AssetCardData({required this.title, required this.description});

  final String title;
  final String description;
}

class AssetCardBuilder extends StatelessWidget {
  const AssetCardBuilder({super.key, required this.asset, this.onSync});

  final AssetCardData asset;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ThemeColor.white,
      shape: RoundedRectangleBorder(borderRadius: ThemeBorderRadius.r4),
      child: ListTile(
        title: Text(asset.title),
        subtitle: Text(asset.description),
        trailing: ElevatedButton(onPressed: onSync, child: const Text('Check List')),
      ),
    );
  }
}
