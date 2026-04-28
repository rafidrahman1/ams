import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/src/theme/border_radius.dart';
import 'package:asset_management_system/src/theme/colors.dart';
import 'package:asset_management_system/src/theme/gap.dart';
import 'package:asset_management_system/src/theme/padding.dart';
import 'package:asset_management_system/src/theme/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../widgets/square_action_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  final _formKey = GlobalKey<FormState>();

  bool _showEmailForm = false;
  bool _isPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    /// Listen to auth state changes (side-effects)
    ref.listen<AuthStatus>(authProvider, (previous, next) {
      final l10n = AppLocalizations.of(context)!;
      final messenger = ScaffoldMessenger.of(context);

      if (next == AuthStatus.unauthenticated && previous == AuthStatus.loading) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.invalidEmailOrPassword)));
      }

      if (next == AuthStatus.authenticated) {
        // TODO: Navigate to home/dashboard
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    bool obscureText = false,
    VoidCallback? onToggleObscureText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
  }) {
    return Container(
      decoration: BoxDecoration(color: ThemeColor.primary.withValues(alpha: 0.35), borderRadius: ThemeBorderRadius.r3),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: ThemeTextStyles.hint,
          border: InputBorder.none,
          contentPadding: ThemePadding.p3,
          suffixIcon: onToggleObscureText == null ? null : IconButton(onPressed: onToggleObscureText, icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility)),
        ),
      ),
    );
  }

  Future<void> _loginWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    await ref.read(authProvider.notifier).login(email, password);
  }

  void _loginWithNfc(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.nfcLoginNotConnected)));
  }

  void _showEmailLoginForm() {
    setState(() {
      _showEmailForm = true;
    });
  }

  void _onAdminLoginTap(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${l10n.adminLogin} clicked")));

    // TODO: Implement admin navigation or flow
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }

    final email = value.trim();
    final isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);

    if (!isValid) {
      return "Invalid email format";
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Password is required";
    }

    if (value.trim().length < 6) {
      return "Minimum 6 characters required";
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final isLoading = authState == AuthStatus.loading;

    return Scaffold(
      backgroundColor: ThemeColor.backGroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: ThemePadding.p4,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// Title
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: ThemeColor.primary, borderRadius: ThemeBorderRadius.r2),
                        child: Center(
                          child: Text(
                            l10n.appTitle,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: ThemeColor.white),
                          ),
                        ),
                      ),

                      Gap.y4,

                      /// Admin Button (kept)
                      Material(
                        color: ThemeColor.primary,
                        borderRadius: ThemeBorderRadius.r2,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _onAdminLoginTap(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.admin_panel_settings, size: 40, color: ThemeColor.white),
                                Gap.x2,
                                Text(
                                  l10n.adminLogin,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: ThemeColor.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Gap.y4,

                      /// Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SquareActionButton(
                              label: isLoading ? l10n.loading : l10n.loginWithEmail,
                              icon: Icons.mail_outline,
                              onPressed: isLoading ? null : _showEmailLoginForm,
                              backgroundColor: ThemeColor.primary,
                              foregroundColor: ThemeColor.white,
                            ),
                          ),
                          Gap.x4,
                          Expanded(
                            child: SquareActionButton(
                              label: l10n.loginWithNfc,
                              icon: Icons.contactless,
                              onPressed: isLoading ? null : () => _loginWithNfc(context),
                              backgroundColor: ThemeColor.primary.withValues(alpha: 0.35),
                              foregroundColor: ThemeColor.black,
                            ),
                          ),
                        ],
                      ),

                      if (_showEmailForm) ...[
                        Gap.y8,

                        _buildField(
                          controller: _emailController,
                          hintText: l10n.email,
                          validator: _emailValidator,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                        ),

                        Gap.y4,

                        _buildField(
                          controller: _passwordController,
                          hintText: l10n.password,
                          validator: _passwordValidator,
                          obscureText: _isPasswordObscured,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onToggleObscureText: () {
                            setState(() {
                              _isPasswordObscured = !_isPasswordObscured;
                            });
                          },
                        ),

                        Gap.y4,

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(onPressed: isLoading ? null : _loginWithEmailPassword, child: Text(isLoading ? l10n.loggingIn : l10n.login)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
