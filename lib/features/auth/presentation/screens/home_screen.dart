import 'package:asset_management_system/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../screens/asset_checklist_screen.dart';
import '../widgets/asset_card_builder.dart';
import '../widgets/square_action_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const assets = [
      AssetCardData(title: 'Asset 1', description: 'Description of Asset 1'),
      AssetCardData(title: 'Asset 2', description: 'Description of Asset 2'),
      AssetCardData(title: 'Asset 3', description: 'Description of Asset 3'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              tooltip: 'Logout',
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SquareActionButton(
                label: 'Scan',
                icon: Icons.document_scanner,
                onPressed: () {},
                backgroundColor: ThemeColor.primary,
                foregroundColor: ThemeColor.backGroundColor,
              ),
              SquareActionButton(label: 'Assets', icon: Icons.web_asset, onPressed: () {}, backgroundColor: ThemeColor.primary, foregroundColor: ThemeColor.backGroundColor),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                ...assets.map(
                  (asset) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: AssetCardBuilder(
                      asset: asset,
                      onSync: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AssetChecklistScreen(asset: asset)));
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
