/// Lets users request a reset code and set a new password.
library;

import 'package:flutter/material.dart';

/// Screen for Forgot Password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.onRequestReset,
    required this.onConfirmReset,
  });

  final Future<String> Function({required String email}) onRequestReset;
  final Future<void> Function({required String email, required String token, required String newPassword})
  onConfirmReset;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRequesting = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestResetCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = 'Enter your email address first.';
        _message = null;
      });
      return;
    }

    setState(() {
      _isRequesting = true;
      _error = null;
      _message = null;
    });

    try {
      final message = await widget.onRequestReset(email: email);
      setState(() {
        _message = message;
      });
    } catch (error) {
      setState(() {
        _error = error.toString().replaceFirst('StateError: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  Future<void> _submitNewPassword() async {
    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || token.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _error = 'Fill in email, reset code, and both password fields.';
        _message = null;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _error = 'Passwords do not match.';
        _message = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _message = null;
    });

    try {
      await widget.onConfirmReset(email: email, token: token, newPassword: newPassword);
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Password updated'),
          content: const Text('Your password has been changed. You can now sign in with the new password.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() {
        _error = error.toString().replaceFirst('StateError: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'We will send a reset code to your email address. Use the code here to set a new password.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              hintText: 'name@example.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isRequesting ? null : _requestResetCode,
            child: Text(_isRequesting ? 'Creating code...' : 'Send reset code'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 14),
            Text(_message!, style: const TextStyle(color: Colors.green)),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Reset code',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscurePassword,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: Icon(Icons.lock_reset_outlined),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitNewPassword,
            child: Text(_isSubmitting ? 'Updating...' : 'Update password'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to login'),
          ),
        ],
      ),
    );
  }
}