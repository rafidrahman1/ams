import 'package:flutter/material.dart';

import '../../../../theme/colors.dart';
import '../widgets/asset_card_builder.dart';

class AssetChecklistScreen extends StatefulWidget {
  const AssetChecklistScreen({super.key, required this.asset});

  final AssetCardData asset;

  @override
  State<AssetChecklistScreen> createState() => _AssetChecklistScreenState();
}

class _AssetChecklistScreenState extends State<AssetChecklistScreen> {
  late final List<bool> _completed;

  final List<String> _checkItems = const ['Verify asset label', 'Inspect physical condition', 'Confirm asset location', 'Mark checklist complete'];

  @override
  void initState() {
    super.initState();
    _completed = List<bool>.filled(_checkItems.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checklist for ${widget.asset.title}')),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(widget.asset.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(widget.asset.description),
          const SizedBox(height: 24),
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
        ],
      ),
    );
  }
}
