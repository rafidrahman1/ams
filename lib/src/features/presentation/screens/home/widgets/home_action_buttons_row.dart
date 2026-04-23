import 'package:asset_management_system/src/features/presentation/widgets/square_action_button.dart';
import 'package:asset_management_system/src/theme/colors.dart';
import 'package:flutter/material.dart';

class HomeActionButtonsRow extends StatefulWidget {
  const HomeActionButtonsRow({
    super.key,
    required this.scanLabel,
    required this.assetsLabel,
    required this.isSyncing,
    required this.onScanPressed,
    required this.onSyncPressed,
  });

  final String scanLabel;
  final String assetsLabel;
  final bool isSyncing;
  final VoidCallback onScanPressed;
  final VoidCallback onSyncPressed;

  @override
  State<HomeActionButtonsRow> createState() => _HomeActionButtonsRowState();
}

class _HomeActionButtonsRowState extends State<HomeActionButtonsRow> with SingleTickerProviderStateMixin {
  late final AnimationController _syncRotationController;

  @override
  void initState() {
    super.initState();
    _syncRotationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.isSyncing) {
      _syncRotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant HomeActionButtonsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing && !_syncRotationController.isAnimating) {
      _syncRotationController.repeat();
    } else if (!widget.isSyncing && _syncRotationController.isAnimating) {
      _syncRotationController.stop();
      _syncRotationController.value = 0;
    }
  }

  @override
  void dispose() {
    _syncRotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SquareActionButton(
          size: 180,
          label: widget.scanLabel,
          icon: Icons.document_scanner,
          onPressed: widget.isSyncing ? null : widget.onScanPressed,
          backgroundColor: ThemeColor.primary,
          foregroundColor: ThemeColor.backGroundColor,
        ),
        SquareActionButton(
          size: 180,
          label: widget.assetsLabel,
          iconWidget: RotationTransition(turns: _syncRotationController, child: const Icon(Icons.sync, size: 36)),
          onPressed: widget.isSyncing ? null : widget.onSyncPressed,
          backgroundColor: ThemeColor.primary,
          foregroundColor: ThemeColor.backGroundColor,
        ),
      ],
    );
  }
}
