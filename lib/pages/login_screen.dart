import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/theme/border_radius.dart';
import 'package:asset_management_system/theme/colors.dart';
import 'package:asset_management_system/theme/gap.dart';
import 'package:asset_management_system/theme/padding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/app_text_field.dart';
import '../components/square_action_button.dart';
import '../provider/auth_provider.dart';
import 'admin_screen.dart';

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
  bool _isPasswordObscured = true;

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

  Future<void> _loginWithEmailPassword(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final cleanedEmail = _emailController.text.trim();
    final cleanedPassword = _passwordController.text.trim();

    if (cleanedEmail.isEmpty || cleanedPassword.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.emailAndPasswordRequired)));
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
      messenger.showSnackBar(SnackBar(content: Text(l10n.invalidEmailOrPassword)));
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
    final isLoading = ref.watch(authProvider) == AuthStatus.loading;
    final isSubmitting = _isLoggingIn;

    return Scaffold(
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
                            decoration: BoxDecoration(color: ThemeColor.primary, borderRadius: ThemeBorderRadius.r2),
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
                    Gap.y8,
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: ThemeColor.primary.withValues(alpha: 0.35),
                        borderRadius: ThemeBorderRadius.r2,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminScreen()));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.admin_panel_settings, size: 48, color: ThemeColor.red),
                                Gap.x2,
                                Text(
                                  l10n.adminLogin,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: ThemeColor.red),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Gap.y8,
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
                      AppTextField(controller: _emailController, hintText: l10n.email),
                      Gap.y8,
                      AppTextField(
                        controller: _passwordController,
                        hintText: l10n.password,
                        obscureText: _isPasswordObscured,
                        onToggleObscureText: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ),
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
    );
  }
}
