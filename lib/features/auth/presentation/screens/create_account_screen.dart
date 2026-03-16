/// Collects new user details and starts account creation.
library;
import 'package:flutter/material.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({
    super.key,
    required this.onCreateAccount,
    required this.onBackToLogin,
    this.error,
  });

  final Future<void> Function({
    required String fullName,
    required String identifier,
    required String password,
  }) onCreateAccount;
  final VoidCallback onBackToLogin;
  final String? error;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // Controllers keep the form values while user types.
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  // Disables submit button while account creation is running.
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
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
            // Top gradient area for page identity.
            Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF5E56E7), Color(0xFF756DF2)]),
              ),
            ),
            // Main form in a scroll view for better small-screen behavior.
            ListView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBackToLogin,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create Account',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a new account to start shopping.',
                  style: TextStyle(color: Color(0xFFDCDDFF)),
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Username',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _identifierController,
                        decoration: const InputDecoration(
                          hintText: 'Email address',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
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
                            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                      if (widget.error != null)
                        // Friendly error message from auth provider.
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(widget.error!, style: const TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                // Prevent duplicate account creation requests.
                                setState(() => _isSubmitting = true);
                                await widget.onCreateAccount(
                                  fullName: _nameController.text,
                                  identifier: _identifierController.text,
                                  password: _passwordController.text,
                                );
                                if (mounted) {
                                  // Re-enable button after response returns.
                                  setState(() => _isSubmitting = false);
                                }
                              },
                        child: Text(_isSubmitting ? 'Creating...' : 'Create Account'),
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