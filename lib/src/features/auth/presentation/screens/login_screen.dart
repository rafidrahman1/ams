import 'package:asset_management_system/src/theme/border_radius.dart';
import 'package:asset_management_system/src/theme/colors.dart';
import 'package:asset_management_system/src/theme/gap.dart';
import 'package:asset_management_system/src/theme/padding.dart';
import 'package:asset_management_system/src/theme/textStyles.dart';
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
    final cleanedEmail = _emailController.text.trim();
    final cleanedPassword = _passwordController.text.trim();

    if (cleanedEmail.isEmpty || cleanedPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email and password are required')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email or password')));
    }
  }

  void _loginWithNfc(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NFC login is not connected yet')));
  }

  void _showEmailLoginForm() {
    setState(() {
      _showEmailForm = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
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
                                  "Asset Management System",
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
                              label: isLoading || isSubmitting ? 'Loading...' : 'Login with\nEmail',
                              icon: Icons.mail_outline,
                              onPressed: isLoading || isSubmitting ? null : _showEmailLoginForm,
                              backgroundColor: ThemeColor.primary,
                              foregroundColor: ThemeColor.white,
                            ),
                          ),
                          Gap.x4,
                          Expanded(
                            child: SquareActionButton(
                              label: 'Login with\nNFC',
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
                        _buildField(controller: _emailController, hintText: 'Email'),
                        Gap.y8,
                        _buildField(controller: _passwordController, hintText: 'Password', obscureText: true),
                        Gap.y8,
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading || isSubmitting ? null : () => _loginWithEmailPassword(context),
                            child: Text(isSubmitting ? 'Logging in...' : 'Login'),
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

