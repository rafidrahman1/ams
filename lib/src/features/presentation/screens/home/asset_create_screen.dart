import 'dart:convert';

import 'package:asset_management_system/src/theme/colors.dart';
import 'package:asset_management_system/src/theme/gap.dart';
import 'package:asset_management_system/src/theme/padding.dart';
import 'package:asset_management_system/src/theme/text_styles.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/asset_provider.dart';
import '../../utils/ast_id_parser.dart';

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
  bool _isSyncing = false;
  int? _savedDeviceId;
  String? _selectedImagePath;
  String? _selectedImageName;
  String? _selectedAttachmentPath;
  String? _selectedAttachmentName;
  static const List<String> _statusOptions = ['ACTIVE', 'UNDER MAINTENANCE', 'APPROVAL PENDING', 'INACTIVE'];

  DateTime? _purchaseDate;
  DateTime? _manufactureDate;
  DateTime? _warrantyEndDate;

  final List<Map<String, TextEditingController>> _items = [];

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
        _items.removeAt(index);
      }
    });
  }

  Future<void> _selectDate(BuildContext context, {required Function(DateTime) onDateSelected}) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _submitForm() async {
    final messenger = ScaffoldMessenger.of(context);

    final name = _nameController.text.trim();
    final astId = normalizeAstId(_astIdController.text);
    final address = _addressLineController.text.trim();
    final details = _assetDetailsController.text.trim();

    if (astId == null || astId.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Asset ID is required (Scan QR/NFC)')));
      return;
    }

    _astIdController.text = astId;

    if (name.isEmpty || address.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Name and address are required')));
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

      final deviceId = await ref
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

      setState(() {
        _savedDeviceId = deviceId;
      });

      messenger.showSnackBar(const SnackBar(content: Text('Asset saved locally. Click Sync to upload.')));
    } catch (error) {
      if (!mounted) return;

      messenger.showSnackBar(SnackBar(content: Text('Error: ${error.toString()}')));
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
    final result = await FilePicker.pickFiles(type: isImage ? FileType.image : FileType.any);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        if (isImage) {
          _selectedImagePath = result.files.first.path;
          _selectedImageName = result.files.first.name;
        } else {
          _selectedAttachmentPath = result.files.first.path;
          _selectedAttachmentName = result.files.first.name;
        }
      });
    }
  }

  Future<void> _syncDevice() async {
    if (_savedDeviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No device to sync')));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isSyncing = true;
    });

    try {
      await ref.read(assetRepositoryProvider).syncRegisteredDevice(_savedDeviceId!);

      if (!mounted) return;

      messenger.showSnackBar(const SnackBar(content: Text('Asset uploaded successfully')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      messenger.showSnackBar(SnackBar(content: Text('Sync Error: ${error.toString()}')));
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
    final campLocationsAsync = ref.watch(campLocationsProvider);
    final blocksAsync = ref.watch(blocksProvider);
    final assetTypesAsync = ref.watch(assetTypesProvider);

    return Scaffold(
      backgroundColor: ThemeColor.backGroundColor,
      appBar: AppBar(title: const Text('Asset Create'), backgroundColor: ThemeColor.white, foregroundColor: ThemeColor.black, elevation: 0),
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
                _buildResponsiveRow([
                  _buildFieldContainer('Asset ID *', _buildTextField(controller: _astIdController, hint: 'Scan QR/NFC or enter ID', readOnly: true)),
                  _buildFieldContainer('Name *', _buildTextField(controller: _nameController, hint: 'Enter asset name')),
                ]),
                Gap.y4,
                _buildResponsiveRow([
                  _buildFieldContainer(
                    'Type',
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
                      error: (err, stack) => const Text('Error loading types'),
                    ),
                  ),
                  _buildFieldContainer('Amount', _buildTextField(controller: _amountController, hint: 'Enter asset amount', keyboardType: TextInputType.number)),
                ]),
                Gap.y4,
                _buildResponsiveRow([
                  _buildFieldContainer(
                    'Status',
                    _buildDropdown(
                      value: _selectedStatus,
                      items: _statusOptions
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, style: ThemeTextStyles.values),
                            ),
                          )
                          .toList(),
                      onChanged: _isSubmitting ? null : (v) => setState(() => _selectedStatus = v ?? 'ACTIVE'),
                    ),
                  ),
                  _buildFieldContainer(
                    'Camp',
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
                        onChanged: (v) => setState(() => _selectedCamp = v),
                      ),
                      loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                      error: (err, stack) => const Text('Error loading camps'),
                    ),
                  ),
                ]),
                Gap.y4,
                _buildResponsiveRow([
                  _buildFieldContainer(
                    'Block',
                    blocksAsync.when(
                      data: (items) => _buildDropdown(
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
                      ),
                      loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                      error: (err, stack) => const Text('Error loading blocks'),
                    ),
                  ),
                  _buildFieldContainer('Address Line', _buildTextField(controller: _addressLineController, hint: 'Enter address line')),
                ]),
                Gap.y4,
                _buildResponsiveRow([
                  _buildFieldContainer(
                    'Purchase Date',
                    _buildDatePicker(
                      date: _purchaseDate,
                      onTap: () => _selectDate(context, onDateSelected: (d) => setState(() => _purchaseDate = d)),
                    ),
                  ),
                  _buildFieldContainer(
                    'Manufacture Date',
                    _buildDatePicker(
                      date: _manufactureDate,
                      onTap: () => _selectDate(context, onDateSelected: (d) => setState(() => _manufactureDate = d)),
                    ),
                  ),
                ]),
                Gap.y4,
                _buildResponsiveRow([
                  _buildFieldContainer(
                    'Warranty End',
                    _buildDatePicker(
                      date: _warrantyEndDate,
                      onTap: () => _selectDate(context, onDateSelected: (d) => setState(() => _warrantyEndDate = d)),
                    ),
                  ),
                  const SizedBox.shrink(),
                ]),

                Gap.y8,
                Text('Items', style: ThemeTextStyles.heading),
                Gap.y2,
                Table(
                  columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2), 2: IntrinsicColumnWidth()},
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: ThemePadding.p2,
                          child: Text('Item', style: ThemeTextStyles.label),
                        ),
                        Padding(
                          padding: ThemePadding.p2,
                          child: Text('Description', style: ThemeTextStyles.label),
                        ),
                        Padding(
                          padding: ThemePadding.p2,
                          child: Text('Action', style: ThemeTextStyles.label),
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
                            child: _buildTextField(controller: controllers['item']!, hint: 'Enter item'),
                          ),
                          Padding(
                            padding: ThemePadding.p1,
                            child: _buildTextField(controller: controllers['description']!, hint: 'Enter description'),
                          ),
                          Padding(
                            padding: ThemePadding.p1,
                            child: ElevatedButton(
                              onPressed: () => _removeItem(idx),
                              style: ElevatedButton.styleFrom(backgroundColor: ThemeColor.black, padding: EdgeInsets.zero),
                              child: const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
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
                    child: const Text('Add Item', style: TextStyle(color: Colors.white)),
                  ),
                ),

                Gap.y8,
                _buildFieldContainer('Asset Photo', _buildFilePicker(isImage: true)),
                Gap.y4,
                _buildFieldContainer('Upload Attachment', _buildFilePicker(isImage: false)),
                Gap.y4,
                _buildFieldContainer('Asset Details', _buildTextField(controller: _assetDetailsController, hint: 'Enter asset details', maxLines: 3)),

                Gap.y8,
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _isSubmitting || _isSyncing ? null : _submitForm,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: ThemePadding.px6),
                      child: Text(_isSubmitting ? 'Saving...' : 'Create', style: const TextStyle(color: Colors.white)),
                    ),
                    if (_savedDeviceId != null) ...[
                      Gap.x2,
                      ElevatedButton(
                        onPressed: _isSubmitting || _isSyncing ? null : _syncDevice,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: ThemePadding.px6),
                        child: Text(_isSyncing ? 'Syncing...' : 'Sync', style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                    Gap.x4,
                    ElevatedButton(
                      onPressed: _isSubmitting || _isSyncing ? null : () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: ThemePadding.px6),
                      child: const Text('Go Back', style: TextStyle(color: Colors.white)),
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

  Widget _buildTextField({required TextEditingController controller, required String hint, TextInputType? keyboardType, int maxLines = 1, bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
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
      onChanged: onChanged as void Function(String?)?,
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
    return Row(
      children: [
        ElevatedButton(
          onPressed: _isSubmitting || _isSyncing ? null : () => _pickFile(isImage: isImage),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
            elevation: 0,
            side: const BorderSide(color: Colors.grey),
          ),
          child: Text(isImage ? 'Choose Image' : 'Choose Attachment', style: const TextStyle(fontSize: 12)),
        ),
        Gap.x2,
        Expanded(
          child: Text(
            (isImage ? _selectedImageName : _selectedAttachmentName) ?? (isImage ? 'No image chosen' : 'No attachment chosen'),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String? _formatDateForApi(DateTime? value) {
    if (value == null) return null;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
