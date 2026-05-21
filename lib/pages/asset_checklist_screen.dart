import 'dart:io';

import 'package:asset_management_system/components/asset_checklist/asset_checklist_components.dart';
import 'package:asset_management_system/core/utils/network_error_utils.dart';
import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../components/asset_card_builder.dart';
import '../../data/models/asset_checklist_item.dart';
import '../../providers/asset_provider.dart';

class AssetChecklistScreen extends ConsumerStatefulWidget {
  const AssetChecklistScreen({super.key, required this.asset});

  final AssetCardData asset;

  @override
  ConsumerState<AssetChecklistScreen> createState() => _AssetChecklistScreenState();
}

class _AssetChecklistScreenState extends ConsumerState<AssetChecklistScreen> {
  List<bool> _completed = const [];
  String? _loadedAstId;
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _parameterController = TextEditingController();
  String _status = 'ACTIVE';
  String _imagePath = '';

  @override
  void dispose() {
    _remarksController.dispose();
    _parameterController.dispose();
    super.dispose();
  }

  List<bool> _effectiveCompleted(List<AssetChecklistItem> items) {
    if (_completed.length == items.length) {
      return List<bool>.from(_completed);
    }
    return items.map((item) => item.response).toList(growable: false);
  }

  void _toggleCompleted(List<AssetChecklistItem> items, int index, bool value) {
    setState(() {
      if (_completed.length != items.length) {
        _completed = _effectiveCompleted(items);
      }
      _completed[index] = value;
    });
  }

  Future<void> _saveChecklist(List<AssetChecklistItem> items) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final completed = _effectiveCompleted(items);
      final submitItems = <({int featureId, bool response})>[];
      for (var index = 0; index < items.length; index++) {
        submitItems.add((featureId: items[index].featureId, response: completed[index]));
      }

      // Submit when online; repository queues automatically when offline.
      await ref.read(assetRepositoryProvider).submitChecklist(
            astId: widget.asset.astId,
            status: _status,
            remark: _remarksController.text.trim(),
            parameter: _parameterController.text.trim(),
            image: '',
            imagePath: _imagePath,
            items: submitItems,
          );

      ref.invalidate(assetChecklistProvider(widget.asset.astId));
      ref.invalidate(assetChecklistAllTrueProvider(widget.asset.astId));
      ref.invalidate(assetAllTrueStatesProvider);

      if (!mounted) return;
      navigator.pop(completed);
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      messenger.showSnackBar(SnackBar(content: Text(offlineAwareErrorMessage(l10n.noInternetConnection, error))));
    }
  }

  void _syncState(String astId, AssetChecklist data) {
    if (_loadedAstId == astId) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _loadedAstId = astId;
        _completed = data.items.map((item) => item.response).toList();
        _status = data.status;
        _remarksController.text = data.remark;
        _parameterController.text = data.parameter;
        _imagePath = data.image;
      });
    });
  }

  Future<void> _captureImageFromCamera() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (picked == null) return;

      final cachedPath = await _resolveCachedCameraImagePath(picked);

      if (!mounted) return;
      setState(() {
        _imagePath = cachedPath;
      });
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorCapturingImage(offlineAwareErrorMessage(l10n.noInternetConnection, error)))));
    }
  }

  Future<void> _pickImageFromGallery() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      final cachedPath = await _resolveCachedCameraImagePath(picked);

      if (!mounted) return;
      setState(() {
        _imagePath = cachedPath;
      });
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorPickingImage(offlineAwareErrorMessage(l10n.noInternetConnection, error)))));
    }
  }

  Future<String> _resolveCachedCameraImagePath(XFile picked) async {
    final originalPath = picked.path;
    if (originalPath.trim().isNotEmpty) {
      try {
        if (await File(originalPath).exists()) {
          return originalPath;
        }
      } catch (_) {
        // Fall through to bytes caching.
      }
    }

    final bytes = await picked.readAsBytes();
    final safeName = picked.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final tempDir = await Directory.systemTemp.createTemp('checklist_upload_cache_image');
    final outPath = '${tempDir.path}/image-$safeName';
    final outFile = File(outPath);
    await outFile.writeAsBytes(bytes, flush: true);
    return outPath;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final checklistAsync = ref.watch(assetChecklistProvider(widget.asset.astId));
    final saveButtonPressed = checklistAsync.maybeWhen(
      data: (data) =>
          () => _saveChecklist(data.items),
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checklistForAsset(widget.asset.title), style: const TextStyle(color: Colors.white)),
        backgroundColor: ThemeColor.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: saveButtonPressed,
        backgroundColor: ThemeColor.primary,
        foregroundColor: ThemeColor.backGroundColor,
        icon: const Icon(Icons.save),
        label: Text(l10n.save),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: checklistAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(offlineAwareErrorMessage(l10n.noInternetConnection, error))),
          data: (data) {
            _syncState(widget.asset.astId, data);
            final items = data.items;

            if (items.isEmpty) {
              return Center(child: Text(l10n.noChecklistItemsFound));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AssetChecklistHeader(title: widget.asset.title, description: widget.asset.description, assetId: widget.asset.astId),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 96, top: 10),
                    children: [
                      AssetChecklistStatusDropdown(
                        value: _status,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _status = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      AssetChecklistItemsList(items: items, completed: _effectiveCompleted(items), onChanged: (index, value) => _toggleCompleted(items, index, value)),
                      const SizedBox(height: 16),
                      AssetChecklistFieldGroup(parameterController: _parameterController, remarksController: _remarksController),
                      const SizedBox(height: 16),
                      AssetChecklistImageSection(
                        imagePath: _imagePath,
                        onCameraPressed: _captureImageFromCamera,
                        onGalleryPressed: _pickImageFromGallery,
                        onRemovePressed: () => setState(() => _imagePath = ''),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
