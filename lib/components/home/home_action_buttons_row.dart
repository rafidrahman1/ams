import 'package:asset_management_system/components/square_action_button.dart';
import 'package:asset_management_system/theme/colors.dart';
import 'package:flutter/material.dart';

class HomeActionButtonsRow extends StatefulWidget {
  const HomeActionButtonsRow({
    super.key,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.secondaryLabel,
    required this.isSyncing,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
  });

  final String primaryLabel;
  final IconData primaryIcon;
  final String secondaryLabel;
  final bool isSyncing;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;

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
          size: 150,
          label: widget.primaryLabel,
          icon: widget.primaryIcon,
          onPressed: widget.isSyncing ? null : widget.onPrimaryPressed,
          backgroundColor: ThemeColor.primary,
          foregroundColor: ThemeColor.backGroundColor,
        ),
        SquareActionButton(
          size: 150,
          label: widget.secondaryLabel,
          iconWidget: RotationTransition(turns: _syncRotationController, child: const Icon(Icons.sync, size: 36)),
          onPressed: widget.isSyncing ? null : widget.onSecondaryPressed,
          backgroundColor: ThemeColor.primary,
          foregroundColor: ThemeColor.backGroundColor,
        ),
      ],
    );
  }
}
