/// Lets existing users sign in to the app.
library;

import 'package:flutter/material.dart';

/// Screen for Login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    this.onCreateAccount,
    this.onForgotPassword,
    this.error,
  });

  final Future<void> Function({
    required String identifier,
    required String password,
  })
  onLogin;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onForgotPassword;
  final String? error;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers hold user input for email/phone and password fields.
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  // Prevents duplicate taps while login request is running.
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Purple hero background for the top area.
            Container(
              height: 260,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF5E56E7), Color(0xFF6C63F0)],
                ),
              ),
            ),
            // Decorative circles to give the header a soft look.
            Positioned(
              top: 60,
              right: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: -26,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Scrollable login card so layout works on small screens.
            ListView(
              padding: const EdgeInsets.fromLTRB(22, 34, 22, 24),
              children: [
                const Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white24,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: Color(0xFF5E56E7),
                            size: 26,
                          ),
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Gulit Gebeya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'An easy shopping for home',
                        style: TextStyle(color: Color(0xFFE5E7FF)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 42),
                // Main login form.
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140F172A),
                        blurRadius: 30,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login Account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text('Email or phone number'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _identifierController,
                        decoration: const InputDecoration(
                          hintText: 'Email or phone',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.onForgotPassword,
                          child: const Text('Forgot password'),
                        ),
                      ),
                      if (widget.error != null)
                        // Shows friendly error text received from auth provider.
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            widget.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                // Lock button while request is in progress.
                                setState(() => _isSubmitting = true);
                                // Delegates credential check to auth provider callback.
                                await widget.onLogin(
                                  identifier: _identifierController.text,
                                  password: _passwordController.text,
                                );
                                if (mounted) {
                                  // Unlock button only if the widget is still visible.
                                  setState(() => _isSubmitting = false);
                                }
                              },
                        child: Text(
                          _isSubmitting ? 'Signing in...' : 'Sign in',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Or sign in with'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _SocialButton(
                              icon: Icons.g_mobiledata_rounded,
                              label: 'Google',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SocialButton(
                              icon: Icons.facebook_rounded,
                              label: 'Facebook',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Don\'t have an account?'),
                          TextButton(
                            onPressed: widget.onCreateAccount,
                            child: const Text('Create account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Placeholder action for future OAuth integration.
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
