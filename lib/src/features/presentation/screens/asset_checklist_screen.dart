import 'package:asset_management_system/src/theme/colors.dart';
import 'package:flutter/material.dart';

import '../widgets/asset_card_builder.dart';

class AssetChecklistScreen extends StatefulWidget {
  const AssetChecklistScreen({super.key, required this.asset});

  final AssetCardData asset;

  @override
  State<AssetChecklistScreen> createState() => _AssetChecklistScreenState();
}

class _AssetChecklistScreenState extends State<AssetChecklistScreen> {
  late final List<bool> _completed;
  final TextEditingController _remarksController = TextEditingController();

  final List<String> _checkItems = const [
    'Verify asset label',
    'Inspect physical condition',
    'Confirm asset location',
    'Mark checklist complete',
    'Verify asset label',
    'Inspect physical condition',
    'Confirm asset location',
    'Mark checklist complete',
    'Verify asset label',
    'Inspect physical condition',
    'Confirm asset location',
    'Mark checklist complete',
  ];

  @override
  void initState() {
    super.initState();
    _completed = List<bool>.filled(_checkItems.length, false);
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checklist for ${widget.asset.title}', style: TextStyle(color: Colors.white)),
        backgroundColor: ThemeColor.primary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pop(List<bool>.from(_completed));
        },
        backgroundColor: ThemeColor.primary,
        foregroundColor: ThemeColor.backGroundColor,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.asset.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(widget.asset.description),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  ...List.generate(_checkItems.length, (index) {
                    return CheckboxListTile(
                      value: _completed[index],
                      onChanged: (value) {
                        setState(() {
                          _completed[index] = value ?? false;
                        });
                      },
                      title: Text(_checkItems[index]),
                    );
                  }),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _remarksController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(labelText: 'Remarks', hintText: 'Add any notes about this checklist...', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
