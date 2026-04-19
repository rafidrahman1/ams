import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.orange.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = TextEditingController();
    final password = TextEditingController();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.orange.shade50,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildField(
                controller: email,
                hintText: 'Email',
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: password,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final cleanedEmail = email.text.trim();
                  final cleanedPassword = password.text.trim();

                  if (cleanedEmail.isEmpty || cleanedPassword.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email and password are required'),
                      ),
                    );
                    return;
                  }

                  await ref.read(authProvider.notifier).login(
                    cleanedEmail,
                    cleanedPassword,
                  );
                },
                child: const Text("Login"),
              )
            ],
          ),
        ),
      ),
    );
  }
}