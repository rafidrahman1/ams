import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/src/features/presentation/widgets/language_toggle.dart';
import 'package:asset_management_system/src/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/asset_card_builder.dart';
import '../widgets/square_action_button.dart';
import 'qr_nfc_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSyncing = false;

  Future<void> _syncChecklistToggles(BuildContext context) async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await ref.read(assetRepositoryProvider).syncQueuedResponses();
      ref.invalidate(assetChecklistProvider);

      if (!context.mounted) return;

      final message = result.totalPending == 0
          ? 'No pending checklist updates'
          : 'Synced ${result.synced}/${result.totalPending} checklist updates${result.failed > 0 ? ' (${result.failed} failed)' : ''}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(localeProvider);
    final assetsAsync = ref.watch(myAssetsProvider);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(l10n.homeTitle),
            actions: [
              const LanguageToggle(),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  tooltip: l10n.logout,
                  onPressed: _isSyncing
                      ? null
                      : () async {
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
                    onPressed: _isSyncing ? null : () {},
                    backgroundColor: ThemeColor.primary,
                    foregroundColor: ThemeColor.backGroundColor,
                  ),
                  SquareActionButton(
                    label: l10n.assets,
                    icon: Icons.sync,
                    onPressed: _isSyncing ? null : () => _syncChecklistToggles(context),
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
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: assetsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text(error.toString())),
                    data: (assets) {
                      if (assets.isEmpty) {
                        return Center(child: Text(l10n.assets));
                      }

                      return ListView(
                        children: [
                          ...assets.map((apiAsset) {
                            final asset = AssetCardData(title: apiAsset.name, description: apiAsset.details, astId: apiAsset.astId);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: AssetCardBuilder(
                                asset: asset,
                                onSync: _isSyncing
                                    ? null
                                    : () {
                                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => QrNfcScreen(asset: asset)));
                                      },
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isSyncing) ...[
          const ModalBarrier(dismissible: false, color: Colors.black54),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}
