import 'package:asset_management_system/l10n/app_localizations.dart';
import 'package:asset_management_system/src/theme/border_radius.dart';
import 'package:asset_management_system/src/theme/colors.dart';
import 'package:asset_management_system/src/theme/gap.dart';
import 'package:asset_management_system/src/theme/padding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../widgets/app_text_field.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSubmitting = _isLoggingIn;

    return Scaffold(
      backgroundColor: ThemeColor.backGroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ThemeColor.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: ThemePadding.p4,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    Gap.y8,
                    Row(
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
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final cleanedEmail = _emailController.text.trim();
                                final cleanedPassword = _passwordController.text.trim();

                                if (cleanedEmail.isEmpty || cleanedPassword.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.emailAndPasswordRequired)));
                                  return;
                                }

                                setState(() {
                                  _isLoggingIn = true;
                                });

                                await ref.read(authProvider.notifier).adminLogin(cleanedEmail, cleanedPassword);

                                if (!context.mounted) {
                                  return;
                                }

                                final authState = ref.read(authProvider);

                                setState(() {
                                  _isLoggingIn = false;
                                });

                                if (authState == AuthStatus.unauthenticated) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidEmailOrPassword)));
                                } else if (authState == AuthStatus.authenticatedAdmin || authState == AuthStatus.authenticatedVolunteer) {
                                  Navigator.of(context).pop();
                                }
                              },
                        child: Text(isSubmitting ? l10n.loggingIn : l10n.login),
                      ),
                    ),
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
