import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/src/features/presentation/widgets/language_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import 'home/home_screen_actions.dart';
import 'home/widgets/home_action_buttons_row.dart';
import 'home/widgets/home_assets_filter_card.dart';
import 'home/widgets/home_assets_list_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _pageSize = 10;
  static const double _loadMoreThreshold = 200;
  static const int _skeletonItemCount = 6;

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
    final reachedLoadMoreThreshold = position.maxScrollExtent - position.pixels <= _loadMoreThreshold;

    if (reachedLoadMoreThreshold) {
      _loadMoreAssets();
    }
  }

  void _loadMoreAssets() {
    if (!mounted || _visibleAssetCount >= _lastFilteredAssetCount) {
      return;
    }

    setState(() {
      _visibleAssetCount = (_visibleAssetCount + _pageSize).clamp(0, _lastFilteredAssetCount);
    });
  }

  void _ensureScrollablePage(bool hasMoreAssets) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !hasMoreAssets || !_assetListScrollController.hasClients) {
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
              HomeActionButtonsRow(
                scanLabel: l10n.scan,
                assetsLabel: l10n.assets,
                isSyncing: _isSyncing,
                onScanPressed: () => HomeScreenActions.showScanOptions(context: context, ref: ref, isMounted: () => mounted),
                onSyncPressed: () => _syncChecklistToggles(context),
              ),
              const SizedBox(height: 16),
              HomeAssetsFilterCard(
                assetsLabel: l10n.assets,
                allCheckedLabel: 'All Checked',
                showAllTrueAssets: _showAllTrueAssets,
                onChanged: (value) {
                  setState(() {
                    _showAllTrueAssets = value;
                    _visibleAssetCount = _pageSize;
                  });
                  if (_assetListScrollController.hasClients) {
                    _assetListScrollController.jumpTo(0);
                  }
                },
              ),
              Expanded(
                child: HomeAssetsListSection(
                  assetsLabel: l10n.assets,
                  assetsAsync: assetsAsync,
                  showAllTrueAssets: _showAllTrueAssets,
                  visibleAssetCount: _visibleAssetCount,
                  skeletonItemCount: _skeletonItemCount,
                  isSyncing: _isSyncing,
                  scrollController: _assetListScrollController,
                  onRefresh: _refreshAssets,
                  onFilteredCountChanged: (count) {
                    _lastFilteredAssetCount = count;
                  },
                  ensureScrollablePage: _ensureScrollablePage,
                ),
              ),
            ],
          ),
        ),
        if (_isSyncing) ...[const ModalBarrier(dismissible: false, color: Colors.black54), const Center(child: CircularProgressIndicator())],
      ],
    );
  }
}
