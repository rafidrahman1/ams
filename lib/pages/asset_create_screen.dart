import 'dart:convert';
import 'dart:io';

import 'package:asset_management_system/components/asset_create/asset_create_components.dart';
import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/theme/colors.dart';
import 'package:asset_management_system/theme/gap.dart';
import 'package:asset_management_system/theme/padding.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/utils/ast_id_parser.dart';
import '../data/models/location_models.dart';
import '../providers/asset_provider.dart';

class AssetCreateScreen extends ConsumerStatefulWidget {
  final String? scannedId;

  const AssetCreateScreen({super.key, this.scannedId});

  @override
  ConsumerState<AssetCreateScreen> createState() => _AssetCreateScreenState();
}

class _AssetCreateScreenState extends ConsumerState<AssetCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _astIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _assetDetailsController = TextEditingController();

  String _selectedStatus = 'ACTIVE';
  String? _selectedType;
  String? _selectedCamp;
  String? _selectedBlock;

  bool _isSubmitting = false;
  String? _selectedImagePath;
  String? _selectedImageName;
  String? _selectedAttachmentPath;
  String? _selectedAttachmentName;
  static const List<String> _statusOptions = ['ACTIVE', 'UNDER MAINTENANCE', 'APPROVAL PENDING', 'INACTIVE'];

  DateTime? _purchaseDate;
  DateTime? _manufactureDate;
  DateTime? _warrantyEndDate;

  final List<Map<String, TextEditingController>> _items = [];

  static const _defaultDatePickerStartYear = 2000;
  static const _defaultDatePickerEndYear = 2101;

  @override
  void initState() {
    super.initState();
    _astIdController.text = normalizeAstId(widget.scannedId) ?? (widget.scannedId ?? '');
    _addItem();
  }

  void _addItem() {
    setState(() {
      _items.add({'item': TextEditingController(), 'description': TextEditingController()});
    });
  }

  void _removeItem(int index) {
    setState(() {
      if (_items.length > 1) {
        final removed = _items.removeAt(index);
        removed['item']?.dispose();
        removed['description']?.dispose();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _astIdController.dispose();
    _amountController.dispose();
    _addressLineController.dispose();
    _assetDetailsController.dispose();
    for (final entry in _items) {
      entry['item']?.dispose();
      entry['description']?.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required Function(DateTime) onDateSelected}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(_defaultDatePickerStartYear),
      lastDate: DateTime(_defaultDatePickerEndYear),
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 600), child: child),
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _submitForm() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final name = _nameController.text.trim();
    final astId = normalizeAstId(_astIdController.text);
    final address = _addressLineController.text.trim();
    final details = _assetDetailsController.text.trim();

    if (astId == null || astId.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.assetIdRequired)));
      return;
    }

    _astIdController.text = astId;

    if (name.isEmpty || address.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.nameAndAddressRequired)));
      return;
    }

    if ((_selectedType ?? '').isEmpty || (_selectedCamp ?? '').isEmpty || (_selectedBlock ?? '').isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.typeCampBlockRequired), duration: const Duration(seconds: 3)));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final specifications = _items
          .asMap()
          .entries
          .map((entry) {
            final itemName = entry.value['item']!.text.trim();
            final itemDesc = entry.value['description']!.text.trim();
            if (itemName.isEmpty) return null;
            return <String, dynamic>{'id': entry.key + 1, 'name': itemName, 'description': itemDesc};
          })
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      await ref
          .read(assetRepositoryProvider)
          .saveRegisteredDeviceLocally(
            name: name,
            details: details,
            addressLine: address,
            astId: astId,
            status: _selectedStatus,
            assetType: _selectedType,
            location: _selectedCamp,
            block: _selectedBlock,
            imagePath: _selectedImagePath,
            amount: _amountController.text.trim(),
            purchaseDate: _formatDateForApi(_purchaseDate),
            manufactureDate: _formatDateForApi(_manufactureDate),
            warrantyEnd: _formatDateForApi(_warrantyEndDate),
            specification: specifications.isNotEmpty ? jsonEncode(specifications) : null,
            assetAttachment: _selectedAttachmentPath,
          );

      if (!mounted) return;

      messenger.showSnackBar(SnackBar(content: Text(l10n.assetSavedLocally)));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      messenger.showSnackBar(SnackBar(content: Text(l10n.errorPrefix(error.toString()))));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickFile({required bool isImage}) async {
    final result = await FilePicker.pickFiles(type: isImage ? FileType.image : FileType.any, withData: true);
    if (result != null && result.files.isNotEmpty) {
      final picked = result.files.first;
      final cachedPath = await _resolveCachedUploadPath(picked, prefix: isImage ? 'image' : 'asset_attachment');
      if (!mounted) return;
      setState(() {
        if (isImage) {
          _selectedImagePath = cachedPath;
          _selectedImageName = picked.name;
        } else {
          _selectedAttachmentPath = cachedPath;
          _selectedAttachmentName = picked.name;
        }
      });
    }
  }

  Future<void> _captureImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);

      if (photo != null && mounted) {
        setState(() {
          _selectedImagePath = photo.path;
          _selectedImageName = photo.name;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorCapturingImage(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final campLocationsAsync = ref.watch(campLocationsProvider);
    final assetTypesAsync = ref.watch(assetTypesProvider);

    final blocksAsync = _selectedCamp == null || _selectedCamp!.isEmpty
        ? const AsyncValue<List<IdNamePair>>.data(<IdNamePair>[])
        : ref.watch(blocksProvider(int.parse(_selectedCamp!)));

    return Scaffold(
      backgroundColor: ThemeColor.backGroundColor,
      appBar: AppBar(title: Text(l10n.assetCreateTitle), backgroundColor: ThemeColor.white, foregroundColor: ThemeColor.black, elevation: 0),
      body: SingleChildScrollView(
        padding: ThemePadding.p4,
        child: Container(
          padding: ThemePadding.p4,
          decoration: BoxDecoration(color: ThemeColor.white, borderRadius: BorderRadius.circular(8)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AssetCreateNoticeBanner(noticeText: l10n.assetCreateNotice, importantNoticeText: l10n.assetCreateImportantNotice),
                Gap.y4,
                AssetCreateResponsiveRow(
                  children: [
                    AssetCreateFieldSection(
                      label: l10n.assetIdLabel,
                      child: AssetCreateInputField(controller: _astIdController, hintText: l10n.assetIdHint, readOnly: true),
                    ),
                    AssetCreateFieldSection(
                      label: l10n.nameLabel,
                      child: AssetCreateInputField(controller: _nameController, hintText: l10n.nameHint),
                    ),
                  ],
                ),
                Gap.y4,
                AssetCreateResponsiveRow(
                  children: [
                    AssetCreateFieldSection(
                      label: l10n.typeLabel,
                      child: assetTypesAsync.when(
                        data: (items) => AssetCreateDropdownField(
                          value: items.any((i) => i.id.toString() == _selectedType) ? _selectedType : null,
                          items: items
                              .map(
                                (i) => DropdownMenuItem(
                                  value: i.id.toString(),
                                  child: Text(i.name, style: Theme.of(context).textTheme.bodyMedium),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (v) => setState(() => _selectedType = v),
                        ),
                        loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                        error: (err, stack) => Text(l10n.errorLoadingTypes(err.toString()), style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ),
                    AssetCreateFieldSection(
                      label: l10n.amountLabel,
                      child: AssetCreateInputField(
                        controller: _amountController,
                        hintText: l10n.amountHint,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
                Gap.y4,
                AssetCreateResponsiveRow(
                  children: [
                    AssetCreateFieldSection(
                      label: l10n.statusLabel,
                      child: AssetCreateDropdownField(
                        value: _selectedStatus,
                        items: _statusOptions
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(_statusLabel(l10n, e), style: Theme.of(context).textTheme.bodyMedium),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _isSubmitting ? null : (v) => setState(() => _selectedStatus = v ?? 'ACTIVE'),
                      ),
                    ),
                    AssetCreateFieldSection(
                      label: l10n.campLabel,
                      child: campLocationsAsync.when(
                        data: (items) => AssetCreateDropdownField(
                          value: items.any((i) => i.id.toString() == _selectedCamp) ? _selectedCamp : null,
                          items: items
                              .map(
                                (i) => DropdownMenuItem(
                                  value: i.id.toString(),
                                  child: Text(i.name, style: Theme.of(context).textTheme.bodyMedium),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (v) => setState(() {
                            _selectedCamp = v;
                            _selectedBlock = null;
                          }),
                        ),
                        loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                        error: (err, stack) => Text(l10n.errorLoadingCamps),
                      ),
                    ),
                  ],
                ),
                Gap.y4,
                AssetCreateResponsiveRow(
                  children: [
                    AssetCreateFieldSection(
                      label: l10n.blockLabel,
                      child: blocksAsync.when(
                        data: (List<IdNamePair> items) {
                          if (items.isEmpty) {
                            return Text(l10n.noBlocksAvailableForCamp, style: const TextStyle(color: Colors.orange));
                          }
                          return AssetCreateDropdownField(
                            value: items.any((i) => i.id.toString() == _selectedBlock) ? _selectedBlock : null,
                            items: items
                                .map(
                                  (i) => DropdownMenuItem(
                                    value: i.id.toString(),
                                    child: Text(i.name, style: Theme.of(context).textTheme.bodyMedium),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (v) => setState(() => _selectedBlock = v),
                          );
                        },
                        loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                        error: (err, stack) => Text(l10n.errorLoadingBlocks(err.toString()), style: const TextStyle(color: Colors.red, fontSize: 11)),
                      ),
                    ),
                    AssetCreateFieldSection(
                      label: l10n.addressLineLabel,
                      child: AssetCreateInputField(controller: _addressLineController, hintText: l10n.addressLineHint),
                    ),
                  ],
                ),
                Gap.y4,
                AssetCreateResponsiveRow(
                  children: [
                    AssetCreateFieldSection(
                      label: l10n.purchaseDateLabel,
                      child: AssetCreateDateField(
                        date: _purchaseDate,
                        placeholderText: 'Select a date',
                        onTap: () => _selectDate(context, onDateSelected: (d) => setState(() => _purchaseDate = d)),
                      ),
                    ),
                    AssetCreateFieldSection(
                      label: l10n.manufactureDateLabel,
                      child: AssetCreateDateField(
                        date: _manufactureDate,
                        placeholderText: 'Select a date',
                        onTap: () => _selectDate(context, onDateSelected: (d) => setState(() => _manufactureDate = d)),
                      ),
                    ),
                  ],
                ),
                Gap.y4,
                AssetCreateResponsiveRow(
                  children: [
                    AssetCreateFieldSection(
                      label: l10n.warrantyEndLabel,
                      child: AssetCreateDateField(
                        date: _warrantyEndDate,
                        placeholderText: 'Select a date',
                        onTap: () => _selectDate(context, onDateSelected: (d) => setState(() => _warrantyEndDate = d)),
                      ),
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
                Gap.y8,
                AssetCreateItemsSection(
                  items: _items,
                  itemsHeading: l10n.itemsHeading,
                  itemColumnLabel: l10n.itemColumn,
                  descriptionColumnLabel: l10n.descriptionColumn,
                  actionColumnLabel: l10n.actionColumn,
                  enterItemHint: l10n.enterItemHint,
                  enterDescriptionHint: l10n.enterDescriptionHint,
                  deleteItemLabel: l10n.deleteItem,
                  addItemLabel: l10n.addItem,
                  onAddItem: _addItem,
                  onRemoveItem: _removeItem,
                ),
                Gap.y8,
                AssetCreateFieldSection(
                  label: l10n.assetPhotoLabel,
                  child: AssetCreateFilePickerField(
                    isImage: true,
                    isSubmitting: _isSubmitting,
                    selectedName: _selectedImageName,
                    chooseLabel: l10n.chooseImage,
                    takePhotoLabel: l10n.takePhoto,
                    removeLabel: l10n.remove,
                    noneSelectedLabel: l10n.noImageChosen,
                    onChoosePressed: () => _pickFile(isImage: true),
                    onTakePhotoPressed: _captureImageFromCamera,
                    onRemovePressed: () => setState(() {
                      _selectedImagePath = null;
                      _selectedImageName = null;
                    }),
                  ),
                ),
                Gap.y4,
                AssetCreateFieldSection(
                  label: l10n.assetAttachmentLabel,
                  child: AssetCreateFilePickerField(
                    isImage: false,
                    isSubmitting: _isSubmitting,
                    selectedName: _selectedAttachmentName,
                    chooseLabel: l10n.chooseAttachment,
                    takePhotoLabel: l10n.takePhoto,
                    removeLabel: l10n.remove,
                    noneSelectedLabel: l10n.noAttachmentChosen,
                    onChoosePressed: () => _pickFile(isImage: false),
                    onRemovePressed: () => setState(() {
                      _selectedAttachmentPath = null;
                      _selectedAttachmentName = null;
                    }),
                  ),
                ),
                Gap.y4,
                AssetCreateFieldSection(
                  label: l10n.assetDetailsLabel,
                  child: AssetCreateInputField(controller: _assetDetailsController, hintText: l10n.assetDetailsHint, maxLines: 3),
                ),
                Gap.y8,
                AssetCreateActionButtons(
                  isSubmitting: _isSubmitting,
                  createLabel: l10n.createAsset,
                  savingLabel: l10n.saving,
                  goBackLabel: l10n.goBack,
                  onCreatePressed: _submitForm,
                  onGoBackPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _formatDateForApi(DateTime? value) {
    if (value == null) return null;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'ACTIVE' => l10n.statusActive,
      'UNDER MAINTENANCE' => l10n.statusUnderMaintenance,
      'APPROVAL PENDING' => l10n.statusApprovalPending,
      'INACTIVE' => l10n.statusInactive,
      _ => status,
    };
  }

  Future<String?> _resolveCachedUploadPath(PlatformFile picked, {required String prefix}) async {
    final originalPath = picked.path;
    final originalName = picked.name;

    if (originalPath != null && originalPath.trim().isNotEmpty) {
      try {
        final f = File(originalPath);
        if (await f.exists()) {
          return originalPath;
        }
      } catch (_) {
        // Fall through to bytes caching.
      }
    }

    final bytes = picked.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      final safeName = (originalName.isNotEmpty ? originalName : 'upload.bin').replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final tempDir = await Directory.systemTemp.createTemp('asset_upload_cache_$prefix');
      final outPath = '${tempDir.path}/$prefix-$safeName';
      final outFile = File(outPath);
      await outFile.writeAsBytes(bytes, flush: true);
      return outPath;
    }

    return originalPath;
  }
}
