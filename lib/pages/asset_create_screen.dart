import 'dart:convert';
import 'dart:io';

import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/theme/colors.dart';
import 'package:asset_management_system/theme/gap.dart';
import 'package:asset_management_system/theme/padding.dart';
import 'package:asset_management_system/theme/text_styles.dart';
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
        return Theme(
          data: Theme.of(context).copyWith(),
          child: Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 600), child: child),
          ),
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

    if ((_selectedType ?? '').trim().isEmpty || (_selectedCamp ?? '').trim().isEmpty || (_selectedBlock ?? '').trim().isEmpty) {
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
    // file_picker API changed in recent versions; use static pickFiles which is available
    final result = await FilePicker.pickFiles(
      type: isImage ? FileType.image : FileType.any,
      // Cache bytes immediately so Sync can upload later even if the original path becomes inaccessible.
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final picked = result.files.first;
      setState(() {
        if (isImage) {
          _selectedImagePath = picked.path;
          _selectedImageName = picked.name;
        } else {
          _selectedAttachmentPath = picked.path;
          _selectedAttachmentName = picked.name;
        }
      });

      // If we needed to cache bytes, update the stored path after writing temp file.
      // This runs after the UI state update so the user immediately sees the picked filename.
      final cachedPath = await _resolveCachedUploadPath(picked, prefix: isImage ? 'image' : 'asset_attachment');
      if (!mounted) return;
      setState(() {
        if (isImage) {
          _selectedImagePath = cachedPath;
        } else {
          _selectedAttachmentPath = cachedPath;
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

    // Only fetch blocks if a camp is selected
    final blocksAsync = _selectedCamp != null && _selectedCamp!.isNotEmpty
        ? ref.watch(blocksProvider(int.parse(_selectedCamp!)))
        : const AsyncValue<List<IdNamePair>>.data(<IdNamePair>[]);

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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue, width: 0.5),
                  ),
                  child: Text('${l10n.assetCreateNotice}\n${l10n.assetCreateImportantNotice}', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                ),
                Gap.y4,
                _buildResponsiveRow([
                  _buildFieldContainer(l10n.assetIdLabel, _buildTextField(controller: _astIdController, hint: l10n.assetIdHint, readOnly: true)),
                  _buildFieldContainer(l10n.nameLabel, _buildTextField(controller: _nameController, hint: l10n.nameHint)),
                ]),
                Gap.y4,
                _buildResponsiveRow([
                  _buildFieldContainer(
                    l10n.typeLabel,
                    assetTypesAsync.when(
                      data: (items) => _buildDropdown(
                        value: items.any((i) => i.id.toString() == _selectedType) ? _selectedType : null,
                        items: items
                            .map(
                              (i) => DropdownMenuItem(
                                value: i.id.toString(),
                                child: Text(i.name, style: ThemeTextStyles.values),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedType = v),
                      ),
                      loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                      error: (err, stack) => Text(l10n.errorLoadingTypes(err.toString()), style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ),
                  _buildFieldContainer(
                    l10n.amountLabel,
                    _buildTextField(
                      controller: _amountController,
                      hint: l10n.amountHint,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ]),
                Gap.y4,
                _buildResponsiveRow([
                  _buildFieldContainer(
                    l10n.statusLabel,
                    _buildDropdown(
                      value: _selectedStatus,
                      items: _statusOptions
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(_statusLabel(l10n, e), style: ThemeTextStyles.values),
                            ),
                          )
                          .toList(),
                      onChanged: _isSubmitting ? null : (v) => setState(() => _selectedStatus = v ?? 'ACTIVE'),
                    ),
                  ),
                  _buildFieldContainer(
                    l10n.campLabel,
                    campLocationsAsync.when(
                      data: (items) => _buildDropdown(
                        value: items.any((i) => i.id.toString() == _selectedCamp) ? _selectedCamp : null,
                        items: items
                            .map(
                              (i) => DropdownMenuItem(
                                value: i.id.toString(),
                                child: Text(i.name, style: ThemeTextStyles.values),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedCamp = v;
                          // Prevent stale block id from a previous camp selection.
                          _selectedBlock = null;
                        }),
                      ),
                      loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                      error: (err, stack) => Text(l10n.errorLoadingCamps),
                    ),
                  ),
                ]),
                Gap.y4,
                _buildResponsiveRow([
                  _buildFieldContainer(
                    l10n.blockLabel,
                    blocksAsync.when(
                      data: (List<IdNamePair> items) {
                        if (items.isEmpty) {
                          return Text(l10n.noBlocksAvailableForCamp, style: const TextStyle(color: Colors.orange));
                        }
                        return _buildDropdown(
                          value: items.any((i) => i.id.toString() == _selectedBlock) ? _selectedBlock : null,
                          items: items
                              .map(
                                (i) => DropdownMenuItem(
                                  value: i.id.toString(),
                                  child: Text(i.name, style: ThemeTextStyles.values),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedBlock = v),
                        );
                      },
                      loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                      error: (err, stack) => Text(l10n.errorLoadingBlocks(err.toString()), style: const TextStyle(color: Colors.red, fontSize: 11)),
                    ),
                  ),
                  _buildFieldContainer(l10n.addressLineLabel, _buildTextField(controller: _addressLineController, hint: l10n.addressLineHint)),
                ]),
                Gap.y4,
                _buildResponsiveRow([
                  _buildFieldContainer(
                    l10n.purchaseDateLabel,
                    _buildDatePicker(
                      date: _purchaseDate,
                      onTap: () => _selectDate(context, onDateSelected: (d) => setState(() => _purchaseDate = d)),
                    ),
                  ),
                  _buildFieldContainer(
                    l10n.manufactureDateLabel,
                    _buildDatePicker(
                      date: _manufactureDate,
                      onTap: () => _selectDate(context, onDateSelected: (d) => setState(() => _manufactureDate = d)),
                    ),
                  ),
                ]),
                Gap.y4,
                _buildResponsiveRow([
                  _buildFieldContainer(
                    l10n.warrantyEndLabel,
                    _buildDatePicker(
                      date: _warrantyEndDate,
                      onTap: () => _selectDate(context, onDateSelected: (d) => setState(() => _warrantyEndDate = d)),
                    ),
                  ),
                  const SizedBox.shrink(),
                ]),

                Gap.y8,
                Text(l10n.itemsHeading, style: ThemeTextStyles.heading),
                Gap.y2,
                Table(
                  columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2), 2: IntrinsicColumnWidth()},
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: ThemePadding.p2,
                          child: Text(l10n.itemColumn, style: ThemeTextStyles.label),
                        ),
                        Padding(
                          padding: ThemePadding.p2,
                          child: Text(l10n.descriptionColumn, style: ThemeTextStyles.label),
                        ),
                        Padding(
                          padding: ThemePadding.p2,
                          child: Text(l10n.actionColumn, style: ThemeTextStyles.label),
                        ),
                      ],
                    ),
                    ..._items.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var controllers = entry.value;
                      return TableRow(
                        children: [
                          Padding(
                            padding: ThemePadding.p1,
                            child: _buildTextField(controller: controllers['item']!, hint: l10n.enterItemHint),
                          ),
                          Padding(
                            padding: ThemePadding.p1,
                            child: _buildTextField(controller: controllers['description']!, hint: l10n.enterDescriptionHint),
                          ),
                          Padding(
                            padding: ThemePadding.p1,
                            child: ElevatedButton(
                              onPressed: () => _removeItem(idx),
                              style: ElevatedButton.styleFrom(backgroundColor: ThemeColor.black, padding: EdgeInsets.zero),
                              child: Text(l10n.deleteItem, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                Gap.y4,
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: _addItem,
                    style: ElevatedButton.styleFrom(backgroundColor: ThemeColor.black),
                    child: Text(l10n.addItem, style: const TextStyle(color: Colors.white)),
                  ),
                ),

                Gap.y8,
                _buildFieldContainer(l10n.assetPhotoLabel, _buildFilePicker(isImage: true)),
                Gap.y4,
                _buildFieldContainer(l10n.assetAttachmentLabel, _buildFilePicker(isImage: false)),
                Gap.y4,
                _buildFieldContainer(l10n.assetDetailsLabel, _buildTextField(controller: _assetDetailsController, hint: l10n.assetDetailsHint, maxLines: 3)),

                Gap.y8,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: ThemePadding.px6),
                      child: Text(_isSubmitting ? l10n.saving : l10n.createAsset, style: const TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: ThemePadding.px6),
                      child: Text(l10n.goBack, style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .map(
                  (c) => Expanded(
                    child: Padding(padding: ThemePadding.px2, child: c),
                  ),
                )
                .toList(),
          );
        } else {
          return Column(
            children: children.map((c) => Padding(padding: ThemePadding.py1, child: c)).toList(),
          );
        }
      },
    );
  }

  Widget _buildFieldContainer(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ThemeTextStyles.label),
        Gap.y2,
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: ThemeTextStyles.hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDropdown({required String? value, required List<DropdownMenuItem<String>> items, required Function(String?)? onChanged}) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
    );
  }

  Widget _buildDatePicker({required DateTime? date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date == null ? 'Select a date' : '${date.day}/${date.month}/${date.year}', style: ThemeTextStyles.values),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker({required bool isImage}) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = isImage ? _selectedImageName != null : _selectedAttachmentName != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;

        final chooseButton = ElevatedButton(
          onPressed: _isSubmitting ? null : () => _pickFile(isImage: isImage),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
            elevation: 0,
            side: const BorderSide(color: Colors.grey),
          ),
          child: Text(isImage ? l10n.chooseImage : l10n.chooseAttachment, style: const TextStyle(fontSize: 12)),
        );

        final cameraButton = Padding(
          padding: const EdgeInsets.only(left: 8),
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _captureImageFromCamera,
            icon: const Icon(Icons.camera_alt, size: 16),
            label: Text(l10n.takePhoto, style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[200],
              foregroundColor: Colors.black,
              elevation: 0,
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        );

        final removeButton = ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () => setState(() {
                  if (isImage) {
                    _selectedImagePath = null;
                    _selectedImageName = null;
                  } else {
                    _selectedAttachmentPath = null;
                    _selectedAttachmentName = null;
                  }
                }),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[300],
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(l10n.remove, style: const TextStyle(fontSize: 11)),
        );

        final fileName = Text(
          (isImage ? _selectedImageName : _selectedAttachmentName) ?? (isImage ? l10n.noImageChosen : l10n.noAttachmentChosen),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
        );

        if (!isNarrow) {
          return Row(
            children: [
              chooseButton,
              if (isImage) cameraButton,
              Gap.x2,
              Expanded(child: fileName),
              if (isSelected) removeButton,
            ],
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            chooseButton,
            if (isImage) cameraButton,
            SizedBox(width: constraints.maxWidth, child: fileName),
            if (isSelected) removeButton,
          ],
        );
      },
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
