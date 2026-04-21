import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/src/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/asset_card_builder.dart';
import '../widgets/square_action_button.dart';
import 'qr_nfc_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final assets = [
      AssetCardData(title: l10n.assetTitle1, description: l10n.assetDescription1),
      AssetCardData(title: l10n.assetTitle2, description: l10n.assetDescription2),
      AssetCardData(title: l10n.assetTitle3, description: l10n.assetDescription3),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              key: const Key('language_toggle_switch_home'),
              onTap: () => ref.read(localeProvider.notifier).toggleLanguage(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 58,
                height: 34,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: ThemeColor.primary.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(999)),
                child: Align(
                  alignment: locale.languageCode == 'bn' ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: ThemeColor.white, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      locale.languageCode == 'bn' ? 'বা' : 'EN',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ThemeColor.primary),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              tooltip: l10n.logout,
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
                label: l10n.scan,
                icon: Icons.document_scanner,
                onPressed: () {},
                backgroundColor: ThemeColor.primary,
                foregroundColor: ThemeColor.backGroundColor,
              ),
              SquareActionButton(
                label: l10n.assets,
                icon: Icons.web_asset,
                onPressed: () {},
                backgroundColor: ThemeColor.primary,
                foregroundColor: ThemeColor.backGroundColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: ThemeColor.primary,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.assets,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ListView(
                children: [
                  ...assets.map(
                    (asset) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: AssetCardBuilder(
                        asset: asset,
                        onSync: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => QrNfcScreen(asset: asset)));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
