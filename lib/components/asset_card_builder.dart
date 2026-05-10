import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/theme/border_radius.dart';
import 'package:asset_management_system/theme/colors.dart';
import 'package:flutter/material.dart';

class AssetCardData {
  const AssetCardData({required this.title, required this.description, required this.astId});

  final String title;
  final String description;
  final String astId;
}

class AssetCardBuilder extends StatelessWidget {
  const AssetCardBuilder({super.key, required this.asset, this.onSync});

  final AssetCardData asset;
  final VoidCallback? onSync;

  String _truncateDescription(String value, {int maxWords = 8}) {
    final words = value.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList(growable: false);
    if (words.length <= maxWords) {
      return value.trim();
    }

    return '${words.take(maxWords).join(' ')}...';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      color: ThemeColor.white,
      shape: RoundedRectangleBorder(borderRadius: ThemeBorderRadius.r4),
      child: ListTile(
        title: Text(asset.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [if (asset.description.isNotEmpty) Text(_truncateDescription(asset.description))],
        ),
        trailing: ElevatedButton(onPressed: onSync, child: Text(l10n.checkList)),
      ),
    );
  }
}
