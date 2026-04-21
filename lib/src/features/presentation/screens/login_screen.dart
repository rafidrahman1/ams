import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/src/theme/border_radius.dart';
import 'package:asset_management_system/src/theme/colors.dart';
import 'package:asset_management_system/src/theme/gap.dart';
import 'package:asset_management_system/src/theme/padding.dart';
import 'package:asset_management_system/src/theme/textStyles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/square_action_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _showEmailForm = false;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildField({required TextEditingController controller, required String hintText, bool obscureText = false}) {
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
        ),
      ),
    );
  }

  Future<void> _loginWithEmailPassword(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cleanedEmail = _emailController.text.trim();
    final cleanedPassword = _passwordController.text.trim();

    if (cleanedEmail.isEmpty || cleanedPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.emailAndPasswordRequired)));
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    await ref.read(authProvider.notifier).login(cleanedEmail, cleanedPassword);

    if (!mounted) {
      return;
    }

    final authState = ref.read(authProvider);

    setState(() {
      _isLoggingIn = false;
    });

    if (authState == AuthStatus.unauthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidEmailOrPassword)));
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final locale = ref.watch(localeProvider);
    final isLoading = authState == AuthStatus.loading;
    final isSubmitting = _isLoggingIn;

    return SafeArea(
      child: Scaffold(
        backgroundColor: ThemeColor.backGroundColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: ThemePadding.p4,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(color: ThemeColor.primary),
                              child: Center(
                                child: Text(
                                  l10n.appTitle,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: ThemeColor.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: constraints.maxHeight * 0.1),
                      Row(
                        children: [
                          Expanded(
                            child: SquareActionButton(
                              label: isLoading || isSubmitting ? l10n.loading : l10n.loginWithEmail,
                              icon: Icons.mail_outline,
                              onPressed: isLoading || isSubmitting ? null : _showEmailLoginForm,
                              backgroundColor: ThemeColor.primary,
                              foregroundColor: ThemeColor.white,
                            ),
                          ),
                          Gap.x4,
                          Expanded(
                            child: SquareActionButton(
                              label: l10n.loginWithNfc,
                              icon: Icons.contactless,
                              onPressed: isLoading || isSubmitting ? null : () => _loginWithNfc(context),
                              backgroundColor: ThemeColor.primary.withValues(alpha: 0.35),
                              foregroundColor: ThemeColor.black,
                            ),
                          ),
                        ],
                      ),
                      if (_showEmailForm) ...[
                        Gap.y8,
                        _buildField(controller: _emailController, hintText: l10n.email),
                        Gap.y8,
                        _buildField(controller: _passwordController, hintText: l10n.password, obscureText: true),
                        Gap.y8,
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading || isSubmitting ? null : () => _loginWithEmailPassword(context),
                            child: Text(isSubmitting ? l10n.loggingIn : l10n.login),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
