import 'package:flutter/material.dart';

import '../theme/border_radius.dart';
import '../theme/colors.dart';
import '../theme/padding.dart';
import '../theme/text_styles.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final VoidCallback? onToggleObscureText;

  const AppTextField({super.key, required this.controller, required this.hintText, this.obscureText = false, this.onToggleObscureText});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: ThemeColor.primary.withValues(alpha: 0.35), borderRadius: ThemeBorderRadius.r3),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: ThemeTextStyles.hint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: ThemePadding.p3,
          suffixIcon: onToggleObscureText == null ? null : IconButton(onPressed: onToggleObscureText, icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility)),
        ),
      ),
    );
  }
}
