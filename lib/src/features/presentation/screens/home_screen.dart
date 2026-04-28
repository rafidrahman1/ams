import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/src/core/storage/local_database.dart';
import 'package:asset_management_system/src/features/presentation/utils/nfc_parser.dart';
import 'package:asset_management_system/src/features/presentation/widgets/language_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import 'home/home_screen_actions.dart';
import 'home/widgets/home_action_buttons_row.dart';
import 'home/widgets/home_assets_filter_card.dart';
import 'home/widgets/home_assets_list_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.isAdmin = false});

  final bool isAdmin;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _pageSize = 10;
  static const double _loadMoreThreshold = 200;
  static const int _skeletonItemCount = 6;

  bool _isSyncing = false;
  int _visibleAssetCount = _pageSize;
  int _lastFilteredAssetCount = 0;
  final ScrollController _assetListScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _assetListScrollController.addListener(_onAssetListScroll);
    _startGlobalNfcSession();
  }

  @override
  void dispose() {
    _assetListScrollController.removeListener(_onAssetListScroll);
    _assetListScrollController.dispose();
    try {
      NfcManager.instance.stopSession();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _startGlobalNfcSession() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) return;

    NfcManager.instance.startSession(
      onDiscovered: (tag) async {
        final scannedValue = await NfcParser.extractTagValue(tag);
        if (scannedValue != null && mounted) {
          final l10n = AppLocalizations.of(context)!;
          HomeScreenActions.openAssetChecklist(context: context, ref: ref, scannedValue: scannedValue, isMounted: () => mounted, mismatchMessage: l10n.nfcTagMismatch);
        }
      },
    );
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

    if (widget.isAdmin) {
      ref.invalidate(adminAssetsProvider);
      ref.invalidate(unsyncedRegisteredDevicesProvider);
      ref.invalidate(adminHomeBootstrapProvider);
      await ref.read(adminHomeBootstrapProvider.future);
      return;
    }

    ref.invalidate(myAssetsProvider);
    ref.invalidate(assetChecklistProvider);
    ref.invalidate(homeBootstrapProvider);

    // Keep refresh indicator active until assets and checklist statuses are ready.
    await ref.read(homeBootstrapProvider.future);
  }

  Future<void> _refreshAdminAssets(BuildContext context) async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      ref.invalidate(adminAssetsProvider);
      ref.invalidate(unsyncedRegisteredDevicesProvider);
      ref.invalidate(adminHomeBootstrapProvider);
      await ref.read(adminHomeBootstrapProvider.future);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin assets refreshed')));
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

  Future<void> _syncRegisteredDevices(BuildContext context) async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final unaycdDevices = await ref.read(assetRepositoryProvider).getUnsyncedRegisteredDevices();

      if (unaycdDevices.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending devices to sync')));
        return;
      }

      int syncedCount = 0;
      int failedCount = 0;

      for (final device in unaycdDevices) {
        try {
          await ref.read(assetRepositoryProvider).syncRegisteredDevice(device.id!);
          syncedCount++;
        } catch (_) {
          failedCount++;
        }
      }

      if (syncedCount > 0) {
        ref.invalidate(unsyncedRegisteredDevicesProvider);
        ref.invalidate(adminAssetsProvider);
      }

      if (!context.mounted) return;

      final message = failedCount > 0
          ? 'Synced $syncedCount of ${unaycdDevices.length} devices. $failedCount failed.'
          : 'Successfully synced ${unaycdDevices.length} device(s)';
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

  Future<void> _syncChecklistToggles(BuildContext context) async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await ref.read(assetRepositoryProvider).syncQueuedResponses();
      ref.invalidate(assetChecklistProvider);
      ref.invalidate(homeBootstrapProvider);
      await ref.read(homeBootstrapProvider.future);

      if (!context.mounted) return;

      final l10n = AppLocalizations.of(context)!;
      final baseMessage = result.totalPending == 0 ? l10n.noPendingChecklistUpdates : l10n.syncedChecklistUpdates(result.synced, result.totalPending);
      final message = result.totalPending > 0 && result.failed > 0 ? '$baseMessage ${l10n.syncFailedSuffix(result.failed)}' : baseMessage;
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

  Future<void> _showLogoutConfirmation() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutConfirmationTitle),
        content: Text(l10n.logoutConfirmationMessage),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.logout)),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(localeProvider);
    final assetsAsync = widget.isAdmin ? ref.watch(adminAssetsProvider) : ref.watch(filteredAssetsProvider);
    final unsyncedDevicesAsync = widget.isAdmin ? ref.watch(unsyncedRegisteredDevicesProvider) : const AsyncValue.data(<RegisteredDeviceData>[]);
    final bootstrapAsync = widget.isAdmin ? ref.watch(adminHomeBootstrapProvider) : ref.watch(homeBootstrapProvider);
    final isBusy = _isSyncing || bootstrapAsync.isLoading;
    final showAllTrueAssets = ref.watch(showAllTrueAssetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          const LanguageToggle(),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(tooltip: l10n.logout, onPressed: isBusy ? null : _showLogoutConfirmation, icon: const Icon(Icons.logout)),
          ),
        ],
      ),
      body: Column(
        children: [
          HomeActionButtonsRow(
            primaryLabel: widget.isAdmin ? 'Register device' : l10n.scan,
            primaryIcon: widget.isAdmin ? Icons.app_registration : Icons.document_scanner,
            secondaryLabel: l10n.sync,
            isSyncing: isBusy,
            onPrimaryPressed: widget.isAdmin
                ? () async {
                    await HomeScreenActions.openRegisterDevice(context: context);
                    if (mounted) {
                      ref.invalidate(unsyncedRegisteredDevicesProvider);
                    }
                  }
                : () => HomeScreenActions.showScanOptions(context: context, ref: ref, isMounted: () => mounted),
            onSecondaryPressed: widget.isAdmin ? () => _syncRegisteredDevices(context) : () => _syncChecklistToggles(context),
          ),
          if (!widget.isAdmin) ...[
            const SizedBox(height: 16),
            HomeAssetsFilterCard(
              assetsLabel: l10n.assets,
              allCheckedLabel: l10n.allChecked,
              showAllTrueAssets: showAllTrueAssets,
              onChanged: isBusy
                  ? null
                  : (value) {
                      ref.read(showAllTrueAssetsProvider.notifier).update(value);
                      setState(() {
                        _visibleAssetCount = _pageSize;
                      });
                      if (_assetListScrollController.hasClients) {
                        _assetListScrollController.jumpTo(0);
                      }
                    },
            ),
          ],
          Expanded(
            child: HomeAssetsListSection(
              assetsLabel: l10n.assets,
              noFullyCheckedAssetsFoundLabel: l10n.noFullyCheckedAssetsFound,
              noPartiallyCheckedAssetsFoundLabel: l10n.noPartiallyCheckedAssetsFound,
              assetsAsync: assetsAsync,
              unsyncedDevicesAsync: unsyncedDevicesAsync,
              forceLoading: bootstrapAsync.isLoading,
              isAdmin: widget.isAdmin,
              showAllTrueAssets: showAllTrueAssets,
              visibleAssetCount: _visibleAssetCount,
              skeletonItemCount: _skeletonItemCount,
              isSyncing: isBusy,
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
    );
  }
}
