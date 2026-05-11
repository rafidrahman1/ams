import 'package:asset_management_system/data/models/asset_checklist_item.dart';
import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AssetChecklistHeader extends StatelessWidget {
  const AssetChecklistHeader({super.key, required this.title, required this.description, required this.assetId});

  final String title;
  final String description;
  final String assetId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.headlineSmall),
        const SizedBox(height: 8),
        Text(description),
        const SizedBox(height: 8),
        Text(assetId, style: theme.bodyMedium),
      ],
    );
  }
}

class AssetChecklistStatusDropdown extends StatelessWidget {
  const AssetChecklistStatusDropdown({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      decoration: InputDecoration(border: const OutlineInputBorder(), labelText: l10n.statusLabel),
      items: [
        DropdownMenuItem(value: 'APPROVAL PENDING', child: Text(l10n.statusApprovalPending)),
        DropdownMenuItem(value: 'UNDER MAINTENANCE', child: Text(l10n.statusUnderMaintenance)),
        DropdownMenuItem(value: 'ACTIVE', child: Text(l10n.statusActive)),
        DropdownMenuItem(value: 'INACTIVE', child: Text(l10n.statusInactive)),
      ],
      onChanged: onChanged,
    );
  }
}

class AssetChecklistItemsList extends StatelessWidget {
  const AssetChecklistItemsList({super.key, required this.items, required this.completed, required this.onChanged});

  final List<AssetChecklistItem> items;
  final List<bool> completed;
  final void Function(int index, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final checked = index < completed.length ? completed[index] : items[index].response;
        return CheckboxListTile(contentPadding: EdgeInsets.zero, value: checked, onChanged: (value) => onChanged(index, value ?? false), title: Text(items[index].title));
      }),
    );
  }
}

class AssetChecklistFieldGroup extends StatelessWidget {
  const AssetChecklistFieldGroup({super.key, required this.parameterController, required this.remarksController});

  final TextEditingController parameterController;
  final TextEditingController remarksController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        TextField(
          controller: parameterController,
          decoration: InputDecoration(labelText: l10n.parameterLabel, hintText: l10n.parameterHint, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: remarksController,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(labelText: l10n.remarks, hintText: l10n.remarksHint, border: const OutlineInputBorder()),
        ),
      ],
    );
  }
}

class AssetChecklistImageSection extends StatelessWidget {
  const AssetChecklistImageSection({super.key, required this.imagePath, required this.onCameraPressed, required this.onGalleryPressed, required this.onRemovePressed});

  final String imagePath;
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;
  final VoidCallback onRemovePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImage = imagePath.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(onPressed: onCameraPressed, icon: const Icon(Icons.camera_alt), label: Text(hasImage ? l10n.retakePhoto : l10n.camera)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(onPressed: onGalleryPressed, icon: const Icon(Icons.image), label: Text(hasImage ? l10n.changeImage : l10n.attachImage)),
            ),
          ],
        ),
        if (hasImage) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRemovePressed,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: Text(l10n.removeImage, style: const TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              foregroundColor: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.imageSelected, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
