import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/src/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/asset_provider.dart';
import '../widgets/asset_card_builder.dart';
import '../../data/models/asset_checklist_item.dart';

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
  String _status = 'ACTIVE';

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
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
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final checklistAsync = ref.watch(assetChecklistProvider(widget.asset.astId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checklistForAsset(widget.asset.title), style: const TextStyle(color: Colors.white)),
        backgroundColor: ThemeColor.primary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: checklistAsync.hasValue
            ? () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final data = await ref.read(assetChecklistProvider(widget.asset.astId).future);
                  final items = data.items;
                  final completed = _completed.length == items.length ? List<bool>.from(_completed) : items.map((item) => item.response).toList();

                  final submitItems = <({int featureId, bool response})>[];
                  for (var index = 0; index < items.length; index++) {
                    submitItems.add((featureId: items[index].featureId, response: completed[index]));
                  }

                  // Always queue the submission so Home -> Sync can submit later.
                  // This keeps behavior predictable for users who save while offline.
                  await ref
                      .read(assetRepositoryProvider)
                      .queueChecklistSubmission(astId: widget.asset.astId, status: _status, remark: _remarksController.text.trim(), items: submitItems);

                  ref.invalidate(assetChecklistProvider(widget.asset.astId));

                  if (!mounted) return;
                  navigator.pop(completed);
                } catch (error) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text(error.toString())));
                }
              }
            : null,
        backgroundColor: ThemeColor.primary,
        foregroundColor: ThemeColor.backGroundColor,
        icon: const Icon(Icons.save),
        label: Text(l10n.save),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: checklistAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (data) {
            _syncState(widget.asset.astId, data);
            final items = data.items;

            if (items.isEmpty) {
              return const Center(child: Text('No checklist items found'));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.asset.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(widget.asset.description),
                const SizedBox(height: 8),
                Text(widget.asset.astId, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: [
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'APPROVAL PENDING', child: Text('APPROVAL PENDING')),
                          DropdownMenuItem(value: 'UNDER MAINTENANCE', child: Text('UNDER MAINTENANCE')),
                          DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                          DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _status = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(items.length, (index) {
                        return CheckboxListTile(
                          value: index < _completed.length ? _completed[index] : items[index].response,
                          onChanged: (value) {
                            setState(() {
                              if (_completed.length != items.length) {
                                _completed = items.map((item) => item.response).toList();
                              }
                              _completed[index] = value ?? false;
                            });
                          },
                          title: Text(items[index].title),
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
            );
          },
        ),
      ),
    );
  }
}
