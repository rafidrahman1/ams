import 'package:asset_management_system/src/theme/colors.dart';
import 'package:asset_management_system/l10n/app_localizations.dart';
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
  static const int _checkItemCount = 12;

  @override
  void initState() {
    super.initState();
    _completed = List<bool>.filled(_checkItemCount, false);
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final baseItems = [l10n.verifyAssetLabel, l10n.inspectPhysicalCondition, l10n.confirmAssetLocation, l10n.markChecklistComplete];
    final checkItems = List<String>.generate(_checkItemCount, (index) => baseItems[index % baseItems.length]);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checklistForAsset(widget.asset.title), style: const TextStyle(color: Colors.white)),
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
        label: Text(l10n.save),
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
                  ...List.generate(checkItems.length, (index) {
                    return CheckboxListTile(
                      value: _completed[index],
                      onChanged: (value) {
                        setState(() {
                          _completed[index] = value ?? false;
                        });
                      },
                      title: Text(checkItems[index]),
                    );
                  }),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _remarksController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(labelText: l10n.remarks, hintText: l10n.remarksHint, border: const OutlineInputBorder()),
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
