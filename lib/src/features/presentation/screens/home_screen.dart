import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/src/features/presentation/widgets/language_toggle.dart';
import 'package:asset_management_system/src/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/nfc_scanner_provider.dart';
import '../providers/qr_scanner_provider.dart';
import '../utils/ast_id_parser.dart';
import '../widgets/asset_card_builder.dart';
import '../widgets/square_action_button.dart';
import 'asset_checklist_screen.dart';
import 'qr_nfc_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _pageSize = 10;
  static const double _loadMoreThreshold = 200;

  bool _isSyncing = false;
  bool _showAllTrueAssets = false;
  int _visibleAssetCount = _pageSize;
  int _lastFilteredAssetCount = 0;
  final ScrollController _assetListScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _assetListScrollController.addListener(_onAssetListScroll);
  }

  @override
  void dispose() {
    _assetListScrollController.removeListener(_onAssetListScroll);
    _assetListScrollController.dispose();
    super.dispose();
  }

  void _onAssetListScroll() {
    if (!_assetListScrollController.hasClients) {
      return;
    }

    final position = _assetListScrollController.position;
    final reachedLoadMoreThreshold =
        position.maxScrollExtent - position.pixels <= _loadMoreThreshold;

    if (reachedLoadMoreThreshold) {
      _loadMoreAssets();
    }
  }

  void _loadMoreAssets() {
    if (!mounted || _visibleAssetCount >= _lastFilteredAssetCount) {
      return;
    }

    setState(() {
      _visibleAssetCount = (_visibleAssetCount + _pageSize).clamp(
        0,
        _lastFilteredAssetCount,
      );
    });
  }

  void _ensureScrollablePage(bool hasMoreAssets) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !hasMoreAssets ||
          !_assetListScrollController.hasClients) {
        return;
      }

      if (_assetListScrollController.position.maxScrollExtent <= 0) {
        _loadMoreAssets();
      }
    });
  }

  Future<void> _refreshAssets() async {
    if (mounted) {
      setState(() {
        _visibleAssetCount = _pageSize;
      });
    }

    ref.invalidate(myAssetsProvider);
    ref.invalidate(assetChecklistProvider);

    // Await fresh assets so RefreshIndicator completes after data refetch.
    await ref.read(myAssetsProvider.future);
  }

  Future<void> _openChecklistFromScan(
    BuildContext context, {
    required Future<String?> Function(BuildContext context) scanLauncher,
    required String mismatchMessage,
  }) async {
    final scannedValue = await scanLauncher(context);

    if (!mounted) return;

    final scannedAstId = normalizeAstId(scannedValue);
    if (scannedAstId == null) {
      return;
    }

    try {
      final assets = await ref.read(myAssetsProvider.future);

      if (!mounted) return;

      final matchedAssets = assets.where(
        (asset) => normalizeAstId(asset.astId) == scannedAstId,
      );
      final matchedAsset = matchedAssets.isEmpty ? null : matchedAssets.first;

      if (matchedAsset == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mismatchMessage)));
        return;
      }

      final selectedAsset = AssetCardData(
        title: matchedAsset.name,
        description: matchedAsset.details,
        astId: matchedAsset.astId,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AssetChecklistScreen(asset: selectedAsset),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _showScanOptions(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final selectedOption = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: Text(l10n.qrCode),
                onTap: () => Navigator.of(sheetContext).pop('qr'),
              ),
              ListTile(
                leading: const Icon(Icons.nfc),
                title: Text(l10n.nfc),
                onTap: () => Navigator.of(sheetContext).pop('nfc'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedOption == null) {
      return;
    }

    if (selectedOption == 'qr') {
      await _openChecklistFromScan(
        context,
        scanLauncher: ref.read(qrScannerLauncherProvider),
        mismatchMessage: l10n.qrScanMismatch,
      );
      return;
    }

    await _openChecklistFromScan(
      context,
      scanLauncher: ref.read(nfcScannerLauncherProvider),
      mismatchMessage: l10n.nfcTagMismatch,
    );
  }

  Future<void> _syncChecklistToggles(BuildContext context) async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await ref
          .read(assetRepositoryProvider)
          .syncQueuedResponses();
      ref.invalidate(assetChecklistProvider);

      if (!context.mounted) return;

      final message = result.totalPending == 0
          ? 'No pending checklist updates'
          : 'Synced ${result.synced}/${result.totalPending} checklist updates${result.failed > 0 ? ' (${result.failed} failed)' : ''}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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
                    size: 180,
                    label: l10n.scan,
                    icon: Icons.document_scanner,
                    onPressed: _isSyncing
                        ? null
                        : () => _showScanOptions(context),
                    backgroundColor: ThemeColor.primary,
                    foregroundColor: ThemeColor.backGroundColor,
                  ),
                  SquareActionButton(
                    size: 180,
                    label: l10n.assets,
                    icon: Icons.sync,
                    onPressed: _isSyncing
                        ? null
                        : () => _syncChecklistToggles(context),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            'All Checked',
                            style: TextStyle(color: Colors.white),
                          ),
                          Switch(
                            value: _showAllTrueAssets,
                            onChanged: (value) {
                              setState(() {
                                _showAllTrueAssets = value;
                                _visibleAssetCount = _pageSize;
                              });
                              if (_assetListScrollController.hasClients) {
                                _assetListScrollController.jumpTo(0);
                              }
                            },
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
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: assetsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text(error.toString())),
                    data: (assets) {
                      if (assets.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _refreshAssets,
                          child: ListView(
                            controller: _assetListScrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: 240,
                                child: Center(child: Text(l10n.assets)),
                              ),
                            ],
                          ),
                        );
                      }

                      final filteredAssets = assets.where((apiAsset) {
                        final isAllTrueAsync = ref.watch(
                          assetChecklistAllTrueProvider(apiAsset.astId),
                        );
                        return isAllTrueAsync.maybeWhen(
                          data: (isAllTrue) =>
                              _showAllTrueAssets ? isAllTrue : !isAllTrue,
                          orElse: () => false,
                        );
                      }).toList();
                      _lastFilteredAssetCount = filteredAssets.length;

                      final visibleAssets = filteredAssets
                          .take(_visibleAssetCount)
                          .toList(growable: false);
                      final hasMoreAssets =
                          visibleAssets.length < filteredAssets.length;
                      _ensureScrollablePage(hasMoreAssets);

                      final hasLoadingStatuses = assets.any(
                        (apiAsset) => ref
                            .watch(
                              assetChecklistAllTrueProvider(apiAsset.astId),
                            )
                            .isLoading,
                      );

                      if (filteredAssets.isEmpty && hasLoadingStatuses) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (filteredAssets.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _refreshAssets,
                          child: ListView(
                            controller: _assetListScrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: 240,
                                child: Center(
                                  child: Text(
                                    _showAllTrueAssets
                                        ? 'No fully checked assets found'
                                        : 'No partially checked assets found',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _refreshAssets,
                        child: ListView(
                          controller: _assetListScrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            ...visibleAssets.map((apiAsset) {
                              final asset = AssetCardData(
                                title: apiAsset.name,
                                description: apiAsset.details,
                                astId: apiAsset.astId,
                              );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: AssetCardBuilder(
                                  asset: asset,
                                  onSync: _isSyncing
                                      ? null
                                      : () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  QrNfcScreen(asset: asset),
                                            ),
                                          );
                                        },
                                ),
                              );
                            }),
                            if (hasMoreAssets)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
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
