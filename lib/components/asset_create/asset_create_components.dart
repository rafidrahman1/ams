import 'package:asset_management_system/theme/border_radius.dart';
import 'package:asset_management_system/theme/colors.dart';
import 'package:asset_management_system/theme/gap.dart';
import 'package:asset_management_system/theme/padding.dart';
import 'package:asset_management_system/theme/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AssetCreateNoticeBanner extends StatelessWidget {
  const AssetCreateNoticeBanner({super.key, required this.noticeText, required this.importantNoticeText});

  final String noticeText;
  final String importantNoticeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: ThemeBorderRadius.r3,
        border: Border.all(color: Colors.blue, width: 0.5),
      ),
      child: Text('$noticeText\n$importantNoticeText', style: const TextStyle(fontSize: 11, color: Colors.blue)),
    );
  }
}

class AssetCreateFieldSection extends StatelessWidget {
  const AssetCreateFieldSection({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ThemeTextStyles.label),
        Gap.y2,
        child,
      ],
    );
  }
}

class AssetCreateResponsiveRow extends StatelessWidget {
  const AssetCreateResponsiveRow({super.key, required this.children, this.breakpoint = 600});

  final List<Widget> children;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > breakpoint;
        final wrappedChildren = children.map((child) => Padding(padding: isWide ? ThemePadding.px2 : ThemePadding.py1, child: child)).toList(growable: false);

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: wrappedChildren.map((child) => Expanded(child: child)).toList(growable: false),
          );
        }

        return Column(children: wrappedChildren);
      },
    );
  }
}

class AssetCreateInputField extends StatelessWidget {
  const AssetCreateInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: ThemeTextStyles.hint,
        border: OutlineInputBorder(borderRadius: ThemeBorderRadius.r3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class AssetCreateDropdownField extends StatelessWidget {
  const AssetCreateDropdownField({super.key, required this.value, required this.items, required this.onChanged});

  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      alignment: Alignment.center,
      items: items,
      onChanged: onChanged,
      borderRadius: ThemeBorderRadius.r3,
      dropdownColor: ThemeColor.white,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: ThemeBorderRadius.r3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class AssetCreateDateField extends StatelessWidget {
  const AssetCreateDateField({super.key, required this.date, required this.onTap, required this.placeholderText});

  final DateTime? date;
  final VoidCallback onTap;
  final String placeholderText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: ThemeBorderRadius.r3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date == null ? placeholderText : '${date!.day}/${date!.month}/${date!.year}', style: ThemeTextStyles.values),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }
}

class AssetCreateFilePickerField extends StatelessWidget {
  const AssetCreateFilePickerField({
    super.key,
    required this.isImage,
    required this.isSubmitting,
    required this.selectedName,
    required this.chooseLabel,
    required this.takePhotoLabel,
    required this.removeLabel,
    required this.noneSelectedLabel,
    required this.onChoosePressed,
    this.onTakePhotoPressed,
    this.onRemovePressed,
  });

  final bool isImage;
  final bool isSubmitting;
  final String? selectedName;
  final String chooseLabel;
  final String takePhotoLabel;
  final String removeLabel;
  final String noneSelectedLabel;
  final VoidCallback onChoosePressed;
  final VoidCallback? onTakePhotoPressed;
  final VoidCallback? onRemovePressed;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedName != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;

        final chooseButton = ElevatedButton(
          onPressed: isSubmitting ? null : onChoosePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
            elevation: 0,
            side: const BorderSide(color: Colors.grey),
          ),
          child: Text(chooseLabel, style: const TextStyle(fontSize: 12)),
        );

        final cameraButton = isImage && onTakePhotoPressed != null
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onTakePhotoPressed,
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: Text(takePhotoLabel, style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[200],
                    foregroundColor: Colors.black,
                    elevation: 0,
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              )
            : const SizedBox.shrink();

        final removeButton = ElevatedButton(
          onPressed: isSubmitting ? null : onRemovePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[300],
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(removeLabel, style: const TextStyle(fontSize: 11)),
        );

        final fileName = Text(
          selectedName ?? noneSelectedLabel,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
        );

        final buttons = <Widget>[chooseButton, if (isImage) cameraButton];

        if (!isNarrow) {
          return Row(
            children: [
              ...buttons,
              Gap.x2,
              Expanded(child: fileName),
              if (hasSelection) removeButton,
            ],
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...buttons,
            SizedBox(width: constraints.maxWidth, child: fileName),
            if (hasSelection) removeButton,
          ],
        );
      },
    );
  }
}

class AssetCreateItemsSection extends StatelessWidget {
  const AssetCreateItemsSection({
    super.key,
    required this.items,
    required this.itemsHeading,
    required this.itemColumnLabel,
    required this.descriptionColumnLabel,
    required this.actionColumnLabel,
    required this.enterItemHint,
    required this.enterDescriptionHint,
    required this.deleteItemLabel,
    required this.addItemLabel,
    required this.onAddItem,
    required this.onRemoveItem,
  });

  final List<Map<String, TextEditingController>> items;
  final String itemsHeading;
  final String itemColumnLabel;
  final String descriptionColumnLabel;
  final String actionColumnLabel;
  final String enterItemHint;
  final String enterDescriptionHint;
  final String deleteItemLabel;
  final String addItemLabel;
  final VoidCallback onAddItem;
  final ValueChanged<int> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(itemsHeading, style: ThemeTextStyles.heading),
        Gap.y2,
        Table(
          columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2), 2: IntrinsicColumnWidth()},
          children: [
            TableRow(
              children: [
                Padding(
                  padding: ThemePadding.p2,
                  child: Text(itemColumnLabel, style: ThemeTextStyles.label),
                ),
                Padding(
                  padding: ThemePadding.p2,
                  child: Text(descriptionColumnLabel, style: ThemeTextStyles.label),
                ),
                Padding(
                  padding: ThemePadding.p2,
                  child: Text(actionColumnLabel, style: ThemeTextStyles.label),
                ),
              ],
            ),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final controllers = entry.value;
              return TableRow(
                children: [
                  Padding(
                    padding: ThemePadding.p1,
                    child: TextFormField(
                      controller: controllers['item'],
                      decoration: InputDecoration(
                        hintText: enterItemHint,
                        hintStyle: ThemeTextStyles.hint,
                        border: OutlineInputBorder(borderRadius: ThemeBorderRadius.r3),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  Padding(
                    padding: ThemePadding.p1,
                    child: TextFormField(
                      controller: controllers['description'],
                      decoration: InputDecoration(
                        hintText: enterDescriptionHint,
                        hintStyle: ThemeTextStyles.hint,
                        border: OutlineInputBorder(borderRadius: ThemeBorderRadius.r3),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  Padding(
                    padding: ThemePadding.p1,
                    child: ElevatedButton(
                      onPressed: () => onRemoveItem(index),
                      style: ElevatedButton.styleFrom(backgroundColor: ThemeColor.black, padding: EdgeInsets.zero),
                      child: Text(deleteItemLabel, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
            onPressed: onAddItem,
            style: ElevatedButton.styleFrom(backgroundColor: ThemeColor.black),
            child: Text(addItemLabel, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class AssetCreateActionButtons extends StatelessWidget {
  const AssetCreateActionButtons({
    super.key,
    required this.isSubmitting,
    required this.createLabel,
    required this.savingLabel,
    required this.goBackLabel,
    required this.onCreatePressed,
    required this.onGoBackPressed,
  });

  final bool isSubmitting;
  final String createLabel;
  final String savingLabel;
  final String goBackLabel;
  final VoidCallback onCreatePressed;
  final VoidCallback onGoBackPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: [
        ElevatedButton(
          onPressed: isSubmitting ? null : onCreatePressed,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: ThemePadding.px6),
          child: Text(isSubmitting ? savingLabel : createLabel, style: const TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : onGoBackPressed,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: ThemePadding.px6),
          child: Text(goBackLabel, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
